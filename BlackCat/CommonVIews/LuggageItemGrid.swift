import SwiftUI

struct LuggageItemGrid: View {
    private let deliveryItem: DeliveryItem
    private var deliveryStatus: DeliveryStatus {
        return deliveryItem.statusList.last!
    }

    init(deliveryItem: DeliveryItem) {
        self.deliveryItem = deliveryItem
    }

    var body: some View {
        ZStack {
            deliveryStatus.deliveryStatus?.color
                .edgesIgnoringSafeArea(.all)

            VStack {
                ZStack {
                    DonutsView(deliveryStatusType: deliveryStatus.deliveryStatus ?? .sended)
                        .frame(width: 130, height: 130)

                    VStack {
                        Text(deliveryStatus.status)
                            .foregroundColor(.white)
                        Text(deliveryStatus.shopName)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        HStack {
                            Text(deliveryStatus.date)
                                .foregroundColor(.white)
                            Text(deliveryStatus.time)
                                .foregroundColor(.white)
                        }
                    }.frame(width: 120, height: 120)
                }
                Text(String(deliveryItem.deliveryID))
                    .foregroundColor(.white)
            }
        }
    }
}

struct LuggageItemGrid_Previews: PreviewProvider {
    static var previews: some View {
        let mock = TnekoMock.tnekoClient.deliveryList[2]
        LuggageItemGrid(deliveryItem: mock)
    }
}
