import UIKit
import Domain
import Combine

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

    private var cancellables: Set<AnyCancellable> = []

    init() {
        // Notifications
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: .addItem),
            NotificationCenter.default.publisher(for: .removeItem),
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
        .sink { [weak self] _ in
            self?.loadItem()
        }
        .store(in: &cancellables)
    }

    private func loadItem() {
        apiClient.tneko(.init(numbers: goodsIdList), completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(tneko):
                let tnekoClient = TnekoClient(tneko: tneko)
                DispatchQueue.main.async {
                    self.deliveryList = tnekoClient.deliveryList
                }
            case .failure: break
            }
        })
    }

    var input: DeliveryListViewModelInputs { return self }
    var output: DeliveryListViewModelOutputs { return self }
}
