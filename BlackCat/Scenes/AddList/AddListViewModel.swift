import Foundation
import SwiftUI

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

    func buttonDidTap(text: String) {

        guard let itemNumber = Int(text),
              !text.isEmpty else {
            self.showingAlert = true
            return
        }
        LocalDeliveryItems.shared.add(itemNumber)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.showingAlert = true
        })
    }

    @Published var showingAlert: Bool

    var input: AddListViewModelInputs { return self }
    var output: AddListViewModelOutputs { return self }
}
