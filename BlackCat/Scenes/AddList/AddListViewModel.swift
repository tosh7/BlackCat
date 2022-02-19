import Foundation
import Combine
import Domain

protocol AddListViewModelInputs {
    func textFieldDidChange(text: String)
    func buttonDidTap(text: String)
}

protocol AddListViewModelOutputs {}

protocol AddListViewModelType {
    var input: AddListViewModelInputs { get }
    var output: AddListViewModelOutputs { get }
}

final class AddListViewModel: ObservableObject, AddListViewModelType, AddListViewModelInputs, AddListViewModelOutputs {

    init() {
        self.showingAlert = false
    }

    // MARK: Inputs
    @Published var deliveryID: String = ""

    // MARK: Outputs
    @Published var showingAlert: Bool
    @Published var isButtonEnabled: Bool = false
    var errorMessage: String = ""

    var inputText: AnyPublisher<String, Never>!
    func textFieldDidChange(text: String) {
        deliveryID = text

        _ = $deliveryID
            .map { $0.count == 12 }
            .assign(to: \.isButtonEnabled, on: self)
    }

    func buttonDidTap(text: String) {
        guard let itemNumber = Int(text),
              !text.isEmpty && text.count == 12 else {
            errorMessage = "入力形式が違います"
            return
        }

        errorMessage = "登録に成功しました"

        apiClient.tneko(.init(numbers: [itemNumber]), completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(tneko):
                if tneko.deriveryList[0].statusList.count == 0 {
                    self.errorMessage = "登録に失敗しました"
                } else {
                    LocalDeliveryItems.shared.add(itemNumber)
                    self.errorMessage = "登録に成功しました"
                    DispatchQueue.main.async {
                        self.showingAlert = true
                    }
                    // SwiftUIのバグで、showingAlertの文字がpublishされなくなってしまうので、
                    // ここでは、3秒後に実行するようにしている
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                        NotificationCenter.default.post(name: .addItem, object: nil)
                    })
                }
            case .failure:
                self.errorMessage = "登録に失敗しました"
            }
        })
    }

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }
}
