import Foundation
import Combine
import Domain

protocol AddListViewModelInputs {
    func textFieldDidChange(text: String)
    func buttonDidTap()
}

protocol AddListViewModelOutputs {
    var isButtonEnabled: Bool { get }
    var errorMessage: String { get }
    var cautionMessage: String { get }
    var isSuccessfullyAdded: Bool { get }
}

protocol AddListViewModelType {
    var input: AddListViewModelInputs { get }
    var output: AddListViewModelOutputs { get }
}

final class AddListViewModel: ObservableObject, AddListViewModelType, AddListViewModelInputs, AddListViewModelOutputs {

    init() {
        $inputTextPublisher
            .filter { Int($0) != nil }
            .map { $0.count == 12 }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &cancellables)

        $inputTextPublisher
            .compactMap { text in
                guard !text.isEmpty else { return "" }
                guard Int(text) != nil else { return "数字以外の文字が含まれています" }
                return text.count == 12 ? "" : "伝票番号は12文字です"
            }
            .assign(to: \.cautionMessage, on: self)
            .store(in: &cancellables)

        $buttonTappedPublisher
            .combineLatest($inputTextPublisher) { $1 }
            .compactMap { Int($0) }
            .map { itemNumber in
                return true
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
            .assign(to: \.isSuccessfullyAdded, on: self)
            .store(in: &cancellables)
    }

    private var cancellables: Set<AnyCancellable> = []

    // MARK: Inputs
    @Published private var inputTextPublisher: String = ""
    func textFieldDidChange(text: String) {
        inputTextPublisher = text
    }

    @Published private var buttonTappedPublisher: Void = ()
    func buttonDidTap() {
        buttonTappedPublisher = ()
    }

    // MARK: Outputs
    @Published var showingAlert: Bool = false
    @Published private(set) var isButtonEnabled: Bool = false
    @Published private(set) var errorMessage: String = ""
    @Published private(set) var cautionMessage: String = ""
    @Published private(set) var isSuccessfullyAdded: Bool = false

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }
}
