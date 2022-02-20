import Foundation
import Combine
import Domain

protocol AddListViewModelInputs {
    func textFieldDidChange(text: String)
    func buttonDidTap(text: String)
}

protocol AddListViewModelOutputs {
    var isButtonEnabled: Bool { get }
    var errorMessage: String { get }
    var cautionMessage: String { get }
}

protocol AddListViewModelType {
    var input: AddListViewModelInputs { get }
    var output: AddListViewModelOutputs { get }
}

final class AddListViewModel: ObservableObject, AddListViewModelType, AddListViewModelInputs, AddListViewModelOutputs {

    init() {
        inputTextSubscriber = $inputText
            .filter { Int($0) != nil }
            .map { $0.count == 12 }
            .assign(to: \.isButtonEnabled, on: self)

        errorMessageSubscriber = $inputText
            .compactMap { text in
                guard !text.isEmpty else { return "" }
                guard Int(text) != nil else { return "数字以外の文字が含まれています" }
                return text.count == 12 ? "" : "伝票番号は12文字です"
            }
            .assign(to: \.cautionMessage, on: self)
    }

    // MARK: Inputs
    @Published private var inputText: String = ""
    func textFieldDidChange(text: String) {
        inputText = text
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

    // MARK: Outputs
    @Published var showingAlert: Bool = false
    @Published private(set) var isButtonEnabled: Bool = false
    @Published private(set) var errorMessage: String = ""
    @Published private(set) var cautionMessage: String = ""

    // MARk: Subscribers
    // Using these subscribers just for store properties, never used out of init phase
    private var inputTextSubscriber: AnyCancellable?
    private var errorMessageSubscriber: AnyCancellable?

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }
}
