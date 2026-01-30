import SwiftUI

// MARK: - Watch Delivery Detail View
/// watchOS向けの配達詳細画面
/// タイムライン形式でステータス履歴を表示
struct WatchDeliveryDetailView: View {
    let deliveryData: WatchDeliveryData

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ヘッダーカード
                headerCard
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "0x1A1A2E"))
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 12) {
            // ステータスアイコンと状態
            HStack(spacing: 10) {
                statusIconView

                VStack(alignment: .leading, spacing: 2) {
                    Text(deliveryData.latestStatus)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("\(deliveryData.latestDate) \(deliveryData.latestTime ?? "")")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "0xc0c0c0"))
                }

                Spacer()
            }

            Divider()
                .background(Color(hex: "0x606060"))

            // 配送業者と伝票番号
            VStack(spacing: 8) {
                // 配送業者
                HStack {
                    Image(systemName: deliveryData.carrierIcon)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "0x4A90D9"))

                    Text(deliveryData.carrierName)
                        .font(.caption)
                        .foregroundColor(Color(hex: "0xc0c0c0"))

                    Spacer()
                }

                // 伝票番号
                HStack {
                    Image(systemName: "barcode")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "0x808080"))

                    Text(String(deliveryData.deliveryID))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(hex: "0xc0c0c0"))

                    Spacer()
                }

                // 場所
                if !deliveryData.latestLocation.isEmpty {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "0x808080"))

                        Text(deliveryData.latestLocation)
                            .font(.caption)
                            .foregroundColor(Color(hex: "0xc0c0c0"))

                        Spacer()
                    }
                }
            }

            // 進捗バー
            progressBar
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "0x0F3460"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(deliveryData.statusColor.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    // MARK: - Status Icon View
    private var statusIconView: some View {
        ZStack {
            Circle()
                .fill(deliveryData.statusColor.opacity(0.2))
                .frame(width: 44, height: 44)

            Circle()
                .fill(deliveryData.statusColor)
                .frame(width: 36, height: 36)

            Image(systemName: deliveryData.statusIcon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("進捗")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "0x808080"))

                Spacer()

                Text("\(deliveryData.progressPercentage)%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(deliveryData.statusColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "0x404040"))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(deliveryData.statusColor)
                        .frame(width: geometry.size.width * CGFloat(deliveryData.progressPercentage) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("進捗 \(deliveryData.progressPercentage)パーセント")
    }

    // MARK: - Computed Properties
    private var headerAccessibilityLabel: String {
        let status = deliveryData.latestStatus
        let carrier = deliveryData.carrierName
        let trackingNumber = "伝票番号 \(deliveryData.deliveryID)"
        let progress = "進捗 \(deliveryData.progressPercentage)パーセント"
        return "\(status)、\(carrier)、\(trackingNumber)、\(progress)"
    }
}

// MARK: - Preview
#if DEBUG
struct WatchDeliveryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WatchDeliveryDetailView(
                deliveryData: WatchDeliveryData(
                    id: "preview-123",
                    deliveryID: 123456789012,
                    carrierName: "ヤマト運輸",
                    carrierIcon: "shippingbox.fill",
                    latestStatus: "配達中",
                    latestStatusType: "delivering",
                    latestDate: "01/29",
                    latestTime: "14:30",
                    latestLocation: "配送センター",
                    registeredDate: Date(),
                    isDelivered: false
                )
            )
        }
        .previewDevice("Apple Watch Series 9 - 45mm")
    }
}
#endif
