import SwiftUI

struct AddListView: View {
    private let viewModel = AddListViewModel()
    @State private var itemNumber: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(alignment: .center, spacing: 100) {
                Text("新しい伝票番号を登録する")
                    .foregroundColor(.white)
                
                TextField("    伝票番号を入力(12桁の数字)", text: $itemNumber)
                    .frame(height: 40)
                    .foregroundColor(.black)
                    .background(Color.white)
                    .padding(.horizontal, 20.0)

                Button(action: {
                    viewModel.input.buttonDidTap(text: itemNumber)
                    self.showingAlert = true
                }, label: {
                    ZStack {
                        Color.BlackCat.naturalGreen.edgesIgnoringSafeArea(.all)
                            .frame(height: 50, alignment: .center)
                        Text("登録する")
                            .foregroundColor(.black)
                    }
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                })
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("登録に失敗しました"),
                          dismissButton: .default(
                            Text("OK"),
                            action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                          )
                    )
                }
            }
        }
    }
}

struct AddListView_Previews: PreviewProvider {
    static var previews: some View {
        AddListView()
    }
}
