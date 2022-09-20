import SwiftUI

struct StateDetailListView: View {
    private let deliveryStatus: DeliveryStatus

    init(deliveryStatus: DeliveryStatus) {
        self.deliveryStatus = deliveryStatus
    }

    var body: some View {
        VStack {
            HStack {
                Text(deliveryStatus.status)
                HStack {
                    Text(deliveryStatus.date)
                    Text(deliveryStatus.time)
                }
                Spacer()
            }
            HStack {
                Text(deliveryStatus.shopName)
                Spacer()
            }
        }
    }
}

struct StateDetailListView_Previews: PreviewProvider {
    static var previews: some View {
        let deliveryStatusMock = TnekoMock.tnekoClient.deliveryList[0].statusList[0]
        StateDetailListView(deliveryStatus: deliveryStatusMock)
    }
}
