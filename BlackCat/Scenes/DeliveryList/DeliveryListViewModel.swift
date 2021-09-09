import Foundation
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
    private let goodsIdList: [Int]
    @Published var deliveryList: [DeliveryItem] = []

    init() {
        goodsIdList = LocalDeliveryItems.shared.items
        apiClient.tneko(.init(numbers: goodsIdList), completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(tneko):
                print(tneko)
                // FIXME: Using MockData for easy debugging
                let tnekoClient = TnekoClient(tneko: TnekoMock.tneko)
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
