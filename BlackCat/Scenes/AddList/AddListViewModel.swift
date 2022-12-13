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
            .withLatestFrom($inputTextPublisher) { $1 }
            .compactMap { Int($0) }
            .flatMap { itemNumber in
                return apiClient.tneko(.init(numbers: [itemNumber]))
                    .subscribe(on: DispatchQueue.global())
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in
                self.errorMessage = "登録に失敗しました"
            }, receiveValue: { value in
                self.errorMessage = value.deriveryList[0].statusList.count != 0 ? "登録に成功しました" : "登録に失敗しました"
                self.showingAlert = true
                value.deriveryList.filter { $0.statusList.count != 0 }.forEach {
                    LocalDeliveryItems.shared.add($0.deliveryID)
                }
            })
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
