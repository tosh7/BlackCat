import Foundation

/// API通信で発生するエラーを表す列挙型
public enum APIError: Error, Equatable {
    // MARK: - ネットワークエラー
    /// URLが無効
    case invalidURL
    /// 接続タイムアウト
    case timeout
    /// ネットワーク接続なし
    case noConnection
    /// SSL/TLS証明書エラー
    case sslError

    // MARK: - HTTPエラー
    /// HTTPステータスコードエラー
    case httpError(statusCode: Int, message: String)
    /// リクエストが不正 (400)
    case badRequest(String)
    /// 認証エラー (401)
    case unauthorized
    /// アクセス禁止 (403)
    case forbidden
    /// リソースが見つからない (404)
    case notFound
    /// サーバーエラー (500系)
    case serverError(statusCode: Int)

    // MARK: - データ処理エラー
    /// デコードエラー
    case decodeError(String)
    /// データが空
    case emptyData
    /// HTMLパースエラー
    case htmlParseError(String)

    // MARK: - リトライ関連
    /// リトライ上限に達した
    case retryLimitExceeded(lastError: String)

    // MARK: - キャッシュ関連
    /// キャッシュ読み込みエラー
    case cacheReadError
    /// キャッシュ書き込みエラー
    case cacheWriteError

    // MARK: - その他
    /// リクエストエラー
    case requestError(Error?)
    /// キャンセルされた
    case cancelled
    /// 不明なエラー
    case unknownError(String)

    // MARK: - 後方互換性のためのエイリアス
    /// 非推奨: invalidURLを使用してください
    @available(*, deprecated, renamed: "invalidURL")
    static var invalideURL: APIError { .invalidURL }
    /// 非推奨: decodeErrorを使用してください
    @available(*, deprecated, renamed: "decodeError")
    static func decodeErrror(_ message: String) -> APIError { .decodeError(message) }

    // MARK: - Equatable
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.timeout, .timeout),
             (.noConnection, .noConnection),
             (.sslError, .sslError),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.emptyData, .emptyData),
             (.cacheReadError, .cacheReadError),
             (.cacheWriteError, .cacheWriteError),
             (.cancelled, .cancelled):
            return true
        case (.httpError(let lCode, let lMsg), .httpError(let rCode, let rMsg)):
            return lCode == rCode && lMsg == rMsg
        case (.badRequest(let lMsg), .badRequest(let rMsg)):
            return lMsg == rMsg
        case (.serverError(let lCode), .serverError(let rCode)):
            return lCode == rCode
        case (.decodeError(let lMsg), .decodeError(let rMsg)):
            return lMsg == rMsg
        case (.htmlParseError(let lMsg), .htmlParseError(let rMsg)):
            return lMsg == rMsg
        case (.retryLimitExceeded(let lErr), .retryLimitExceeded(let rErr)):
            return lErr == rErr
        case (.unknownError(let lMsg), .unknownError(let rMsg)):
            return lMsg == rMsg
        case (.requestError, .requestError):
            return true // Errorは直接比較できないのでtrueとする
        default:
            return false
        }
    }
}

// MARK: - LocalizedError
extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .timeout:
            return "リクエストがタイムアウトしました"
        case .noConnection:
            return "ネットワーク接続がありません"
        case .sslError:
            return "SSL証明書の検証に失敗しました"
        case .httpError(let statusCode, let message):
            return "HTTPエラー (\(statusCode)): \(message)"
        case .badRequest(let message):
            return "不正なリクエスト: \(message)"
        case .unauthorized:
            return "認証が必要です"
        case .forbidden:
            return "アクセスが拒否されました"
        case .notFound:
            return "リソースが見つかりませんでした"
        case .serverError(let statusCode):
            return "サーバーエラー (\(statusCode))"
        case .decodeError(let message):
            return "データの解析に失敗しました: \(message)"
        case .emptyData:
            return "データが空です"
        case .htmlParseError(let message):
            return "HTMLの解析に失敗しました: \(message)"
        case .retryLimitExceeded(let lastError):
            return "リトライ上限に達しました: \(lastError)"
        case .cacheReadError:
            return "キャッシュの読み込みに失敗しました"
        case .cacheWriteError:
            return "キャッシュの書き込みに失敗しました"
        case .requestError(let error):
            return "リクエストエラー: \(error?.localizedDescription ?? "不明")"
        case .cancelled:
            return "リクエストがキャンセルされました"
        case .unknownError(let message):
            return "不明なエラー: \(message)"
        }
    }
}

// MARK: - リトライ可能判定
extension APIError {
    /// このエラーがリトライ可能かどうか
    public var isRetryable: Bool {
        switch self {
        case .timeout, .noConnection, .serverError:
            return true
        case .httpError(let statusCode, _):
            // 5xx系エラーはリトライ可能
            return (500...599).contains(statusCode)
        default:
            return false
        }
    }
}

// MARK: - URLError変換
extension APIError {
    /// URLErrorからAPIErrorに変換
    public static func from(_ urlError: URLError) -> APIError {
        switch urlError.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .cancelled:
            return .cancelled
        case .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateNotYetValid:
            return .sslError
        case .badURL:
            return .invalidURL
        default:
            return .requestError(urlError)
        }
    }
}

// MARK: - HTTPURLResponse変換
extension APIError {
    /// HTTPレスポンスステータスコードからAPIErrorに変換
    public static func from(statusCode: Int, data: Data? = nil) -> APIError? {
        guard !(200...299).contains(statusCode) else { return nil }

        let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

        switch statusCode {
        case 400:
            return .badRequest(message)
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .httpError(statusCode: statusCode, message: message)
        }
    }
}
