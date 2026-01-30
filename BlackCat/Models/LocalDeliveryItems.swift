import Foundation
import WidgetKit

final class LocalDeliveryItems {
    static let shared = LocalDeliveryItems()
    private let key = "ItemList"
    /// App Group identifier for sharing data with widget
    private let appGroupIdentifier = "group.com.blackcat.delivery"

    /// Items should be a read only property
    /// if you want to add a content, use add method
    private(set) var items: [Int]

    /// Standard UserDefaults (fallback)
    private let userdefaults = UserDefaults.standard

    /// Shared UserDefaults for App Group
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    init() {
        // Try to load from shared defaults first, then fallback to standard
        let sharedDefaultsInstance = UserDefaults(suiteName: appGroupIdentifier)
        if let sharedDefaults = sharedDefaultsInstance,
           let array = sharedDefaults.array(forKey: key) as? [Int] {
            items = array
        } else if let array = userdefaults.array(forKey: key) as? [Int] {
            items = array
            // Migrate to shared defaults
            sharedDefaultsInstance?.set(array, forKey: key)
        } else {
            items = []
        }
    }

    func add(_ content: Int) {
        items.insert(content, at: 0)
        saveItems()
        NotificationCenter.default.post(name: .addItem, object: nil)
        reloadWidget()
    }

    /// 文字列の追跡番号を追加（国際郵便など数字以外を含む番号にも対応）
    /// 数値に変換可能な場合はIntとして保存し、不可能な場合はログ出力のみ
    func addTrackingNumber(_ trackingNumber: String) {
        if let intValue = Int(trackingNumber) {
            add(intValue)
        } else {
            // 国際郵便番号（例: EA123456789JP）はInt変換不可
            // TODO: LocalDeliveryItemsをString型に拡張して対応する
            print("[LocalDeliveryItems] Warning: Cannot store non-numeric tracking number: \(trackingNumber)")
            NotificationCenter.default.post(name: .addItem, object: nil)
        }
    }

    func remove(id: Int) {
        items.removeAll(where: { $0 == id })
        saveItems()
        NotificationCenter.default.post(name: .removeItem, object: nil)
        reloadWidget()
    }

    func update() {
        if let sharedDefaults = sharedDefaults,
           let array = sharedDefaults.array(forKey: key) as? [Int] {
            items = array
        } else if let array = userdefaults.array(forKey: key) as? [Int] {
            items = array
        }
    }

    func removeDeplicates(deliveryItems newItems: [DeliveryItem]) {
        items = newItems.compactMap {
            $0.statusList.isEmpty ? nil : $0.deliveryID
        }
        saveItems()
    }

    /// Save items to both standard and shared UserDefaults
    private func saveItems() {
        userdefaults.set(items, forKey: key)
        sharedDefaults?.set(items, forKey: key)
    }

    /// Reload widget timeline
    private func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "BlackCarWidget")
    }
}
