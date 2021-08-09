import SwiftUI

struct StateDetailView: View {
    private let deliveyDetail: DeliveryItem

    init(deliveryDetail: DeliveryItem) {
        self.deliveyDetail = deliveryDetail
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                List() {
                    ForEach(deliveyDetail.statusList) {
                        Text($0.status)
                    }
                }
            }
        }
        .navigationTitle(String(deliveyDetail.deliveryID))
    }
}

struct StateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        StateDetailView(
            deliveryDetail: .init(
                deliveryID: 123456123456,
                statusList: [
                    .init(status: "荷物受付", date: "07/17", time: "16:39", shopName: "船橋法人営業支店", shopID: "035600"),
                    .init(status: "発送済み", date: "07/17", time: "16:39", shopName: "船橋法人営業支店", shopID: "035600"),
                    .init(status: "輸送中", date: "07/17", time: "23:17", shopName: "羽田クロノゲートベース", shopID: "032990"),
                    .init(status: "配達完了", date: "07/18", time: "12:06", shopName: "上原センター", shopID: "132255")
                ]
            )
        )
    }
}
