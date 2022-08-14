import UIKit
import Domain
import Combine

protocol DeliveryListViewModelInputs {
    func onAppear()
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
    private var shouldReload: Bool = false
    private var cancellables: Set<AnyCancellable> = []

    init() {
        $onAppearPublisher.sink { _ in
            guard self.shouldReload else { return }
            self.loadItem()
            self.shouldReload = false
        }
        .store(in: &cancellables)

        // Notifications
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: .addItem),
            NotificationCenter.default.publisher(for: .removeItem),
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
        .sink { [weak self] _ in
            self?.shouldReload = true
        }
        .store(in: &cancellables)
    }

    @Published private var onAppearPublisher: Void?
    func onAppear() {
        onAppearPublisher = ()
    }

    private func loadItem() {
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
