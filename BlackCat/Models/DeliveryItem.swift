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
        statusList.last
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

extension DeliveryItem {
    init(trackingInfo: Sagawa.TrackingInfo, carrier: DeliveryCarrier = .sagawa) {
        self.deliveryID = Int(trackingInfo.trackingNumber) ?? 0
        self.statusList = trackingInfo.statusList.map {
            DeliveryStatus(sagawaStatus: $0)
        }
        self.carrier = carrier
        self.registeredDate = Date()
    }
}
