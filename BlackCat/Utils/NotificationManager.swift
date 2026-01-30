import Foundation
import UserNotifications
import UIKit

/// 通知の種類を定義
enum DeliveryNotificationType: String {
    case statusUpdated = "delivery_status_updated"
    case delivered = "delivery_completed"
    case scheduledDelivery = "scheduled_delivery"

    var title: String {
        switch self {
        case .statusUpdated:
            return "配達状況が更新されました"
        case .delivered:
            return "配達が完了しました"
        case .scheduledDelivery:
            return "配達予定のお知らせ"
        }
    }
}

/// 通知管理クラス
/// Push通知およびローカル通知の管理を担当
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    /// 通知許可の状態
    @Published private(set) var isAuthorized: Bool = false

    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// 通知の許可をリクエスト
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
                completion?(granted)
            }
        }
    }

    /// 現在の許可状態を確認
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications

    /// 配達状況更新通知をスケジュール
    /// - Parameters:
    ///   - deliveryID: 配達ID
    ///   - status: 更新された状態
    ///   - shopName: 店舗名
    func scheduleStatusUpdateNotification(deliveryID: Int, status: String, shopName: String) {
        let content = UNMutableNotificationContent()
        content.title = DeliveryNotificationType.statusUpdated.title
        content.body = "【\(shopName)】\n状態: \(status)"
        content.sound = .default
        content.userInfo = [
            "type": DeliveryNotificationType.statusUpdated.rawValue,
            "deliveryID": deliveryID
        ]

        // 即時通知（1秒後）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "\(DeliveryNotificationType.statusUpdated.rawValue)_\(deliveryID)_\(Date().timeIntervalSince1970)"

        scheduleNotification(identifier: identifier, content: content, trigger: trigger)
    }

    /// 配達完了通知をスケジュール
    /// - Parameters:
    ///   - deliveryID: 配達ID
    ///   - shopName: 店舗名
    func scheduleDeliveryCompletedNotification(deliveryID: Int, shopName: String) {
        let content = UNMutableNotificationContent()
        content.title = DeliveryNotificationType.delivered.title
        content.body = "【\(shopName)】の荷物が届きました"
        content.sound = .default
        content.userInfo = [
            "type": DeliveryNotificationType.delivered.rawValue,
            "deliveryID": deliveryID
        ]

        // 即時通知（1秒後）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "\(DeliveryNotificationType.delivered.rawValue)_\(deliveryID)"

        scheduleNotification(identifier: identifier, content: content, trigger: trigger)
    }

    /// 配達予定時間の通知をスケジュール
    /// - Parameters:
    ///   - deliveryID: 配達ID
    ///   - shopName: 店舗名
    ///   - scheduledDate: 配達予定日時
    ///   - reminderMinutesBefore: 何分前に通知するか（デフォルト: 30分前）
    func scheduleDeliveryReminderNotification(
        deliveryID: Int,
        shopName: String,
        scheduledDate: Date,
        reminderMinutesBefore: Int = 30
    ) {
        let content = UNMutableNotificationContent()
        content.title = DeliveryNotificationType.scheduledDelivery.title
        content.body = "【\(shopName)】の荷物がまもなく届きます"
        content.sound = .default
        content.userInfo = [
            "type": DeliveryNotificationType.scheduledDelivery.rawValue,
            "deliveryID": deliveryID
        ]

        // 指定時間前に通知
        let reminderDate = scheduledDate.addingTimeInterval(-Double(reminderMinutesBefore * 60))

        // 過去の日時の場合はスキップ
        guard reminderDate > Date() else {
            print("Scheduled notification skipped: reminder date is in the past")
            return
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "\(DeliveryNotificationType.scheduledDelivery.rawValue)_\(deliveryID)"

        scheduleNotification(identifier: identifier, content: content, trigger: trigger)
    }

    /// 指定した日時にカスタム通知をスケジュール
    /// - Parameters:
    ///   - identifier: 通知の識別子
    ///   - title: 通知タイトル
    ///   - body: 通知本文
    ///   - date: 通知日時
    ///   - userInfo: カスタムデータ
    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        scheduleNotification(identifier: identifier, content: content, trigger: trigger)
    }

    // MARK: - Cancel Notifications

    /// 特定の配達IDに関連する全ての通知をキャンセル
    /// - Parameter deliveryID: 配達ID
    func cancelNotifications(for deliveryID: Int) {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let identifiersToRemove = requests
                .filter { request in
                    if let id = request.content.userInfo["deliveryID"] as? Int {
                        return id == deliveryID
                    }
                    return request.identifier.contains("_\(deliveryID)")
                }
                .map { $0.identifier }

            self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }

    /// 特定の種類の通知をキャンセル
    /// - Parameters:
    ///   - type: 通知の種類
    ///   - deliveryID: 配達ID（オプション）
    func cancelNotification(type: DeliveryNotificationType, deliveryID: Int? = nil) {
        var identifier = type.rawValue
        if let deliveryID = deliveryID {
            identifier += "_\(deliveryID)"
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// 全てのペンディング通知をキャンセル
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// 全ての配信済み通知をクリア
    func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Badge Management

    /// バッジ数を設定
    /// - Parameter count: バッジに表示する数
    func setBadgeCount(_ count: Int) {
        if #available(iOS 16.0, *) {
            notificationCenter.setBadgeCount(count)
        } else {
            // iOS 16未満の場合は非推奨のAPIを使用
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }

    /// バッジをクリア
    func clearBadge() {
        setBadgeCount(0)
    }

    // MARK: - Private Methods

    private func scheduleNotification(
        identifier: String,
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger
    ) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled: \(identifier)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// フォアグラウンドで通知を受信した時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound, .badge])
    }

    /// 通知をタップした時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let typeRaw = userInfo["type"] as? String,
           let deliveryID = userInfo["deliveryID"] as? Int {
            // 通知タップ時のディープリンク処理
            NotificationCenter.default.post(
                name: .didTapDeliveryNotification,
                object: nil,
                userInfo: ["deliveryID": deliveryID, "type": typeRaw]
            )
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// 配達通知がタップされた時のNotification
    static let didTapDeliveryNotification = Notification.Name("didTapDeliveryNotification")
}
