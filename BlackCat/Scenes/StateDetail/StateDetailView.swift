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

            Button(action: {
                // Remove Item from userdefaults
            }) {
                Text("削除する")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.BlackCat.naturalRed)
                    .cornerRadius(10)
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
