import SwiftUI

struct AddListView: View {
    @ObservedObject var viewModel = AddListViewModel()
    @State private var itemNumber: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(alignment: .center, spacing: 100) {
                Text("新しい伝票番号を登録する")
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 20) {
                    TextField("", text: $itemNumber)
                        .onChange(of: itemNumber) {
                            viewModel.textFieldDidChange(text: $0)
                        }
                        .placeholder(when: itemNumber.isEmpty) {
                            Text("    伝票番号を入力(12桁の数字)").foregroundColor(.gray)
                        }
                        .keyboardType(.numberPad)
                        .frame(height: 40)
                        .foregroundColor(.black)
                        .background(Color.white)
                        .padding(.horizontal, 20.0)

                    Text(viewModel.cautionMessage)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20.0)
                }

                Button(action: {
                    viewModel.input.buttonDidTap(text: itemNumber)
                }, label: {
                    ZStack {
                        Color.BlackCat.naturalGreen.edgesIgnoringSafeArea(.all)
                            .frame(height: 50, alignment: .center)
                            .opacity(viewModel.isButtonEnabled ? 1.0 : 0.5)
                        Text("登録する")
                            .foregroundColor(.black)
                    }
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                })
                    .disabled(!viewModel.isButtonEnabled)
                    .alert(isPresented: $viewModel.showingAlert) {
                        Alert(title: Text(viewModel.errorMessage),
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
