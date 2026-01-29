import Foundation

public final class ApiClient {
    public static let shared: ApiClient = ApiClient()
    public let basePath: String = "https://toi.kuronekoyamato.co.jp/cgi-bin"
    public let sagawaBasePath: String = "https://k2k.sagawa-exp.co.jp/p/sagawa"
    public let japanPostBasePath: String = "https://trackings.post.japanpost.jp"

    /// APIクライアント設定
    public var configuration: APIClientConfiguration

    /// キャッシュ
    public var cache: DeliveryCacheProtocol

    /// リトライポリシー
    public var retryPolicy: RetryPolicy

    /// カスタムURLSession
    private(set) var urlSession: URLSession

    public var baseURL: URL {
        return URL(string: basePath)!
    }

    public var sagawaBaseURL: URL {
        return URL(string: sagawaBasePath)!
    }

    public var japanPostBaseURL: URL {
        return URL(string: japanPostBasePath)!
    }

    public init(
        configuration: APIClientConfiguration = .default,
        cache: DeliveryCacheProtocol = DeliveryTieredCache.shared
    ) {
        self.configuration = configuration
        self.cache = cache
        self.retryPolicy = RetryPolicy(
            maxRetryCount: configuration.maxRetryCount,
            baseDelay: configuration.retryBaseDelay,
            useExponentialBackoff: configuration.useExponentialBackoff
        )

        // タイムアウト設定を含むURLSessionを作成
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
        sessionConfig.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: sessionConfig)
    }

    /// 設定を更新
    public func updateConfiguration(_ configuration: APIClientConfiguration) {
        self.configuration = configuration
        self.retryPolicy = RetryPolicy(
            maxRetryCount: configuration.maxRetryCount,
            baseDelay: configuration.retryBaseDelay,
            useExponentialBackoff: configuration.useExponentialBackoff
        )

        // URLSessionを再作成
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
        sessionConfig.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: sessionConfig)
    }

    /// キャッシュをクリア
    public func clearCache() {
        cache.removeAll()
    }

    /// 期限切れキャッシュを削除
    public func cleanExpiredCache() {
        cache.removeExpired()
    }
}

// MARK: - リトライ処理ヘルパー
extension ApiClient {
    /// リトライ付きでデータ取得を実行（async/await版）
    internal func fetchWithRetry(
        urlRequest: URLRequest,
        currentAttempt: Int = 0
    ) async -> Result<Data, APIError> {
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)

            // HTTPレスポンスのステータスコードをチェック
            if let httpResponse = response as? HTTPURLResponse {
                if let apiError = APIError.from(statusCode: httpResponse.statusCode, data: data) {
                    // リトライ可能なエラーの場合
                    if retryPolicy.shouldRetry(error: apiError, currentAttempt: currentAttempt) {
                        let delay = retryPolicy.delay(for: currentAttempt)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        return await fetchWithRetry(urlRequest: urlRequest, currentAttempt: currentAttempt + 1)
                    }
                    return .failure(apiError)
                }
            }

            return .success(data)

        } catch let urlError as URLError {
            let apiError = APIError.from(urlError)

            // リトライ可能なエラーの場合
            if retryPolicy.shouldRetry(error: apiError, currentAttempt: currentAttempt) {
                let delay = retryPolicy.delay(for: currentAttempt)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return await fetchWithRetry(urlRequest: urlRequest, currentAttempt: currentAttempt + 1)
            }

            // リトライ上限に達した場合
            if currentAttempt > 0 {
                return .failure(.retryLimitExceeded(lastError: apiError.errorDescription ?? "Unknown"))
            }

            return .failure(apiError)

        } catch {
            return .failure(.unknownError(error.localizedDescription))
        }
    }

    /// リトライ付きでデータ取得を実行（completion版）
    internal func fetchWithRetry(
        urlRequest: URLRequest,
        currentAttempt: Int = 0,
        completion: @escaping (Result<Data, APIError>) -> Void
    ) {
        let task = urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else {
                completion(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            // エラーチェック
            if let urlError = error as? URLError {
                let apiError = APIError.from(urlError)

                // リトライ可能なエラーの場合
                if self.retryPolicy.shouldRetry(error: apiError, currentAttempt: currentAttempt) {
                    let delay = self.retryPolicy.delay(for: currentAttempt)
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.fetchWithRetry(urlRequest: urlRequest, currentAttempt: currentAttempt + 1, completion: completion)
                    }
                    return
                }

                // リトライ上限に達した場合
                if currentAttempt > 0 {
                    completion(.failure(.retryLimitExceeded(lastError: apiError.errorDescription ?? "Unknown")))
                    return
                }

                completion(.failure(apiError))
                return
            }

            if let error = error {
                completion(.failure(.unknownError(error.localizedDescription)))
                return
            }

            // HTTPレスポンスのステータスコードをチェック
            if let httpResponse = response as? HTTPURLResponse,
               let apiError = APIError.from(statusCode: httpResponse.statusCode, data: data) {
                // リトライ可能なエラーの場合
                if self.retryPolicy.shouldRetry(error: apiError, currentAttempt: currentAttempt) {
                    let delay = self.retryPolicy.delay(for: currentAttempt)
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.fetchWithRetry(urlRequest: urlRequest, currentAttempt: currentAttempt + 1, completion: completion)
                    }
                    return
                }
                completion(.failure(apiError))
                return
            }

            guard let data = data else {
                completion(.failure(.emptyData))
                return
            }

            completion(.success(data))
        }
        task.resume()
    }
}

// MARK: - HTMLパース共通処理
extension ApiClient {
    /// HTMLデータをパースしてAttributedStringに変換
    internal func parseHTML(from data: Data) -> Result<String, APIError> {
        guard !data.isEmpty else {
            return .failure(.emptyData)
        }

        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) else {
            return .failure(.htmlParseError("Failed to parse HTML content"))
        }

        return .success(attributedString.string)
    }
}

extension Dictionary where Key == String, Value == Int {
    init?<Request>(_ request: Request) where Request: RequestType & URLQueryEncodable {
        guard let data = try? JSONEncoder().encode(request),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = jsonObject as? [String: Any] else {
            return nil
        }

        // 各値を個別にIntに変換（NSNumber対応で大きな整数もサポート）
        var result: [String: Int] = [:]
        for (key, value) in dict {
            if let intValue = value as? Int {
                result[key] = intValue
            } else if let nsNumber = value as? NSNumber {
                result[key] = nsNumber.intValue
            } else {
                return nil
            }
        }
        self = result
    }

    func equalEncode() -> String {
        return map { key, value in
            return key + "=" + String(value)
        }
        .joined(separator: "&")
    }
}
