import SwiftUI

struct StateDetailView: View {
    @StateObject private var viewModel = StateDetailViewModel()
    private let deliveryDetail: DeliveryItem
    @Environment(\.presentationMode) var presentation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showDeleteConfirmation = false
    @State private var headerScale: CGFloat = 1.0
    @State private var showShareSheet = false

    init(deliveryDetail: DeliveryItem) {
        self.deliveryDetail = deliveryDetail
    }

    var body: some View {
        ZStack {
            Color.BlackCat.backgroundPrimary.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 0) {
                    // Header card with current status
                    statusHeaderCard
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // Timeline section header
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.headline)
                            .foregroundColor(Color.BlackCat.primaryOrange)
                            .accessibilityHidden(true)

                        Text("配送履歴")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)

                        Spacer()

                        Text("\(deliveryDetail.statusList.count)件")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.BlackCat.shadowLevel6)
                            )
                            .accessibilityLabel("配送履歴 \(deliveryDetail.statusList.count)件")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Timeline list
                    VStack(spacing: 0) {
                        ForEach(Array(deliveryDetail.statusList.reversed().enumerated()), id: \.element.id) { index, status in
                            StateDetailListView(
                                deliveryStatus: status,
                                isFirst: index == 0,
                                isLast: index == deliveryDetail.statusList.count - 1
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("配送履歴一覧")

                    // Spacer for delete button
                    Spacer(minLength: 120)
                }
            }

            // Floating delete button
            VStack {
                Spacer()

                deleteButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .navigationTitle(String(deliveryDetail.deliveryID))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButton
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareContent.shareText])
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text("削除しました"),
                message: Text("荷物の追跡情報を削除しました"),
                dismissButton: .default(
                    Text("OK"),
                    action: {
                        self.presentation.wrappedValue.dismiss()
                    }
                )
            )
        }
        .confirmationDialog(
            "この荷物を削除しますか?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                if reduceMotion {
                    viewModel.deleteDeliveryItem(id: deliveryDetail.deliveryID)
                } else {
                    withAnimation(.spring()) {
                        viewModel.deleteDeliveryItem(id: deliveryDetail.deliveryID)
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .confetti(isShowing: $viewModel.showConfetti)
        .onAppear {
            // Check if confetti should be shown for delivered items
            let isDelivered = currentStatus?.deliveryStatus == .delivered
            viewModel.checkAndShowConfetti(for: deliveryDetail.deliveryID, isDelivered: isDelivered)
        }
    }

    // MARK: - Status Header Card
    private var statusHeaderCard: some View {
        VStack(spacing: 16) {
            // Current status with large icon
            HStack(spacing: 16) {
                // Status icon circle
                ZStack {
                    Circle()
                        .fill(currentStatusColor.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Circle()
                        .fill(currentStatusColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: currentStatusColor.opacity(0.5), radius: 10, x: 0, y: 4)

                    Image(systemName: currentStatusIcon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentStatus?.status ?? "不明")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .accessibilityAddTraits(.isHeader)

                    if let status = currentStatus {
                        HStack(spacing: 4) {
                            Text(status.date)
                            if let time = status.time {
                                Text(time)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.BlackCat.shadowLevel2)
                    }
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("現在の状態: \(currentStatus?.status ?? "不明")")
            .accessibilityValue(currentStatus.map { "\($0.date) \($0.time ?? "")" } ?? "")

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("配達進捗")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                    Spacer()
                    Text("\(progressPercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(currentStatusColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.BlackCat.shadowLevel6)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.BlackCat.primaryBlue,
                                        currentStatusColor
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(progressPercentage) / 100, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("配達進捗")
            .accessibilityValue("\(progressPercentage)パーセント完了")

            // Delivery ID
            HStack {
                Image(systemName: "barcode")
                    .font(.caption)
                    .foregroundColor(Color.BlackCat.shadowLevel4)
                    .accessibilityHidden(true)

                Text("伝票番号: \(deliveryDetail.deliveryID)")
                    .font(.caption)
                    .foregroundColor(Color.BlackCat.shadowLevel3)
                    .textSelection(.enabled)

                Spacer()

                Button(action: {
                    HapticManager.shared.lightImpact()
                    UIPasteboard.general.string = String(deliveryDetail.deliveryID)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(Color.BlackCat.primaryBlue)
                }
                .accessibilityLabel("伝票番号をコピー")
                .accessibilityHint("伝票番号をクリップボードにコピーします")
                .frame(minWidth: 44, minHeight: 44) // 最小タップ領域を確保
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.BlackCat.backgroundCard)
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(currentStatusColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Share Button
    private var shareButton: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            showShareSheet = true
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.body)
                .foregroundColor(Color.BlackCat.primaryBlue)
        }
        .accessibilityLabel("配送情報を共有")
        .accessibilityHint("配送情報をメッセージやSNSで共有します")
    }

    // MARK: - Share Content
    private var shareContent: DeliveryShareContent {
        DeliveryShareContent(deliveryItem: deliveryDetail)
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(action: {
            HapticManager.shared.deleteConfirmation()
            showDeleteConfirmation = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.body)
                Text("この荷物を削除")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50) // 最小タップ領域を確保
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.BlackCat.naturalRed,
                        Color.BlackCat.naturalRed.opacity(0.8)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.BlackCat.naturalRed.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .accessibilityLabel("この荷物を削除")
        .accessibilityHint("荷物の追跡情報を削除する確認ダイアログを表示します")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Helpers
    private var currentStatus: DeliveryStatus? {
        deliveryDetail.statusList.last
    }

    private var currentStatusColor: Color {
        currentStatus?.deliveryStatus?.color ?? Color.BlackCat.shadowLevel4
    }

    private var currentStatusIcon: String {
        switch currentStatus?.deliveryStatus {
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

    private var progressPercentage: Int {
        switch currentStatus?.deliveryStatus {
        case .received:
            return 20
        case .sended:
            return 40
        case .shipping:
            return 60
        case .delivering:
            return 80
        case .delivered:
            return 100
        case .none:
            return 0
        }
    }
}

struct StateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let deliveryItemMock = TnekoMock.tnekoClient.deliveryList[0]
            StateDetailView(deliveryDetail: deliveryItemMock)
        }
        .preferredColorScheme(.dark)
    }
}
