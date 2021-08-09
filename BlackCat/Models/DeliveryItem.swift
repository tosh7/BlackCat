import Foundation
import Domain

struct DeliveryItem: Identifiable {
    let id = UUID()
    let deliveryID: Int
    let statusList: [DeliveryStatus]
}

extension DeliveryItem {
    init(deliveryList: Tneko.DeliveryList) {
        self.deliveryID = deliveryList.deliveryID
        self.statusList = deliveryList.statusList.map {
            DeliveryStatus(deliveryStatus: $0)
        }
    }
}
