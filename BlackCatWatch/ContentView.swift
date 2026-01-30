import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WatchDeliveryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.deliveries.isEmpty {
                    EmptyStateView(isPhoneReachable: viewModel.isPhoneReachable)
                } else {
                    DeliveryListView(
                        deliveries: viewModel.deliveries,
                        lastSyncDate: viewModel.formattedLastSyncDate
                    )
                }
            }
            .navigationTitle("配達状況")
        }
        .onAppear {
            viewModel.loadDeliveries()
        }
        .refreshable {
            viewModel.refreshStatus()
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)

            Text("読み込み中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let isPhoneReachable: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("追跡中の荷物がありません")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("iPhoneアプリで\n荷物を追加してください")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !isPhoneReachable {
                HStack(spacing: 4) {
                    Image(systemName: "iphone.slash")
                        .font(.caption2)
                    Text("iPhoneに接続できません")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Delivery List View

struct DeliveryListView: View {
    let deliveries: [WatchDeliveryData]
    let lastSyncDate: String

    var body: some View {
        List {
            // 同期情報
            Section {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("最終同期: \(lastSyncDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // 配達リスト
            ForEach(deliveries) { item in
                NavigationLink(destination: DeliveryDetailView(delivery: item)) {
                    DeliveryRowView(delivery: item)
                }
            }
        }
        .listStyle(.carousel)
    }
}

// MARK: - Delivery Row View

struct DeliveryRowView: View {
    let delivery: WatchDeliveryData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(delivery.statusColor)
                    .frame(width: 8, height: 8)

                Text(delivery.latestStatus)
                    .font(.headline)
                    .lineLimit(1)
            }

            Text(delivery.carrierName)
                .font(.caption2)
                .foregroundColor(.secondary)

            if !delivery.latestDate.isEmpty {
                HStack(spacing: 4) {
                    Text(delivery.latestDate)
                    if let time = delivery.latestTime {
                        Text(time)
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Delivery Detail View

struct DeliveryDetailView: View {
    let delivery: WatchDeliveryData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Status Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(delivery.statusColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Circle()
                            .fill(delivery.statusColor)
                            .frame(width: 28, height: 28)

                        Image(systemName: delivery.statusIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text(delivery.latestStatus)
                        .font(.headline)
                }

                Divider()

                // Carrier Info
                Label(delivery.carrierName, systemImage: delivery.carrierIcon)
                    .font(.caption)

                // Tracking Number
                VStack(alignment: .leading, spacing: 2) {
                    Text("伝票番号")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(delivery.deliveryID)
                        .font(.caption)
                        .fontDesign(.monospaced)
                }

                // Date Info
                if !delivery.latestDate.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("最終更新")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(delivery.latestDate)
                            if let time = delivery.latestTime {
                                Text(time)
                            }
                        }
                        .font(.caption)
                    }
                }

                // Location
                if !delivery.latestLocation.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("場所")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(delivery.latestLocation)
                            .font(.caption)
                    }
                }

                // Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("進捗")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(delivery.progressPercentage)%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(delivery.statusColor)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(delivery.statusColor)
                                .frame(width: geometry.size.width * CGFloat(delivery.progressPercentage) / 100, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("詳細")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
