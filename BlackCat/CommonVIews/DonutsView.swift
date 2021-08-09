import SwiftUI

struct DonutsView: View {

    private let deliveryStatusType: DeliveryStatusType
    private var trimValue: CGFloat {
        switch deliveryStatusType {
        case .received:
            return 0.25
        case .sended:
            return 0.5
        case .delivering:
            return 0.75
        case .delivered:
            return 1
        }
    }

    init(deliveryStatusType: DeliveryStatusType) {
        self.deliveryStatusType = deliveryStatusType
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.BlackCat.shadowLevel3, lineWidth: 10)
            Circle()
                .trim(from: 0.0, to: trimValue)
                .rotation(Angle(degrees: 270.0))
                .stroke(
                    Color.BlackCat.naturalGreen,
                    style: .init(
                        lineWidth: 10,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        }
    }
}

struct DonutsView_Previews: PreviewProvider {
    static var previews: some View {
        DonutsView(deliveryStatusType: .delivering)
    }
}
