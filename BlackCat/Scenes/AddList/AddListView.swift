import SwiftUI

struct AddListView: View {
    private let viewModel = AddListViewModel()
    @State private var itemNumber: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(alignment: .center, spacing: 100) {
                TextField("伝票番号を入力(12桁の数字)", text: $itemNumber)
                    .padding(.horizontal, 20.0)
                    .foregroundColor(.white)
                Button(action: {
                    viewModel.input.buttonDidTap(text: itemNumber)
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("登録する")
                })
            }
        }
    }
}

struct AddListView_Previews: PreviewProvider {
    static var previews: some View {
        AddListView()
    }
}
