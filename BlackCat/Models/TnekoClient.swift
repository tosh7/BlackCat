import Foundation
import Domain

struct TnekoClient: Identifiable {
    let id = UUID()
    var deliveryList: [DeliveryItem]
}

extension TnekoClient {
    init(tneko: Tneko, carrier: DeliveryCarrier = .yamato) {
        self.init(deliveryList: tneko.deliveryList.map {
            DeliveryItem(deliveryList: $0, carrier: carrier)
        })
    }
}
