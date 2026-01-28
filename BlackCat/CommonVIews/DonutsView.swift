import SwiftUI

struct DonutsView: View {

    // MARK: - Environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let deliveryStatusType: DeliveryStatusType
    private var trimValue: CGFloat {
        switch deliveryStatusType {
        case .received:
            return 0.2
        case .sended:
            return 0.4
        case .shipping:
            return 0.6
        case .delivering:
            return 0.8
        case .delivered:
            return 1

        }
    }

    /// アクセシビリティ用の進捗パーセンテージ
    private var progressPercentage: Int {
        Int(trimValue * 100)
    }

    /// アクセシビリティ用のステータス説明
    private var statusDescription: String {
        switch deliveryStatusType {
        case .received:
            return "荷物受付済み"
        case .sended:
            return "発送済み"
        case .shipping:
            return "輸送中"
        case .delivering:
            return "配達中"
        case .delivered:
            return "配達完了"
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
        // MARK: - Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("配送進捗")
        .accessibilityValue("\(statusDescription)、\(progressPercentage)パーセント完了")
        .accessibilityHint("配送の進捗状況を示す円形グラフです")
    }
}

struct DonutsView_Previews: PreviewProvider {
    static var previews: some View {
        DonutsView(deliveryStatusType: .delivering)
    }
}
