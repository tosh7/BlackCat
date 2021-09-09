import Foundation
import Domain

protocol AddListViewModelInputs {
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

    @Published var showingAlert: Bool
    var errorMessage: String = ""

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }

    func buttonDidTap(text: String) {
        guard let itemNumber = Int(text),
              !text.isEmpty && text.count == 12 else {
            errorMessage = "入力形式が違います"
            showingAlert = true
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
                    NotificationCenter.default.post(name: .addItem, object: nil)
                }
            case .failure:
                self.errorMessage = "登録に失敗しました"
            }
            DispatchQueue.main.async {
                self.showingAlert = true
            }
        })
    }
}
