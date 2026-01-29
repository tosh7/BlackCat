import Foundation
import Combine

// MARK: - Combine Future API
public extension ApiClient {
    /// ヤマト運輸の配送状況を取得（Combine Future版）
    /// - Parameters:
    ///   - request: TnekoRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    /// - Returns: Future<Tneko, APIError>
    func tneko(_ request: TnekoRequest, useCache: Bool = true) -> Future<Tneko, APIError> {
        return Future() { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            // キャッシュチェック
            if useCache && self.configuration.cacheEnabled {
                let trackingNumbers = request.idList().map { String($0) }
                var cachedInfos: [UnifiedDeliveryInfo] = []

                for trackingNumber in trackingNumbers {
                    if let cached = self.cache.get(for: trackingNumber, carrier: .yamato) {
                        cachedInfos.append(cached)
                    }
                }

                // すべてのトラッキング番号がキャッシュにある場合
                if cachedInfos.count == trackingNumbers.count && !cachedInfos.isEmpty {
                    let tneko = self.tnekoFromCacheFuture(cachedInfos)
                    promise(.success(tneko))
                    return
                }
            }

            guard let urlRequest: URLRequest = URLRequest(request, baseURL: self.baseURL) else {
                promise(.failure(.invalidURL))
                return
            }

            self.fetchWithRetry(urlRequest: urlRequest) { [weak self] result in
                guard let self = self else {
                    promise(.failure(.unknownError("ApiClient was deallocated")))
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
                            self.cacheDeliveryInfoFuture(tneko)
                        }

                        promise(.success(tneko))

                    case .failure(let error):
                        self.handleErrorWithCacheFuture(error: error, request: request, promise: promise)
                    }

                case .failure(let error):
                    self.handleErrorWithCacheFuture(error: error, request: request, promise: promise)
                }
            }
        }
    }

    /// 佐川急便の配送状況を取得（Combine Future版）
    /// - Parameters:
    ///   - request: SagawaRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    /// - Returns: Future<Sagawa, APIError>
    func sagawa(_ request: SagawaRequest, useCache: Bool = true) -> Future<Sagawa, APIError> {
        return Future() { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            // キャッシュチェック
            if useCache && self.configuration.cacheEnabled {
                if let cached = self.cache.get(for: request.trackingNumber, carrier: .sagawa) {
                    let sagawa = self.sagawaFromCacheFuture([cached])
                    promise(.success(sagawa))
                    return
                }
            }

            guard let urlRequest: URLRequest = URLRequest(request, baseURL: self.sagawaBaseURL) else {
                promise(.failure(.invalidURL))
                return
            }

            self.fetchWithRetry(urlRequest: urlRequest) { [weak self] result in
                guard let self = self else {
                    promise(.failure(.unknownError("ApiClient was deallocated")))
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
                            self.cacheDeliveryInfoFuture(sagawa)
                        }

                        promise(.success(sagawa))

                    case .failure(let error):
                        self.handleErrorWithCacheFuture(error: error, request: request, promise: promise)
                    }

                case .failure(let error):
                    self.handleErrorWithCacheFuture(error: error, request: request, promise: promise)
                }
            }
        }
    }

    /// 日本郵便の配送状況を取得（Combine Future版）
    /// - Parameters:
    ///   - request: JapanPostRequest
    ///   - useCache: キャッシュを使用するかどうか（デフォルト: true）
    /// - Returns: Future<JapanPost, APIError>
    func japanPost(_ request: JapanPostRequest, useCache: Bool = true) -> Future<JapanPost, APIError> {
        return Future() { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            // キャッシュチェック
            if useCache && self.configuration.cacheEnabled {
                if let cached = self.cache.get(for: request.trackingNumber, carrier: .japanPost) {
                    let japanPost = self.japanPostFromCacheFuture([cached])
                    promise(.success(japanPost))
                    return
                }
            }

            guard let urlRequest: URLRequest = URLRequest(request, baseURL: self.japanPostBaseURL) else {
                promise(.failure(.invalidURL))
                return
            }

            self.fetchWithRetry(urlRequest: urlRequest) { [weak self] result in
                guard let self = self else {
                    promise(.failure(.unknownError("ApiClient was deallocated")))
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
                            self.cacheDeliveryInfoFuture(japanPost)
                        }

                        promise(.success(japanPost))

                    case .failure(let error):
                        self.handleErrorWithCacheFuture(error: error, request: request, promise: promise)
                    }

                case .failure(let error):
                    self.handleErrorWithCacheFuture(error: error, request: request, promise: promise)
                }
            }
        }
    }

    /// 統一形式で配送情報を取得（Combine Future版）
    /// - Parameters:
    ///   - trackingNumber: 追跡番号
    ///   - carrier: 配送業者
    ///   - useCache: キャッシュを使用するかどうか
    /// - Returns: Future<UnifiedDeliveryInfo, APIError>
    func fetchDeliveryInfo(
        trackingNumber: String,
        carrier: DeliveryCarrierType,
        useCache: Bool = true
    ) -> Future<UnifiedDeliveryInfo, APIError> {
        return Future() { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknownError("ApiClient was deallocated")))
                return
            }

            // キャッシュチェック
            if useCache && self.configuration.cacheEnabled {
                if let cached = self.cache.get(for: trackingNumber, carrier: carrier) {
                    promise(.success(cached))
                    return
                }
            }

            switch carrier {
            case .yamato:
                guard let trackingInt = Int(trackingNumber) else {
                    promise(.failure(.invalidURL))
                    return
                }
                let request = TnekoRequest(numbers: [trackingInt])
                self.tneko(request, useCache: false) { result in
                    switch result {
                    case .success(let tneko):
                        let infos = tneko.toUnifiedDeliveryInfo()
                        if let info = infos.first {
                            promise(.success(info))
                        } else {
                            promise(.failure(.emptyData))
                        }

                    case .failure(let error):
                        promise(.failure(error))
                    }
                }

            case .sagawa:
                let request = SagawaRequest(trackingNumber: trackingNumber)
                self.sagawa(request, useCache: false) { result in
                    switch result {
                    case .success(let sagawa):
                        let infos = sagawa.toUnifiedDeliveryInfo()
                        if let info = infos.first {
                            promise(.success(info))
                        } else {
                            promise(.failure(.emptyData))
                        }

                    case .failure(let error):
                        promise(.failure(error))
                    }
                }

            case .japanPost:
                let request = JapanPostRequest(trackingNumber: trackingNumber)
                self.japanPost(request, useCache: false) { result in
                    switch result {
                    case .success(let japanPost):
                        let infos = japanPost.toUnifiedDeliveryInfo()
                        if let info = infos.first {
                            promise(.success(info))
                        } else {
                            promise(.failure(.emptyData))
                        }

                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}

// MARK: - AnyPublisher Extensions
public extension ApiClient {
    /// ヤマト運輸の配送状況を取得（AnyPublisher版）
    func tnekoPublisher(_ request: TnekoRequest, useCache: Bool = true) -> AnyPublisher<Tneko, APIError> {
        return tneko(request, useCache: useCache).eraseToAnyPublisher()
    }

    /// 佐川急便の配送状況を取得（AnyPublisher版）
    func sagawaPublisher(_ request: SagawaRequest, useCache: Bool = true) -> AnyPublisher<Sagawa, APIError> {
        return sagawa(request, useCache: useCache).eraseToAnyPublisher()
    }

    /// 統一形式で配送情報を取得（AnyPublisher版）
    func fetchDeliveryInfoPublisher(
        trackingNumber: String,
        carrier: DeliveryCarrierType,
        useCache: Bool = true
    ) -> AnyPublisher<UnifiedDeliveryInfo, APIError> {
        return fetchDeliveryInfo(trackingNumber: trackingNumber, carrier: carrier, useCache: useCache)
            .eraseToAnyPublisher()
    }
}

// MARK: - Future用キャッシュヘルパー（privateアクセス制御のため別途定義）
private extension ApiClient {
    /// Tnekoの配送情報をキャッシュに保存
    func cacheDeliveryInfoFuture(_ tneko: Tneko) {
        let infos = tneko.toUnifiedDeliveryInfo()
        for info in infos {
            cache.set(info, for: info.trackingNumber, carrier: .yamato)
        }
    }

    /// Sagawaの配送情報をキャッシュに保存
    func cacheDeliveryInfoFuture(_ sagawa: Sagawa) {
        let infos = sagawa.toUnifiedDeliveryInfo()
        for info in infos {
            cache.set(info, for: info.trackingNumber, carrier: .sagawa)
        }
    }

    /// キャッシュからTnekoを復元
    func tnekoFromCacheFuture(_ cachedInfos: [UnifiedDeliveryInfo]) -> Tneko {
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
    func sagawaFromCacheFuture(_ cachedInfos: [UnifiedDeliveryInfo]) -> Sagawa {
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

    /// エラー時にキャッシュからフォールバック（Future版 - Tneko）
    func handleErrorWithCacheFuture(
        error: APIError,
        request: TnekoRequest,
        promise: @escaping (Result<Tneko, APIError>) -> Void
    ) {
        if configuration.returnCacheOnError {
            let trackingNumbers = request.idList().map { String($0) }
            var cachedInfos: [UnifiedDeliveryInfo] = []

            for trackingNumber in trackingNumbers {
                if let cached = cache.get(for: trackingNumber, carrier: .yamato) {
                    cachedInfos.append(cached)
                }
            }

            if !cachedInfos.isEmpty {
                let tneko = tnekoFromCacheFuture(cachedInfos)
                promise(.success(tneko))
                return
            }
        }
        promise(.failure(error))
    }

    /// エラー時にキャッシュからフォールバック（Future版 - Sagawa）
    func handleErrorWithCacheFuture(
        error: APIError,
        request: SagawaRequest,
        promise: @escaping (Result<Sagawa, APIError>) -> Void
    ) {
        if configuration.returnCacheOnError {
            if let cached = cache.get(for: request.trackingNumber, carrier: .sagawa) {
                let sagawa = sagawaFromCacheFuture([cached])
                promise(.success(sagawa))
                return
            }
        }
        promise(.failure(error))
    }

    // MARK: - JapanPost キャッシュヘルパー

    /// JapanPostの配送情報をキャッシュに保存
    func cacheDeliveryInfoFuture(_ japanPost: JapanPost) {
        let infos = japanPost.toUnifiedDeliveryInfo()
        for info in infos {
            cache.set(info, for: info.trackingNumber, carrier: .japanPost)
        }
    }

    /// キャッシュからJapanPostを復元
    func japanPostFromCacheFuture(_ cachedInfos: [UnifiedDeliveryInfo]) -> JapanPost {
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

    /// エラー時にキャッシュからフォールバック（Future版 - JapanPost）
    func handleErrorWithCacheFuture(
        error: APIError,
        request: JapanPostRequest,
        promise: @escaping (Result<JapanPost, APIError>) -> Void
    ) {
        if configuration.returnCacheOnError {
            if let cached = cache.get(for: request.trackingNumber, carrier: .japanPost) {
                let japanPost = japanPostFromCacheFuture([cached])
                promise(.success(japanPost))
                return
            }
        }
        promise(.failure(error))
    }
}
