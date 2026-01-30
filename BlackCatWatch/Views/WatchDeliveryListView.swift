import SwiftUI

// MARK: - Watch Delivery List View
/// watchOS向けの配達リスト画面
/// Digital Crownでのスクロール、プルリフレッシュに対応
struct WatchDeliveryListView: View {
    @StateObject private var viewModel = WatchDeliveryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    WatchLoadingView()
                } else if viewModel.deliveries.isEmpty {
                    WatchEmptyStateView()
                } else {
                    deliveryListContent
                }
            }
            .navigationTitle("配達状況")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.loadDeliveries()
        }
    }

    // MARK: - Delivery List Content
    private var deliveryListContent: some View {
        List {
            ForEach(viewModel.deliveries) { item in
                NavigationLink(destination: WatchDeliveryDetailView(deliveryData: item)) {
                    WatchDeliveryRowView(deliveryData: item)
                }
                .listRowBackground(Color(hex: "0x0F3460"))
            }
        }
        .listStyle(.carousel)
        .refreshable {
            viewModel.refreshStatus()
        }
    }
}

// MARK: - Watch Delivery Row View
/// 配達リストの各行を表示するView
struct WatchDeliveryRowView: View {
    let deliveryData: WatchDeliveryData

    var body: some View {
        HStack(spacing: 12) {
            // ステータスアイコン
            statusIcon

            // 情報
            VStack(alignment: .leading, spacing: 4) {
                // 伝票番号
                Text(deliveryData.deliveryID)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // ステータス
                Text(deliveryData.latestStatus)
                    .font(.caption2)
                    .foregroundColor(deliveryData.statusColor)
                    .lineLimit(1)

                // 配送業者
                Text(deliveryData.carrierName)
                    .font(.caption2)
                    .foregroundColor(Color(hex: "0xa0a0a0"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("詳細を表示するにはダブルタップ")
    }

    // MARK: - Status Icon
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(deliveryData.statusColor.opacity(0.2))
                .frame(width: 36, height: 36)

            Circle()
                .fill(deliveryData.statusColor)
                .frame(width: 28, height: 28)

            Image(systemName: deliveryData.statusIcon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Computed Properties
    private var accessibilityLabel: String {
        let trackingNumber = "伝票番号 \(deliveryData.deliveryID)"
        let carrier = deliveryData.carrierName
        let status = deliveryData.latestStatus
        return "\(trackingNumber)、\(carrier)、\(status)"
    }
}

// MARK: - Watch Loading View
/// watchOS向けの読み込み中表示
struct WatchLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0xFF9F43")))
                .scaleEffect(1.5)

            Text("読み込み中...")
                .font(.caption)
                .foregroundColor(Color(hex: "0xa0a0a0"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0x1A1A2E"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("読み込み中")
    }
}

// MARK: - Watch Empty State View
/// watchOS向けの空状態表示
struct WatchEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "0x808080"))
                .accessibilityHidden(true)

            Text("荷物がありません")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("iPhoneアプリで\n追加してください")
                .font(.caption2)
                .foregroundColor(Color(hex: "0xa0a0a0"))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0x1A1A2E"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("荷物がありません。iPhoneアプリで追加してください")
    }
}

// MARK: - Color Extension for Watch
extension Color {
    init(hex: String) {
        var color: UInt64 = 0
        var r: Double = 0, g: Double = 0, b: Double = 0
        if Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&color) {
            r = Double((color & 0xFF0000) >> 16) / 255.0
            g = Double((color & 0x00FF00) >>  8) / 255.0
            b = Double( color & 0x0000FF       ) / 255.0
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview
#if DEBUG
struct WatchDeliveryListView_Previews: PreviewProvider {
    static var previews: some View {
        WatchDeliveryListView()
            .previewDevice("Apple Watch Series 9 - 45mm")
    }
}
#endif
