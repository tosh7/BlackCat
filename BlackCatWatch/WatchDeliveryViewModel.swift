import SwiftUI
import Combine

/// Apple Watch用の配達情報ViewModel
/// WatchConnectivityManagerと統合してiOSアプリからデータを同期
@MainActor
final class WatchDeliveryViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 配達データ（WatchDeliveryDataを使用）
    @Published var deliveries: [WatchDeliveryData] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let connectivityManager = WatchConnectivityManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// アクティブな配達（配達完了以外）
    var activeDeliveries: [WatchDeliveryData] {
        deliveries.filter { !$0.isDelivered }
    }

    /// 配達完了した配達
    var completedDeliveries: [WatchDeliveryData] {
        deliveries.filter { $0.isDelivered }
    }

    /// アクティブな配達数
    var activeDeliveryCount: Int {
        activeDeliveries.count
    }

    /// 最終同期日時（フォーマット済み）
    var formattedLastSyncDate: String {
        connectivityManager.formattedLastSyncDate
    }

    /// iPhoneがリーチャブルか
    var isPhoneReachable: Bool {
        connectivityManager.isPhoneReachable
    }

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    // MARK: - Setup

    /// WatchConnectivityManagerとのバインディングを設定
    private func setupBindings() {
        // 配達データの購読
        connectivityManager.$deliveries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deliveries in
                self?.deliveries = deliveries
            }
            .store(in: &cancellables)

        // 同期状態の購読
        connectivityManager.$syncState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .idle, .success:
                    self?.isLoading = false
                    self?.errorMessage = nil
                case .syncing:
                    self?.isLoading = true
                    self?.errorMessage = nil
                case .error(let message):
                    self?.isLoading = false
                    self?.errorMessage = message
                }
            }
            .store(in: &cancellables)

        // エラーメッセージの購読
        connectivityManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorMessage = message
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// 配達データをiPhoneからリクエスト
    func loadDeliveries() {
        connectivityManager.requestAllDeliveries()
    }

    /// ステータス更新をリクエスト
    func refreshStatus() {
        connectivityManager.requestStatusRefresh()
    }

    /// キャッシュをクリア
    func clearCache() {
        connectivityManager.clearCache()
    }
}

// MARK: - WatchDeliveryData Extension for UI

extension WatchDeliveryData {
    /// ステータスに応じた色
    var statusColor: Color {
        switch latestStatusType {
        case "delivered":
            return .green
        case "delivering":
            return .red
        case "shipping":
            return .orange
        case "sended":
            return .pink
        case "received":
            return .blue
        default:
            return .gray
        }
    }

    /// ステータスに応じたアイコン
    var statusIcon: String {
        switch latestStatusType {
        case "delivered":
            return "checkmark.circle.fill"
        case "delivering":
            return "figure.walk"
        case "shipping":
            return "box.truck.fill"
        case "sended":
            return "paperplane.fill"
        case "received":
            return "arrow.down.doc.fill"
        default:
            return "questionmark.circle.fill"
        }
    }

    /// 進捗パーセンテージ
    var progressPercentage: Int {
        switch latestStatusType {
        case "received":
            return 20
        case "sended":
            return 40
        case "shipping":
            return 60
        case "delivering":
            return 80
        case "delivered":
            return 100
        default:
            return 0
        }
    }
}
