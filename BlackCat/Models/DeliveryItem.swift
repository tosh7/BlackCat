import Foundation
import Domain

struct DeliveryItem: Identifiable {
    let id = UUID()
    let deliveryID: Int
    let statusList: [DeliveryStatus]
    let carrier: DeliveryCarrier
    let registeredDate: Date

    /// 最新のステータスを取得
    var latestStatus: DeliveryStatus? {
        statusList.first
    }

    /// 最新のステータスタイプを取得
    var latestStatusType: DeliveryStatusType? {
        latestStatus?.deliveryStatus
    }
}

extension DeliveryItem {
    init(deliveryList: Tneko.DeliveryList, carrier: DeliveryCarrier = .yamato) {
        self.deliveryID = deliveryList.deliveryID
        self.statusList = deliveryList.statusList.map {
            DeliveryStatus(deliveryStatus: $0)
        }
        self.carrier = carrier
        self.registeredDate = Date()
    }
}
