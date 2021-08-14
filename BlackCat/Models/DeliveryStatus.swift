import SwiftUI
import Domain

enum DeliveryStatusType {
    case received
    case sended
    case shipping
    case delivering
    case delivered

    var color: Color {
        switch self {
        case .received:
            return Color.BlackCat.pureBlue
        case .sended:
            return Color.BlackCat.purePink
        case .shipping:
            return Color.BlackCat.pureOrange
        case .delivering:
            return Color.BlackCat.pureRed
        case .delivered:
            return Color.BlackCat.shadowLevel6
        }
    }
}

struct DeliveryStatus: Identifiable {
    let id = UUID()
    let status: String
    let date: String
    let time: String
    let shopName: String
    let shopID: String

    var deliveryStatus: DeliveryStatusType? {
        switch self.status {
        case "荷物受付":
            return .received
        case "発送済み":
            return .sended
        case "輸送中":
            return .shipping
        case "配達中":
            return .delivering
        case "配達完了":
            return .delivered
        default:
            return nil
        }
    }
}

extension DeliveryStatus {
    init(deliveryStatus: Tneko.DeliveryList.DeliveryStatus) {
        self.status = deliveryStatus.status
        self.date = deliveryStatus.date
        self.time = deliveryStatus.time
        self.shopName = deliveryStatus.shopName
        self.shopID = deliveryStatus.shopID
    }
}
