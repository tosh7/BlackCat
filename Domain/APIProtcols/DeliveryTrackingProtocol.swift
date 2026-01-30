import Foundation

// MARK: - 配達業者の種別
public enum DeliveryCarrierType: String, Codable, CaseIterable {
    case yamato = "yamato"      // ヤマト運輸
    case sagawa = "sagawa"      // 佐川急便
    case japanPost = "japanPost" // 日本郵便

    public var displayName: String {
        switch self {
        case .yamato:
            return "ヤマト運輸"
        case .sagawa:
            return "佐川急便"
        case .japanPost:
            return "日本郵便"
        }
    }
}

// MARK: - 統一配送ステータス
public struct UnifiedDeliveryStatus: Codable, Equatable {
    public let status: String
    public let date: String
    public let time: String?
    public let location: String

    public init(status: String, date: String, time: String?, location: String) {
        self.status = status
        self.date = date
        self.time = time
        self.location = location
    }
}

// MARK: - 統一配送情報
public struct UnifiedDeliveryInfo: Codable, Equatable {
    public let trackingNumber: String
    public let carrier: DeliveryCarrierType
    public let statusList: [UnifiedDeliveryStatus]
    public let lastUpdated: Date

    public init(trackingNumber: String, carrier: DeliveryCarrierType, statusList: [UnifiedDeliveryStatus], lastUpdated: Date = Date()) {
        self.trackingNumber = trackingNumber
        self.carrier = carrier
        self.statusList = statusList
        self.lastUpdated = lastUpdated
    }

    /// 最新のステータスを取得
    public var latestStatus: UnifiedDeliveryStatus? {
        return statusList.first
    }

    /// 配達完了かどうか
    public var isDelivered: Bool {
        guard let latest = latestStatus else { return false }
        let deliveredKeywords = ["配達完了", "お届け済み", "完了", "配達済"]
        return deliveredKeywords.contains { latest.status.contains($0) }
    }
}

// MARK: - リクエストプロトコル
public protocol DeliveryTrackingRequestProtocol {
    var trackingNumbers: [String] { get }
    var carrier: DeliveryCarrierType { get }
}

// MARK: - レスポンスプロトコル
public protocol DeliveryTrackingResponseProtocol {
    /// 統一形式の配送情報に変換
    func toUnifiedDeliveryInfo() -> [UnifiedDeliveryInfo]
}

// MARK: - Tneko拡張
extension Tneko: DeliveryTrackingResponseProtocol {
    public func toUnifiedDeliveryInfo() -> [UnifiedDeliveryInfo] {
        return deliveryList.map { delivery in
            let statusList = delivery.statusList.map { status in
                UnifiedDeliveryStatus(
                    status: status.status,
                    date: status.date,
                    time: status.time,
                    location: status.shopName
                )
            }
            return UnifiedDeliveryInfo(
                trackingNumber: String(delivery.deliveryID),
                carrier: .yamato,
                statusList: statusList
            )
        }
    }
}

// MARK: - Sagawa拡張
extension Sagawa: DeliveryTrackingResponseProtocol {
    public func toUnifiedDeliveryInfo() -> [UnifiedDeliveryInfo] {
        return trackingList.map { tracking in
            let statusList = tracking.statusList.map { status in
                UnifiedDeliveryStatus(
                    status: status.status,
                    date: status.date,
                    time: status.time,
                    location: status.location
                )
            }
            return UnifiedDeliveryInfo(
                trackingNumber: tracking.trackingNumber,
                carrier: .sagawa,
                statusList: statusList
            )
        }
    }
}

// MARK: - TnekoRequest拡張
extension TnekoRequest: DeliveryTrackingRequestProtocol {
    public var trackingNumbers: [String] {
        return idList().map { String($0) }
    }

    public var carrier: DeliveryCarrierType {
        return .yamato
    }
}

// MARK: - SagawaRequest拡張
extension SagawaRequest: DeliveryTrackingRequestProtocol {
    public var trackingNumbers: [String] {
        return [trackingNumber]
    }

    public var carrier: DeliveryCarrierType {
        return .sagawa
    }
}

// MARK: - JapanPost拡張
extension JapanPost: DeliveryTrackingResponseProtocol {
    public func toUnifiedDeliveryInfo() -> [UnifiedDeliveryInfo] {
        return trackingList.map { tracking in
            let statusList = tracking.statusList.map { status in
                UnifiedDeliveryStatus(
                    status: status.status,
                    date: status.date,
                    time: status.time,
                    location: status.location
                )
            }
            return UnifiedDeliveryInfo(
                trackingNumber: tracking.trackingNumber,
                carrier: .japanPost,
                statusList: statusList
            )
        }
    }
}

// MARK: - JapanPostRequest拡張
extension JapanPostRequest: DeliveryTrackingRequestProtocol {
    public var trackingNumbers: [String] {
        return [trackingNumber]
    }

    public var carrier: DeliveryCarrierType {
        return .japanPost
    }
}
