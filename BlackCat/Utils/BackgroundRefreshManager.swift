import Foundation
import BackgroundTasks
import UIKit
import Combine
import Domain

/// バックグラウンド更新間隔の設定
enum BackgroundRefreshInterval: Int, CaseIterable, Identifiable {
    case minutes15 = 15
    case minutes30 = 30
    case hour1 = 60
    case hours2 = 120

    var id: Int { self.rawValue }

    var displayName: String {
        switch self {
        case .minutes15:
            return "15分"
        case .minutes30:
            return "30分"
        case .hour1:
            return "1時間"
        case .hours2:
            return "2時間"
        }
    }

    var timeInterval: TimeInterval {
        return TimeInterval(rawValue * 60)
    }
}

/// バックグラウンド更新マネージャー
/// BGTaskSchedulerを使用した定期的なバックグラウンド更新を管理
final class BackgroundRefreshManager: ObservableObject {
    static let shared = BackgroundRefreshManager()

    // MARK: - Task Identifiers

    /// バックグラウンドリフレッシュタスクの識別子
    static let refreshTaskIdentifier = "com.blackcat.delivery.refresh"

    /// バックグラウンド処理タスクの識別子
    static let processingTaskIdentifier = "com.blackcat.delivery.processing"

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKeys {
        static let isEnabled = "BackgroundRefreshEnabled"
        static let refreshInterval = "BackgroundRefreshInterval"
        static let lastRefreshDate = "BackgroundLastRefreshDate"
    }

    // MARK: - Published Properties

