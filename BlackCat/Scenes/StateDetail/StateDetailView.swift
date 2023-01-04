import SwiftUI

struct StateDetailView: View {

    @StateObject private var viewModel: StateDetailViewModel
    @Environment(\.presentationMode) var presentation

    init(deliveryDetail: DeliveryItem) {
        _viewModel = StateObject(wrappedValue: StateDetailViewModel(deliveryItem: deliveryDetail))
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            List() {
                ForEach(viewModel.deliveryItem.statusList) {
                    StateDetailListView(deliveryStatus: $0)
                }
            }

            VStack {
                Spacer()

                VStack {
                    Button(action: {
                        viewModel.deleteDeliveryItem()
                    }, label: {
                        ZStack {
                            Color.blue.edgesIgnoringSafeArea(.all)
                                .frame(height: 50, alignment: .center)

                            Text("Widgetに追加")
                                .foregroundColor(.white)
                        }
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 20)
                    })
                    .alert(isPresented: $viewModel.showsWidgetAlert) {
                        Alert(title: Text("Widgetに登録しました"),
                              dismissButton: .default(
                                Text("OK"),
                                action: {
                                    self.presentation.wrappedValue.dismiss()
                                }
                              )
                        )
                    }

                    Button(action: {
                        viewModel.deleteDeliveryItem()
                    }) {
                        ZStack {
                            Color.BlackCat.naturalRed.edgesIgnoringSafeArea(.all)
                                .frame(height: 50, alignment: .center)

                            Text("削除する")
                                .foregroundColor(.white)
                        }
                        .cornerRadius(10)
                        .padding(.bottom, 30)
                        .padding(.horizontal, 20)
                    }
                    .alert(isPresented: $viewModel.showsDeletionAlert) {
                        Alert(title: Text("削除しました"),
                              dismissButton: .default(
                                Text("OK"),
                                action: {
                                    self.presentation.wrappedValue.dismiss()
                                }
                              )
                        )
                    }
                }
            }
        }
        .navigationTitle(String(viewModel.deliveryItem.deliveryID))
    }
}

struct StateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let deliveryIteMock = TnekoMock.tnekoClient.deliveryList[0]
        StateDetailView(deliveryDetail: deliveryIteMock)
    }
}
