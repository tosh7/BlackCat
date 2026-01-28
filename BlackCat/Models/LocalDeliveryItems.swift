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
        if let sharedDefaults = sharedDefaults,
           let array = sharedDefaults.array(forKey: key) as? [Int] {
            items = array
        } else if let array = userdefaults.array(forKey: key) as? [Int] {
            items = array
            // Migrate to shared defaults
            sharedDefaults?.set(array, forKey: key)
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
