import SwiftUI

struct StateDetailView: View {
    @ObservedObject private var viewModel = StateDetailViewModel()
    private let deliveyDetail: DeliveryItem
    @Environment(\.presentationMode) var presentation

    init(deliveryDetail: DeliveryItem) {
        self.deliveyDetail = deliveryDetail
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            List() {
                ForEach(deliveyDetail.statusList) {
                    StateDetailListView(deliveryStatus: $0)
                }
            }

            VStack {
                Spacer()

                Button(action: {
                    // Remove an Item from userdefaults
                    viewModel.deleteDeliveryItem(id: deliveyDetail.deliveryID)
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
                .alert(isPresented: $viewModel.showingAlert) {
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
        .navigationTitle(String(deliveyDetail.deliveryID))
    }
}

struct StateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let deliveryIteMock = TnekoMock.tnekoClient.deliveryList[0]
        StateDetailView(deliveryDetail: deliveryIteMock)
    }
}
