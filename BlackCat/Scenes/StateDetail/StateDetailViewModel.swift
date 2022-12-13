import Foundation

final class StateDetailViewModel: ObservableObject {
    @Published var showingAlert: Bool = false

    func deleteDeliveryItem(id: Int) {
        showingAlert = true
        LocalDeliveryItems.shared.remove(id: id)
    }
}
