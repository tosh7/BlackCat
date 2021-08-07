import Foundation

final class DeliveryListViewModel: ObservableObject {
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
}
