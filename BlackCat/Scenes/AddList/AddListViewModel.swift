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
        inputTextStream = inputText
            .filter { Int($0) != nil }
            .map { $0.count == 12 }
            .assign(to: \.isButtonEnabled, on: self)

        errorMessageStream = inputText
            .compactMap { text in
                guard !text.isEmpty else { return "" }
                guard Int(text) != nil else { return "数字以外の文字が含まれています" }
                return text.count == 12 ? "" : "伝票番号は12文字です"
            }
            .assign(to: \.cautionMessage, on: self)
    }

    // MARK: Outputs
    @Published var showingAlert: Bool = false
    @Published private(set) var isButtonEnabled: Bool = false
    @Published private(set)var errorMessage: String = ""
    @Published private(set)var cautionMessage: String = ""

    private var inputTextStream: AnyCancellable?
    private var errorMessageStream: AnyCancellable?
    private var inputText: CurrentValueSubject<String, Never> = CurrentValueSubject<String, Never>("")
    func textFieldDidChange(text: String) {
        inputText.send(text)
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
