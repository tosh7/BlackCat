import SwiftUI

struct StateDetailListView: View {
    private let deliveryStatus: DeliveryStatus
    private let isFirst: Bool
    private let isLast: Bool
    @State private var isAnimated = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(deliveryStatus: DeliveryStatus, isFirst: Bool = false, isLast: Bool = false) {
        self.deliveryStatus = deliveryStatus
        self.isFirst = isFirst
        self.isLast = isLast
    }

    /// アクセシビリティ用の配送状況説明
    private var accessibilityDescription: String {
        let timeInfo = deliveryStatus.time.map { " \($0)" } ?? ""
        let latestBadge = isLast ? "最新の状態、" : ""
        return "\(latestBadge)\(deliveryStatus.status)、\(deliveryStatus.date)\(timeInfo)、\(deliveryStatus.shopName)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            timelineIndicator

            // Content card
            contentCard
        }
        .padding(.vertical, 4)
        .onAppear {
            if reduceMotion {
                isAnimated = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    isAnimated = true
                }
            }
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isLast ? [.isHeader, .isSelected] : [])
    }

    // MARK: - Timeline Indicator
    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            // Top line (hidden for first item)
            Rectangle()
                .fill(isFirst ? Color.clear : Color.BlackCat.shadowLevel5)
                .frame(width: 2, height: 20)

            // Status circle with icon
            ZStack {
                // Outer glow for current status
                if isLast && !reduceMotion {
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .scaleEffect(isAnimated ? 1.2 : 1.0)
                        .opacity(isAnimated ? 0.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: isAnimated
                        )
                }

                // Main circle
                Circle()
                    .fill(statusColor)
                    .frame(width: 32, height: 32)
                    .shadow(color: statusColor.opacity(0.5), radius: isLast ? 8 : 4, x: 0, y: 2)

                // Icon
                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(reduceMotion ? 1.0 : (isAnimated ? 1.0 : 0.5))
            .opacity(reduceMotion ? 1.0 : (isAnimated ? 1.0 : 0))

            // Bottom line (hidden for last item)
            Rectangle()
                .fill(isLast ? Color.clear : Color.BlackCat.shadowLevel5)
                .frame(width: 2)
                .frame(minHeight: 40)
        }
        .frame(width: 44)
        .accessibilityHidden(true)
    }

    // MARK: - Content Card
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status badge
            HStack {
                Text(deliveryStatus.status)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                if isLast {
                    Text("最新")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor)
                        )
                }
            }

            // Date and time
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(Color.BlackCat.shadowLevel3)

                Text(deliveryStatus.date)
                    .font(.subheadline)
                    .foregroundColor(Color.BlackCat.shadowLevel2)

                if let time = deliveryStatus.time {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.shadowLevel3)

                    Text(time)
                        .font(.subheadline)
                        .foregroundColor(Color.BlackCat.shadowLevel2)
                }
            }

            // Location
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(Color.BlackCat.primaryOrange)

                Text(deliveryStatus.shopName)
                    .font(.subheadline)
                    .foregroundColor(Color.BlackCat.shadowLevel2)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isLast ? Color.BlackCat.backgroundCard : Color.BlackCat.shadowLevel7)
                .shadow(color: Color.black.opacity(isLast ? 0.3 : 0.1), radius: isLast ? 8 : 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isLast ? statusColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .offset(x: reduceMotion ? 0 : (isAnimated ? 0 : 20))
        .opacity(reduceMotion ? 1.0 : (isAnimated ? 1.0 : 0))
        .accessibilityHidden(true)
    }

    // MARK: - Helpers
    private var statusColor: Color {
        deliveryStatus.deliveryStatus?.color ?? Color.BlackCat.shadowLevel4
    }

    private var statusIcon: String {
        switch deliveryStatus.deliveryStatus {
        case .received:
            return "arrow.down.doc.fill"
        case .sended:
            return "paperplane.fill"
        case .shipping:
            return "box.truck.fill"
        case .delivering:
            return "figure.walk"
        case .delivered:
            return "checkmark.circle.fill"
        case .none:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Timeline Container View
struct TimelineContainerView: View {
    let statusList: [DeliveryStatus]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(statusList.enumerated()), id: \.element.id) { index, status in
                StateDetailListView(
                    deliveryStatus: status,
                    isFirst: index == 0,
                    isLast: index == statusList.count - 1
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("配送履歴タイムライン")
        .accessibilityHint("\(statusList.count)件の配送状況があります")
    }
}

struct StateDetailListView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.BlackCat.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    let deliveryStatusMock = TnekoMock.tnekoClient.deliveryList[0].statusList
                    ForEach(Array(deliveryStatusMock.enumerated()), id: \.element.id) { index, status in
                        StateDetailListView(
                            deliveryStatus: status,
                            isFirst: index == 0,
                            isLast: index == deliveryStatusMock.count - 1
                        )
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
