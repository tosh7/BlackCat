import SwiftUI
import UIKit

struct LuggageItemGrid: View {
    private let deliveryItem: DeliveryItem
    private var deliveryStatus: DeliveryStatus {
        return deliveryItem.statusList.last!
    }
    @State private var isPressed = false
    @State private var isAnimating = false
    @State private var showShareSheet = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(deliveryItem: DeliveryItem) {
        self.deliveryItem = deliveryItem
    }

    /// Share content helper
    private var shareContent: DeliveryShareContent {
        DeliveryShareContent(deliveryItem: deliveryItem)
    }

    /// アクセシビリティ用のステータス説明
    private var accessibilityStatusDescription: String {
        let timeInfo = deliveryStatus.time.map { " \($0)" } ?? ""
        return "\(deliveryStatus.status)、\(deliveryStatus.shopName)、\(deliveryStatus.date)\(timeInfo)"
    }

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            statusColor.opacity(0.9),
                            statusColor.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .offset(x: 50, y: -40)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 60, height: 60)
                .offset(x: -40, y: 60)

            VStack(spacing: 8) {
                // Status icon with animation
                ZStack {
                    // Pulse effect for active deliveries
                    if shouldPulse && !reduceMotion {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .scaleEffect(isAnimating ? 1.3 : 1.0)
                            .opacity(isAnimating ? 0 : 0.5)
                    }

                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: statusIcon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                // Status text
                Text(deliveryStatus.status)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 4)

                // Shop name
                Text(deliveryStatus.shopName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 4)

                // Date and time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))

                    Text(deliveryStatus.date)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))

                    if let time = deliveryStatus.time {
                        Text(time)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer().frame(height: 4)

                // Delivery ID badge
                Text(String(deliveryItem.deliveryID))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .fontDesign(.monospaced)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                    )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .scaleEffect(isPressed && !reduceMotion ? 0.95 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            guard shouldPulse && !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
        // MARK: - Context Menu
        .contextMenu {
            // Share option
            Button(action: {
                HapticManager.shared.lightImpact()
                showShareSheet = true
            }) {
                Label("共有", systemImage: "square.and.arrow.up")
            }

            // Copy tracking number
            Button(action: {
                HapticManager.shared.lightImpact()
                UIPasteboard.general.string = String(deliveryItem.deliveryID)
            }) {
                Label("伝票番号をコピー", systemImage: "doc.on.doc")
            }

            // Open tracking URL
            if let trackingURL = shareContent.trackingURL {
                Button(action: {
                    HapticManager.shared.lightImpact()
                    UIApplication.shared.open(trackingURL)
                }) {
                    Label("追跡サイトを開く", systemImage: "safari")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareContent.shortShareText])
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("荷物 \(deliveryItem.deliveryID)")
        .accessibilityValue(accessibilityStatusDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "共有") {
            showShareSheet = true
        }
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
            return "shippingbox.fill"
        }
    }

    private var shouldPulse: Bool {
        switch deliveryStatus.deliveryStatus {
        case .shipping, .delivering:
            return true
        default:
            return false
        }
    }
}

struct LuggageItemGrid_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.BlackCat.backgroundPrimary.ignoresSafeArea()

            HStack(spacing: 16) {
                let mock = TnekoMock.tnekoClient.deliveryList[2]
                LuggageItemGrid(deliveryItem: mock)
                    .frame(width: 150, height: 180)
                    .cornerRadius(20)

                LuggageItemGrid(deliveryItem: mock)
                    .frame(width: 150, height: 180)
                    .cornerRadius(20)
            }
        }
        .preferredColorScheme(.dark)
    }
}
