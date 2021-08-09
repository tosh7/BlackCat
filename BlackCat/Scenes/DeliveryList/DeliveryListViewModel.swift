import Foundation

protocol DeliveryListViewModelInputs {

}

protocol DeliveryListViewModelOutputs {
    var deliveryList: [Tneko.DeliveryList] { get }
}

protocol DeliveruListViewModelType {
    var input: DeliveryListViewModelInputs { get }
    var output: DeliveryListViewModelOutputs { get }
}

final class DeliveryListViewModel: ObservableObject, DeliveruListViewModelType, DeliveryListViewModelInputs, DeliveryListViewModelOutputs {
    private let goodsIdList: [Int] = [429636181995, 398629940844]
    @Published var deliveryList: [Tneko.DeliveryList] = []

    init() {
        apiClient.tneko(.init(numbers: goodsIdList), completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(tneko):
                DispatchQueue.main.async {
                    self.deliveryList = tneko.deriveryList
                }
            case .failure: break
            }
        })
    }

    var input: DeliveryListViewModelInputs { return self }
    var output: DeliveryListViewModelOutputs { return self }
}
