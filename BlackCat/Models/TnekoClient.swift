import Foundation
import Domain

struct TnekoClient: Identifiable {
    let id = UUID()
    var deliveryList: [DeliveryItem]
}

extension TnekoClient {
    init(tneko: Tneko) {
        self.deliveryList = tneko.deriveryList.map {
            DeliveryItem(deliveryList: $0)
        }
    }
}
