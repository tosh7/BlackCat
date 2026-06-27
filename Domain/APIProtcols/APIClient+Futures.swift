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
            self.tneko(request, useCache: useCache) { result in
                promise(result)
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
            self.sagawa(request, useCache: useCache) { result in
                promise(result)
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
            self.japanPost(request, useCache: useCache) { result in
                promise(result)
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

            switch carrier {
            case .yamato:
                guard let trackingInt = Int(trackingNumber) else {
                    promise(.failure(.invalidURL))
                    return
                }
                self.tneko(TnekoRequest(numbers: [trackingInt]), useCache: useCache) { result in
                    promise(Self.firstInfo(from: result))
                }

            case .sagawa:
                self.sagawa(SagawaRequest(trackingNumber: trackingNumber), useCache: useCache) { result in
                    promise(Self.firstInfo(from: result))
                }

            case .japanPost:
                self.japanPost(JapanPostRequest(trackingNumber: trackingNumber), useCache: useCache) { result in
                    promise(Self.firstInfo(from: result))
                }
            }
        }
    }

    private static func firstInfo<T: DeliveryTrackingResponseProtocol>(
        from result: Result<T, APIError>
    ) -> Result<UnifiedDeliveryInfo, APIError> {
        result.flatMap { response in
            if let info = response.toUnifiedDeliveryInfo().first {
                return .success(info)
            }
            return .failure(.emptyData)
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
