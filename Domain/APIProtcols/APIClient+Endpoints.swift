import UIKit

// MARK: - Completion Handler API (レガシー互換)
public extension ApiClient {
    /// ヤマト運輸の配送状況を取得（completion handler版）
    /// - Parameters:
    ///   - request: TnekoRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    ///   - completion: 結果のコールバック
    func tneko(_ request: TnekoRequest, useCache: Bool = true, completion: @escaping (Result<Tneko, APIError>) -> Void) {
        // キャッシュチェック
        if useCache && configuration.cacheEnabled {
            let trackingNumbers = request.idList().map { String($0) }
            var cachedInfos: [UnifiedDeliveryInfo] = []

            for trackingNumber in trackingNumbers {
                if let cached = cache.get(for: trackingNumber, carrier: .yamato) {
                    cachedInfos.append(cached)
                }
            }

            // すべてのトラッキング番号がキャッシュにある場合
            if cachedInfos.count == trackingNumbers.count && !cachedInfos.isEmpty {
                let tneko = tnekoFromCache(cachedInfos)
                completion(.success(tneko))
                return
            }
        }

        guard let urlRequest: URLRequest = URLRequest(request, baseURL: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }

        fetchWithRetry(urlRequest: urlRequest) { [weak self] result in
            guard let self = self else {
                completion(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            switch result {
            case .success(let data):
                switch self.parseHTML(from: data) {
                case .success(let htmlString):
                    let tneko = Tneko(
                        idList: request.idList(),
                        response: htmlString
                    )

                    // キャッシュに保存
                    if self.configuration.cacheEnabled {
                        self.cacheDeliveryInfo(tneko)
                    }

                    completion(.success(tneko))

                case .failure(let error):
                    self.handleErrorWithCache(error: error, request: request, completion: completion)
                }

            case .failure(let error):
                self.handleErrorWithCache(error: error, request: request, completion: completion)
            }
        }
    }

    /// 佐川急便の配送状況を取得（completion handler版）
    /// - Parameters:
    ///   - request: SagawaRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    ///   - completion: 結果のコールバック
    func sagawa(_ request: SagawaRequest, useCache: Bool = true, completion: @escaping (Result<Sagawa, APIError>) -> Void) {
        // キャッシュチェック
        if useCache && configuration.cacheEnabled {
            if let cached = cache.get(for: request.trackingNumber, carrier: .sagawa) {
                let sagawa = sagawaFromCache([cached])
                completion(.success(sagawa))
                return
            }
        }

        guard let urlRequest: URLRequest = URLRequest(request, baseURL: sagawaBaseURL) else {
            completion(.failure(.invalidURL))
            return
        }

        fetchWithRetry(urlRequest: urlRequest) { [weak self] result in
            guard let self = self else {
                completion(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            switch result {
            case .success(let data):
                switch self.parseHTML(from: data) {
                case .success(let htmlString):
                    let sagawa = Sagawa(
                        trackingNumber: request.trackingNumber,
                        response: htmlString
                    )

                    // キャッシュに保存
                    if self.configuration.cacheEnabled {
                        self.cacheDeliveryInfo(sagawa)
                    }

                    completion(.success(sagawa))

                case .failure(let error):
                    self.handleErrorWithCache(error: error, request: request, completion: completion)
                }

            case .failure(let error):
                self.handleErrorWithCache(error: error, request: request, completion: completion)
            }
        }
    }

    /// 日本郵便の配送状況を取得（completion handler版）
    /// - Parameters:
    ///   - request: JapanPostRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    ///   - completion: 結果のコールバック
    func japanPost(_ request: JapanPostRequest, useCache: Bool = true, completion: @escaping (Result<JapanPost, APIError>) -> Void) {
        // キャッシュチェック
        if useCache && configuration.cacheEnabled {
            if let cached = cache.get(for: request.trackingNumber, carrier: .japanPost) {
                let japanPost = japanPostFromCache([cached])
                completion(.success(japanPost))
                return
            }
        }

        guard let urlRequest: URLRequest = URLRequest(request, baseURL: japanPostBaseURL) else {
            completion(.failure(.invalidURL))
            return
        }

        fetchWithRetry(urlRequest: urlRequest) { [weak self] result in
            guard let self = self else {
                completion(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            switch result {
            case .success(let data):
                switch self.parseHTML(from: data) {
                case .success(let htmlString):
                    let japanPost = JapanPost(
                        trackingNumber: request.trackingNumber,
                        response: htmlString
                    )

                    // キャッシュに保存
                    if self.configuration.cacheEnabled {
                        self.cacheDeliveryInfo(japanPost)
                    }

                    completion(.success(japanPost))

                case .failure(let error):
                    self.handleErrorWithCache(error: error, request: request, completion: completion)
                }

            case .failure(let error):
                self.handleErrorWithCache(error: error, request: request, completion: completion)
            }
        }
    }
}

// MARK: - Async/Await API
public extension ApiClient {
    /// ヤマト運輸の配送状況を取得（async/await版）
    /// - Parameters:
    ///   - request: TnekoRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    /// - Returns: Result<Tneko, APIError>
    func tneko(_ request: TnekoRequest, useCache: Bool = true) async -> Result<Tneko, APIError> {
        // キャッシュチェック
        if useCache && configuration.cacheEnabled {
            let trackingNumbers = request.idList().map { String($0) }
            var cachedInfos: [UnifiedDeliveryInfo] = []

            for trackingNumber in trackingNumbers {
                if let cached = cache.get(for: trackingNumber, carrier: .yamato) {
                    cachedInfos.append(cached)
                }
            }

            // すべてのトラッキング番号がキャッシュにある場合
            if cachedInfos.count == trackingNumbers.count && !cachedInfos.isEmpty {
                let tneko = tnekoFromCache(cachedInfos)
                return .success(tneko)
            }
        }

        guard let urlRequest: URLRequest = URLRequest(request, baseURL: baseURL) else {
            return .failure(.invalidURL)
        }

        let result = await fetchWithRetry(urlRequest: urlRequest)

        switch result {
        case .success(let data):
            switch parseHTML(from: data) {
            case .success(let htmlString):
                let tneko = Tneko(
                    idList: request.idList(),
                    response: htmlString
                )

                // キャッシュに保存
                if configuration.cacheEnabled {
                    cacheDeliveryInfo(tneko)
                }

                return .success(tneko)

            case .failure(let error):
                return handleErrorWithCacheAsync(error: error, request: request)
            }

        case .failure(let error):
            return handleErrorWithCacheAsync(error: error, request: request)
        }
    }

    /// 佐川急便の配送状況を取得（async/await版）
    /// - Parameters:
    ///   - request: SagawaRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    /// - Returns: Result<Sagawa, APIError>
    func sagawa(_ request: SagawaRequest, useCache: Bool = true) async -> Result<Sagawa, APIError> {
        // キャッシュチェック
        if useCache && configuration.cacheEnabled {
            if let cached = cache.get(for: request.trackingNumber, carrier: .sagawa) {
                let sagawa = sagawaFromCache([cached])
                return .success(sagawa)
            }
        }

        guard let urlRequest: URLRequest = URLRequest(request, baseURL: sagawaBaseURL) else {
            return .failure(.invalidURL)
        }

        let result = await fetchWithRetry(urlRequest: urlRequest)

        switch result {
        case .success(let data):
            switch parseHTML(from: data) {
            case .success(let htmlString):
                let sagawa = Sagawa(
                    trackingNumber: request.trackingNumber,
                    response: htmlString
                )

                // キャッシュに保存
                if configuration.cacheEnabled {
                    cacheDeliveryInfo(sagawa)
                }

                return .success(sagawa)

            case .failure(let error):
                return handleErrorWithCacheAsync(error: error, request: request)
            }

        case .failure(let error):
            return handleErrorWithCacheAsync(error: error, request: request)
        }
    }

    /// 日本郵便の配送状況を取得（async/await版）
    /// - Parameters:
    ///   - request: JapanPostRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    /// - Returns: Result<JapanPost, APIError>
    func japanPost(_ request: JapanPostRequest, useCache: Bool = true) async -> Result<JapanPost, APIError> {
        // キャッシュチェック
        if useCache && configuration.cacheEnabled {
            if let cached = cache.get(for: request.trackingNumber, carrier: .japanPost) {
                let japanPost = japanPostFromCache([cached])
                return .success(japanPost)
            }
        }

        guard let urlRequest: URLRequest = URLRequest(request, baseURL: japanPostBaseURL) else {
            return .failure(.invalidURL)
        }

        let result = await fetchWithRetry(urlRequest: urlRequest)

        switch result {
        case .success(let data):
            switch parseHTML(from: data) {
            case .success(let htmlString):
                let japanPost = JapanPost(
                    trackingNumber: request.trackingNumber,
                    response: htmlString
                )

                // キャッシュに保存
                if configuration.cacheEnabled {
                    cacheDeliveryInfo(japanPost)
                }

                return .success(japanPost)

            case .failure(let error):
                return handleErrorWithCacheAsync(error: error, request: request)
            }

        case .failure(let error):
            return handleErrorWithCacheAsync(error: error, request: request)
        }
    }
}

// MARK: - 統一インターフェース API
public extension ApiClient {
    /// 統一形式で配送情報を取得（async/await版）
    /// - Parameters:
    ///   - trackingNumber: 追跡番号
    ///   - carrier: 配送業者
    ///   - useCache: キャッシュを使用するかどうか
    /// - Returns: Result<UnifiedDeliveryInfo, APIError>
    func fetchDeliveryInfo(
        trackingNumber: String,
        carrier: DeliveryCarrierType,
        useCache: Bool = true
    ) async -> Result<UnifiedDeliveryInfo, APIError> {
        // キャッシュチェック
        if useCache && configuration.cacheEnabled {
            if let cached = cache.get(for: trackingNumber, carrier: carrier) {
                return .success(cached)
            }
        }

        switch carrier {
        case .yamato:
            guard let trackingInt = Int(trackingNumber) else {
                return .failure(.invalidURL)
            }
            let request = TnekoRequest(numbers: [trackingInt])
            let result = await tneko(request, useCache: false)

            switch result {
            case .success(let tneko):
                let infos = tneko.toUnifiedDeliveryInfo()
                if let info = infos.first {
                    return .success(info)
                }
                return .failure(.emptyData)

            case .failure(let error):
                return .failure(error)
            }

        case .sagawa:
            let request = SagawaRequest(trackingNumber: trackingNumber)
            let result = await sagawa(request, useCache: false)

            switch result {
            case .success(let sagawa):
                let infos = sagawa.toUnifiedDeliveryInfo()
                if let info = infos.first {
                    return .success(info)
                }
                return .failure(.emptyData)

            case .failure(let error):
                return .failure(error)
            }

        case .japanPost:
            let request = JapanPostRequest(trackingNumber: trackingNumber)
            let result = await japanPost(request, useCache: false)

            switch result {
            case .success(let japanPost):
                let infos = japanPost.toUnifiedDeliveryInfo()
                if let info = infos.first {
                    return .success(info)
                }
                return .failure(.emptyData)

            case .failure(let error):
                return .failure(error)
            }
        }
    }

    /// 複数の追跡番号の配送情報を一括取得
    /// - Parameters:
    ///   - trackingNumbers: 追跡番号と配送業者のペアの配列
    ///   - useCache: キャッシュを使用するかどうか
    /// - Returns: 追跡番号をキーとした結果の辞書
    func fetchDeliveryInfoBatch(
        trackingNumbers: [(trackingNumber: String, carrier: DeliveryCarrierType)],
        useCache: Bool = true
    ) async -> [String: Result<UnifiedDeliveryInfo, APIError>] {
        var results: [String: Result<UnifiedDeliveryInfo, APIError>] = [:]

        await withTaskGroup(of: (String, Result<UnifiedDeliveryInfo, APIError>).self) { group in
            for (trackingNumber, carrier) in trackingNumbers {
                group.addTask {
                    let result = await self.fetchDeliveryInfo(
                        trackingNumber: trackingNumber,
                        carrier: carrier,
                        useCache: useCache
                    )
                    return (trackingNumber, result)
                }
            }

            for await (trackingNumber, result) in group {
                results[trackingNumber] = result
            }
        }

        return results
    }
}

// MARK: - キャッシュヘルパー
private extension ApiClient {
    /// Tnekoの配送情報をキャッシュに保存
    func cacheDeliveryInfo(_ tneko: Tneko) {
        let infos = tneko.toUnifiedDeliveryInfo()
        for info in infos {
            cache.set(info, for: info.trackingNumber, carrier: .yamato)
        }
    }

    /// Sagawaの配送情報をキャッシュに保存
    func cacheDeliveryInfo(_ sagawa: Sagawa) {
        let infos = sagawa.toUnifiedDeliveryInfo()
        for info in infos {
            cache.set(info, for: info.trackingNumber, carrier: .sagawa)
        }
    }

    /// JapanPostの配送情報をキャッシュに保存
    func cacheDeliveryInfo(_ japanPost: JapanPost) {
        let infos = japanPost.toUnifiedDeliveryInfo()
        for info in infos {
            cache.set(info, for: info.trackingNumber, carrier: .japanPost)
        }
    }

    /// キャッシュからTnekoを復元
    func tnekoFromCache(_ cachedInfos: [UnifiedDeliveryInfo]) -> Tneko {
        let deliveryList = cachedInfos.map { info in
            let statusList = info.statusList.map { status in
                Tneko.DeliveryList.DeliveryStatus(
                    status: status.status,
                    date: status.date,
                    time: status.time,
                    shopName: status.location
                )
            }
            return Tneko.DeliveryList(
                deliveryID: Int(info.trackingNumber) ?? 0,
                statusList: statusList
            )
        }
        return Tneko(deliveryList: deliveryList)
    }

    /// キャッシュからSagawaを復元
    func sagawaFromCache(_ cachedInfos: [UnifiedDeliveryInfo]) -> Sagawa {
        let trackingList = cachedInfos.map { info in
            let statusList = info.statusList.map { status in
                Sagawa.TrackingInfo.DeliveryStatus(
                    status: status.status,
                    date: status.date,
                    time: status.time,
                    location: status.location
                )
            }
            return Sagawa.TrackingInfo(
                trackingNumber: info.trackingNumber,
                statusList: statusList
            )
        }
        return Sagawa(trackingList: trackingList)
    }

    /// キャッシュからJapanPostを復元
    func japanPostFromCache(_ cachedInfos: [UnifiedDeliveryInfo]) -> JapanPost {
        let trackingList = cachedInfos.map { info in
            let statusList = info.statusList.map { status in
                JapanPost.TrackingInfo.DeliveryStatus(
                    status: status.status,
                    date: status.date,
                    time: status.time,
                    location: status.location
                )
            }
            return JapanPost.TrackingInfo(
                trackingNumber: info.trackingNumber,
                statusList: statusList
            )
        }
        return JapanPost(trackingList: trackingList)
    }

    /// エラー時にキャッシュからフォールバック（completion版 - Tneko）
    func handleErrorWithCache(error: APIError, request: TnekoRequest, completion: @escaping (Result<Tneko, APIError>) -> Void) {
        if configuration.returnCacheOnError {
            let trackingNumbers = request.idList().map { String($0) }
            var cachedInfos: [UnifiedDeliveryInfo] = []

            for trackingNumber in trackingNumbers {
                if let cached = cache.get(for: trackingNumber, carrier: .yamato) {
                    cachedInfos.append(cached)
                }
            }

            if !cachedInfos.isEmpty {
                let tneko = tnekoFromCache(cachedInfos)
                completion(.success(tneko))
                return
            }
        }
        completion(.failure(error))
    }

    /// エラー時にキャッシュからフォールバック（completion版 - Sagawa）
    func handleErrorWithCache(error: APIError, request: SagawaRequest, completion: @escaping (Result<Sagawa, APIError>) -> Void) {
        if configuration.returnCacheOnError {
            if let cached = cache.get(for: request.trackingNumber, carrier: .sagawa) {
                let sagawa = sagawaFromCache([cached])
                completion(.success(sagawa))
                return
            }
        }
        completion(.failure(error))
    }

    /// エラー時にキャッシュからフォールバック（async版 - Tneko）
    func handleErrorWithCacheAsync(error: APIError, request: TnekoRequest) -> Result<Tneko, APIError> {
        if configuration.returnCacheOnError {
            let trackingNumbers = request.idList().map { String($0) }
            var cachedInfos: [UnifiedDeliveryInfo] = []

            for trackingNumber in trackingNumbers {
                if let cached = cache.get(for: trackingNumber, carrier: .yamato) {
                    cachedInfos.append(cached)
                }
            }

            if !cachedInfos.isEmpty {
                let tneko = tnekoFromCache(cachedInfos)
                return .success(tneko)
            }
        }
        return .failure(error)
    }

    /// エラー時にキャッシュからフォールバック（async版 - Sagawa）
    func handleErrorWithCacheAsync(error: APIError, request: SagawaRequest) -> Result<Sagawa, APIError> {
        if configuration.returnCacheOnError {
            if let cached = cache.get(for: request.trackingNumber, carrier: .sagawa) {
                let sagawa = sagawaFromCache([cached])
                return .success(sagawa)
            }
        }
        return .failure(error)
    }

    /// エラー時にキャッシュからフォールバック（completion版 - JapanPost）
    func handleErrorWithCache(error: APIError, request: JapanPostRequest, completion: @escaping (Result<JapanPost, APIError>) -> Void) {
        if configuration.returnCacheOnError {
            if let cached = cache.get(for: request.trackingNumber, carrier: .japanPost) {
                let japanPost = japanPostFromCache([cached])
                completion(.success(japanPost))
                return
            }
        }
        completion(.failure(error))
    }

    /// エラー時にキャッシュからフォールバック（async版 - JapanPost）
    func handleErrorWithCacheAsync(error: APIError, request: JapanPostRequest) -> Result<JapanPost, APIError> {
        if configuration.returnCacheOnError {
            if let cached = cache.get(for: request.trackingNumber, carrier: .japanPost) {
                let japanPost = japanPostFromCache([cached])
                return .success(japanPost)
            }
        }
        return .failure(error)
    }
}
