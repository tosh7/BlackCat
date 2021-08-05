import Foundation

final class DeliveryListViewModel: ObservableObject {
    private let goodsIdList: [Int] = [429636181995, 398629940844]
    @Published var tneko: Tneko?

    init() {
        apiClient.tneko(.init(number01: 429636181995, number02: 398629940844), completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(tneko):
                DispatchQueue.main.async {
                    self.tneko = tneko
                }
            case .failure: break
            }
        })
    }
}
