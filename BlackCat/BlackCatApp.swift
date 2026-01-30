import SwiftUI
import Domain
import WidgetKit
import UserNotifications
import BackgroundTasks

let apiClient = ApiClient.shared

@main
struct BlackCatApp: App {
    @State private var deepLinkDeliveryID: Int?
    @State private var isSplashActive: Bool = false

    /// 通知マネージャーの初期化
    private let notificationManager = NotificationManager.shared

    /// バックグラウンド更新マネージャーの初期化
    private let backgroundRefreshManager = BackgroundRefreshManager.shared

    init() {
        // アプリ起動時に通知の許可をリクエスト
        setupNotifications()

        // バックグラウンドタスクを登録
        setupBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashActive {
                    RootView()
                        .transition(.opacity)
                } else {
                    SplashView(isActive: $isSplashActive)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isSplashActive)
            .onOpenURL { url in
                handleDeepLink(url: url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didTapDeliveryNotification)) { notification in
                handleNotificationTap(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                handleDidEnterBackground()
            }
        }
    }

    // MARK: - Notification Setup

    /// 通知の初期設定
    private func setupNotifications() {
        notificationManager.requestAuthorization { granted in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // MARK: - Background Tasks Setup

    /// バックグラウンドタスクの初期設定
    private func setupBackgroundTasks() {
        // BGTaskSchedulerにタスクを登録
        backgroundRefreshManager.registerBackgroundTasks()

        // バックグラウンド更新が有効な場合、初回スケジュール
        if backgroundRefreshManager.isEnabled {
            backgroundRefreshManager.scheduleAppRefresh()
        }
    }

    /// アプリがバックグラウンドに移行した時の処理
    private func handleDidEnterBackground() {
        // バックグラウンド更新をスケジュール
        if backgroundRefreshManager.isEnabled {
            backgroundRefreshManager.scheduleAppRefresh()
        }
    }

    /// 通知タップ時のハンドリング
    private func handleNotificationTap(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let deliveryID = userInfo["deliveryID"] as? Int else { return }

        // 配達詳細画面へ遷移するためのdeepLinkIDを設定
        deepLinkDeliveryID = deliveryID
    }

    /// ウィジェットからのディープリンクをハンドリング
    private func handleDeepLink(url: URL) {
        guard url.scheme == "blackcat" else { return }

        switch url.host {
        case "delivery":
            // 配達リスト画面を表示（デフォルト動作）
            // 特定のdeliveryIDがpathにある場合は詳細画面へ遷移
            if let pathComponent = url.pathComponents.dropFirst().first,
               let deliveryID = Int(pathComponent) {
                deepLinkDeliveryID = deliveryID
            }
        default:
            break
        }
    }
}

// MARK: - Widget Data Synchronization

extension BlackCatApp {
    /// アプリからウィジェットへデータを同期する
    /// DeliveryListViewModelの更新時に呼び出す
    static func syncWidgetData(deliveryItems: [DeliveryItem]) {
        let widgetItems = deliveryItems.compactMap { item -> WidgetDeliveryItem? in
            guard let latestStatus = item.statusList.first else { return nil }
            return WidgetDeliveryItem(
                deliveryID: item.deliveryID,
                latestStatus: latestStatus.status,
                latestDate: latestStatus.date,
                latestTime: latestStatus.time,
                shopName: latestStatus.shopName,
                statusType: WidgetDeliveryStatusType.from(status: latestStatus.status)
            )
        }

        WidgetDataManager.shared.saveDeliveryItems(widgetItems)
        WidgetCenter.shared.reloadTimelines(ofKind: "BlackCarWidget")
    }
}

// MARK: - Widget Models (Shared with Widget Extension)

/// ウィジェットで使用する配達アイテムモデル
struct WidgetDeliveryItem: Identifiable, Codable {
    let id: UUID
    let deliveryID: Int
    let latestStatus: String
    let latestDate: String
    let latestTime: String?
    let shopName: String
    let statusType: WidgetDeliveryStatusType

    init(id: UUID = UUID(), deliveryID: Int, latestStatus: String, latestDate: String, latestTime: String?, shopName: String, statusType: WidgetDeliveryStatusType) {
        self.id = id
        self.deliveryID = deliveryID
        self.latestStatus = latestStatus
        self.latestDate = latestDate
        self.latestTime = latestTime
        self.shopName = shopName
        self.statusType = statusType
    }
}

/// 配達ステータスの種類
enum WidgetDeliveryStatusType: String, Codable {
    case received = "荷物受付"
    case sended = "発送済み"
    case shipping = "輸送中"
    case delivering = "配達中"
    case delivered = "配達完了"
    case unknown = "不明"

    static func from(status: String) -> WidgetDeliveryStatusType {
        switch status {
        case "荷物受付":
            return .received
        case "発送済み":
            return .sended
        case "輸送中":
            return .shipping
        case "配達中", "持戻（ご不在）", "配達日・時間帯指定（保管中）":
            return .delivering
        case "配達完了", "配達完了（宅配ボックス）":
            return .delivered
        default:
            return .unknown
        }
    }
}

/// App Groupを使用してアプリとウィジェット間でデータを共有するマネージャー
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupIdentifier = "group.com.blackcat.delivery"
    private let deliveryItemsKey = "WidgetDeliveryItems"
    private let lastUpdateKey = "WidgetLastUpdate"
    private let itemListKey = "ItemList"

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private var standardDefaults: UserDefaults {
        return UserDefaults.standard
    }

    init() {}

    func saveDeliveryItems(_ items: [WidgetDeliveryItem]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(items) {
            sharedDefaults?.set(encoded, forKey: deliveryItemsKey)
            sharedDefaults?.set(Date(), forKey: lastUpdateKey)
        }
    }

    func loadDeliveryItems() -> [WidgetDeliveryItem] {
        if let data = sharedDefaults?.data(forKey: deliveryItemsKey) {
            let decoder = JSONDecoder()
            if let items = try? decoder.decode([WidgetDeliveryItem].self, from: data) {
                return items
            }
        }
        return []
    }
}
