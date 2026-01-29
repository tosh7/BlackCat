import Foundation

/// iOS/watchOS間で共有する配達アイテムモデル
/// App Groupを通じて両プラットフォームでデータを共有する
public struct SharedDeliveryItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let trackingNumber: String
    public let carrierType: SharedCarrierType
    public let latestStatus: String
    public let latestDate: String?
    public let latestTime: String?
    public let shopName: String?
    public let statusType: SharedDeliveryStatusType
    public let registeredDate: Date

    public init(
        id: UUID = UUID(),
        trackingNumber: String,
        carrierType: SharedCarrierType,
        latestStatus: String,
        latestDate: String? = nil,
        latestTime: String? = nil,
        shopName: String? = nil,
        statusType: SharedDeliveryStatusType,
        registeredDate: Date = Date()
    ) {
        self.id = id
        self.trackingNumber = trackingNumber
        self.carrierType = carrierType
        self.latestStatus = latestStatus
        self.latestDate = latestDate
        self.latestTime = latestTime
        self.shopName = shopName
        self.statusType = statusType
        self.registeredDate = registeredDate
    }
}

// MARK: - Shared Carrier Type

/// 配送業者タイプ（共有用）
public enum SharedCarrierType: String, Codable, CaseIterable {
    case yamato = "yamato"
    case sagawa = "sagawa"
    case japanPost = "japanPost"

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

    public var iconName: String {
        switch self {
        case .yamato:
            return "shippingbox.fill"
        case .sagawa:
            return "truck.box.fill"
        case .japanPost:
            return "envelope.fill"
        }
    }
}

// MARK: - Shared Delivery Status Type

/// 配達ステータスタイプ（共有用）
public enum SharedDeliveryStatusType: String, Codable {
    case received = "received"
    case sended = "sended"
    case shipping = "shipping"
    case delivering = "delivering"
    case delivered = "delivered"
    case unknown = "unknown"

    /// ステータス文字列から変換
    public static func from(status: String) -> SharedDeliveryStatusType {
        switch status {
        case "荷物受付":
            return .received
        case "発送済み":
            return .sended
        case "輸送中":
            return .shipping
        case "配達中", "持戻（ご不在）", "配達日・時間帯指定（保管中）":
            return .delivering
        case "配達完了", "配達完了（宅配ボックス）":
            return .delivered
        default:
            return .unknown
        }
    }
}
