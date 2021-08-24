import Foundation

protocol AddListViewModelInputs {
    func buttonDidTap(text: String)
}

protocol AddListViewModelOutputs {

}

protocol AddListViewModelType {
    var input: AddListViewModelInputs { get }
    var output: AddListViewModelOutputs { get }
}

final class AddListViewModel: AddListViewModelType, AddListViewModelInputs, AddListViewModelOutputs {
    init() {}

    func buttonDidTap(text: String) {
        guard let itemNumber = Int(text),
              !text.isEmpty else { return }
        LocalDeliveryItems.shared.add(itemNumber)
    }

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }
}
