import Foundation

typealias DeliveryStatus = Tneko.DeliveryList.DeliveryStatus

extension DeliveryStatus {
    var deliveryStatus: DeliveryStatusType? {
        switch self.status {
        case "荷物受付":
            return .received
        case "発送済み":
            return .sended
        case "輸送中":
            return .delivering
        case "配達完了":
            return .delivered
        default:
            return nil
        }
    }
}
