import SwiftUI

struct StateDetailView: View {
    private let deliveyDetail: DeliveryItem

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
                    print("hoge")
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
