import Foundation
import Combine

final class StateDetailViewModel: ObservableObject {

    /// Delivery Item ID
    let deliveryItem: DeliveryItem
    var id: Int {
        deliveryItem.deliveryID
    }

    init(deliveryItem: DeliveryItem) {
        self.deliveryItem = deliveryItem
    }

    // MARK - Outputs

    @Published var showsDeletionAlert: Bool = false
    @Published var showsWidgetAlert: Bool = false

    // MARK - Inputs

    /// Remove an Item from userdefaults
    func deleteDeliveryItem() {
        LocalDeliveryItems.shared.remove(id: id)
        showsDeletionAlert = true
    }

    /// Set this object's id as a widget item
    func addWidgetDeliveryItem() {
        // TODO: Add item to widget list here
        showsWidgetAlert = true
    }
}