    /// バックグラウンド更新が有効かどうか
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: UserDefaultsKeys.isEnabled)
            if isEnabled {
                scheduleAppRefresh()
            } else {
                cancelAllTasks()
            }
        }
    }

    /// 更新間隔
    @Published var refreshInterval: BackgroundRefreshInterval {
        didSet {
            UserDefaults.standard.set(refreshInterval.rawValue, forKey: UserDefaultsKeys.refreshInterval)
            if isEnabled {
                scheduleAppRefresh()
            }
        }
    }

    /// 最後の更新日時
    @Published private(set) var lastRefreshDate: Date? {
        didSet {
            if let date = lastRefreshDate {
                UserDefaults.standard.set(date, forKey: UserDefaultsKeys.lastRefreshDate)
            }
        }
    }

    // MARK: - Private Properties

    private let notificationManager = NotificationManager.shared
    private let apiClient = ApiClient.shared
    private var cancellables = Set<AnyCancellable>()

    /// 前回の配達状況を保持（状態変更検知用）
    private var previousStatusMap: [Int: String] = [:]

    // MARK: - Initialization

    private init() {
        // UserDefaultsから設定を読み込み
        self.isEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isEnabled)

        if let intervalValue = UserDefaults.standard.object(forKey: UserDefaultsKeys.refreshInterval) as? Int,
           let interval = BackgroundRefreshInterval(rawValue: intervalValue) {
            self.refreshInterval = interval
        } else {
            self.refreshInterval = .minutes30
        }

        self.lastRefreshDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastRefreshDate) as? Date

        // 低電力モードの監視
        setupLowPowerModeObserver()
    }

    // MARK: - Public Methods

    /// BGTaskSchedulerにタスクを登録
    /// AppDelegate/App initで呼び出す必要がある
    func registerBackgroundTasks() {
        // App Refreshタスクの登録
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        // Processing タスクの登録（より長時間の処理用）
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleProcessingTask(task: task as! BGProcessingTask)
        }

        print("[BackgroundRefreshManager] Background tasks registered")
    }

    /// バックグラウンドリフレッシュをスケジュール
    func scheduleAppRefresh() {
        guard isEnabled else {
            print("[BackgroundRefreshManager] Background refresh is disabled")
            return
        }

        // 低電力モード時はスケジュールを延期
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            print("[BackgroundRefreshManager] Low power mode enabled, using longer interval")
        }

        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)

        // 更新間隔を設定（低電力モード時は2倍に）
        var interval = refreshInterval.timeInterval
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            interval *= 2
        }

        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundRefreshManager] Scheduled app refresh for \(interval) seconds from now")
        } catch {
            print("[BackgroundRefreshManager] Failed to schedule app refresh: \(error.localizedDescription)")
        }
    }

    /// バックグラウンド処理タスクをスケジュール
    func scheduleProcessingTask() {
        guard isEnabled else { return }

        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        // 次の更新間隔後に実行
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval.timeInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundRefreshManager] Scheduled processing task")
        } catch {
            print("[BackgroundRefreshManager] Failed to schedule processing task: \(error.localizedDescription)")
        }
    }

    /// 全てのスケジュール済みタスクをキャンセル
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        print("[BackgroundRefreshManager] All background tasks cancelled")
    }

    /// バックグラウンド更新のステータスを確認
    func checkBackgroundRefreshStatus() -> UIBackgroundRefreshStatus {
        return UIApplication.shared.backgroundRefreshStatus
    }

    /// バックグラウンド更新が利用可能かどうか
    var isBackgroundRefreshAvailable: Bool {
        return checkBackgroundRefreshStatus() == .available
    }

    // MARK: - Private Methods

    /// App Refreshタスクのハンドリング
    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("[BackgroundRefreshManager] Handling app refresh task")

        // 次のリフレッシュをスケジュール
        scheduleAppRefresh()

        // ネットワーク接続を確認
        guard isNetworkAvailable() else {
            print("[BackgroundRefreshManager] Network not available, marking task complete")
            task.setTaskCompleted(success: false)
            return
        }

        // タスクの期限切れハンドラー
        task.expirationHandler = {
            print("[BackgroundRefreshManager] App refresh task expired")
            task.setTaskCompleted(success: false)
        }

        // 配達状況を更新
        Task {
            let success = await refreshDeliveryStatus()
            task.setTaskCompleted(success: success)

            if success {
                await MainActor.run {
                    self.lastRefreshDate = Date()
                }
            }
        }
    }

    /// Processing タスクのハンドリング
    private func handleProcessingTask(task: BGProcessingTask) {
        print("[BackgroundRefreshManager] Handling processing task")

        // 次の処理タスクをスケジュール
        scheduleProcessingTask()

        // タスクの期限切れハンドラー
        task.expirationHandler = {
            print("[BackgroundRefreshManager] Processing task expired")
            task.setTaskCompleted(success: false)
        }

        // 配達状況を更新
        Task {
            let success = await refreshDeliveryStatus()
            task.setTaskCompleted(success: success)

            if success {
                await MainActor.run {
                    self.lastRefreshDate = Date()
                }
            }
        }
    }

    /// 配達状況を更新
    @discardableResult
    private func refreshDeliveryStatus() async -> Bool {
        let deliveryIDs = LocalDeliveryItems.shared.items

        guard !deliveryIDs.isEmpty else {
            print("[BackgroundRefreshManager] No delivery items to refresh")
            return true
        }

        print("[BackgroundRefreshManager] Refreshing \(deliveryIDs.count) delivery items")

        // APIから最新の配達状況を取得
        let result = await apiClient.tneko(.init(numbers: deliveryIDs))

        guard let tneko = result.value else {
            print("[BackgroundRefreshManager] Failed to fetch delivery status")
            return false
        }

        let deliveryItems = tneko.deliveryList.map { DeliveryItem(deliveryList: $0) }

        // 状態変更を検知して通知を送信
        await checkAndNotifyStatusChanges(items: deliveryItems)

        // ウィジェットデータを同期
        BlackCatApp.syncWidgetData(deliveryItems: deliveryItems)

        print("[BackgroundRefreshManager] Delivery status refresh completed")
        return true
    }

    /// 配達状況の変更を検知して通知を送信
    private func checkAndNotifyStatusChanges(items: [DeliveryItem]) async {
        for item in items {
            guard let latestStatus = item.statusList.first else { continue }

            let deliveryID = item.deliveryID
            let currentStatus = latestStatus.status
            let shopName = latestStatus.shopName

            // 前回の状態と比較
            if let previousStatus = previousStatusMap[deliveryID] {
                // 状態が変更された場合
                if previousStatus != currentStatus {
                    print("[BackgroundRefreshManager] Status changed for \(deliveryID): \(previousStatus) -> \(currentStatus)")

                    // 配達完了の場合は配達完了通知
                    if isDeliveryCompleted(status: currentStatus) {
                        notificationManager.scheduleDeliveryCompletedNotification(
                            deliveryID: deliveryID,
                            shopName: shopName
                        )
                    } else {
                        // それ以外は状態更新通知
                        notificationManager.scheduleStatusUpdateNotification(
                            deliveryID: deliveryID,
                            status: currentStatus,
                            shopName: shopName
                        )
                    }
                }
            }

            // 現在の状態を保存
            previousStatusMap[deliveryID] = currentStatus
        }
    }

    /// 配達完了かどうかを判定
    private func isDeliveryCompleted(status: String) -> Bool {
        let completedStatuses = ["配達完了", "配達完了（宅配ボックス）"]
        return completedStatuses.contains(status)
    }

    /// ネットワーク接続が利用可能かどうかを確認
    private func isNetworkAvailable() -> Bool {
        // 簡易的なネットワーク確認
        // 本格的な実装ではNWPathMonitorを使用することを推奨
        guard let url = URL(string: "https://www.apple.com") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        let semaphore = DispatchSemaphore(value: 0)
        var isAvailable = false

        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                isAvailable = (200...299).contains(httpResponse.statusCode)
            }
            semaphore.signal()
        }
        task.resume()

        _ = semaphore.wait(timeout: .now() + 5)
        return isAvailable
    }

    /// 低電力モードの監視を設定
    private func setupLowPowerModeObserver() {
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                guard let self = self else { return }

                if ProcessInfo.processInfo.isLowPowerModeEnabled {
                    print("[BackgroundRefreshManager] Low power mode enabled")
                } else {
                    print("[BackgroundRefreshManager] Low power mode disabled")
                    // 低電力モードが解除されたら通常の間隔でスケジュール
                    if self.isEnabled {
                        self.scheduleAppRefresh()
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension BackgroundRefreshManager {
    /// デバッグ用：バックグラウンドタスクを手動でトリガー
    func debugTriggerRefresh() async {
        print("[BackgroundRefreshManager] Debug: Manually triggering refresh")
        await refreshDeliveryStatus()
        await MainActor.run {
            self.lastRefreshDate = Date()
        }
    }

    /// デバッグ用：前回のステータスをクリア
    func debugClearPreviousStatus() {
        previousStatusMap.removeAll()
        print("[BackgroundRefreshManager] Debug: Cleared previous status map")
    }
}
#endif
