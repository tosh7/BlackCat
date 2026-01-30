import Foundation

extension Notification.Name {
    static let addItem = Notification.Name("AddItem")
    static let removeItem = Notification.Name("removeItem")

    // MARK: - Delivery Notifications

    /// 配達状況が更新された時の通知
    static let deliveryStatusUpdated = Notification.Name("deliveryStatusUpdated")

    /// 配達が完了した時の通知
    static let deliveryCompleted = Notification.Name("deliveryCompleted")

    /// 配達予定時間が近づいた時の通知
    static let deliveryScheduledReminder = Notification.Name("deliveryScheduledReminder")

    // MARK: - Background Refresh Notifications

    /// バックグラウンド更新が完了した時の通知
    static let backgroundRefreshCompleted = Notification.Name("backgroundRefreshCompleted")

    /// バックグラウンド更新が失敗した時の通知
    static let backgroundRefreshFailed = Notification.Name("backgroundRefreshFailed")
}
