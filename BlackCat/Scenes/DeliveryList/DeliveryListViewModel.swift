import UIKit
import Domain

protocol DeliveryListViewModelInputs {

}

protocol DeliveryListViewModelOutputs {
    var deliveryList: [DeliveryItem] { get }
}

protocol DeliveryListViewModelType {
    var input: DeliveryListViewModelInputs { get }
    var output: DeliveryListViewModelOutputs { get }
}

final class DeliveryListViewModel: ObservableObject, DeliveryListViewModelType, DeliveryListViewModelInputs, DeliveryListViewModelOutputs {
    private var goodsIdList: [Int] {
        return LocalDeliveryItems.shared.items
    }
    @Published var deliveryList: [DeliveryItem] = []

    init() {
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(loadItem), name: .addItem, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadItem), name: .removeItem, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadItem), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func loadItem() {
        Task { @MainActor in
            let result = await apiClient.tneko(.init(numbers: goodsIdList))
            guard let tneko = result.value else { return }
            let tnekoClient = TnekoClient(tneko: tneko)
            DispatchQueue.main.async {
                self.deliveryList = tnekoClient.deliveryList
            }
        }
    }

    var input: DeliveryListViewModelInputs { return self }
    var output: DeliveryListViewModelOutputs { return self }
}
