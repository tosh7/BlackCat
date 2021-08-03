import SwiftUI

struct LuggageItemGrid: View {
    let deliveryStatus: DeliveryStatus

    init(deliveryStatus: DeliveryStatus) {
        self.deliveryStatus = deliveryStatus
    }

    var body: some View {
        ZStack {
            deliveryStatus.deliveryStatus?.color
                .edgesIgnoringSafeArea(.all)

            DonutsView(deliveryStatusType: deliveryStatus.deliveryStatus ?? .sended)

            VStack {
                Text(deliveryStatus.status)
                    .foregroundColor(.white)
                Text(deliveryStatus.shopName)
                    .foregroundColor(.white)
                HStack {
                    Text(deliveryStatus.date)
                        .foregroundColor(.white)
                    Text(deliveryStatus.time)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct LuggageItemGrid_Previews: PreviewProvider {
    static var previews: some View {
        LuggageItemGrid(deliveryStatus: DeliveryStatus(status: "輸送中",
                                              date: "6/13",
                                              time: "12:41",
                                              shopName: "羽田クロノゲートベース",
                                              shopID: "032990"))
    }
}
