import Foundation

final class StateDetailViewModel: ObservableObject {
    @Published var showingAlert: Bool = false

    func deleteDeliveryItem(id: Int) {
        LocalDeliveryItems.shared.remove(id: id)
        showingAlert = true
        NotificationCenter.default.post(name: .removeItem, object: nil)
    }
}
