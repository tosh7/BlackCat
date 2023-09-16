import Foundation

final class LocalDeliveryItems {
    static let shared = LocalDeliveryItems()
    private let key = "ItemList"
    /// Items should be a read only property
    /// if you want to add a content, use add method
    private(set) var items: [Int]
    private let userdefaults = UserDefaults.standard

    init() {
        if let array = userdefaults.array(forKey: key) {
            items = array as! [Int]
        } else {
            items = []
        }
    }

    func add(_ content: Int) {
        items.insert(content, at: 0)
        userdefaults.set(items, forKey: key)
        NotificationCenter.default.post(name: .addItem, object: nil)
    }

    func remove(id: Int) {
        items.removeAll(where: { $0 == id })
        userdefaults.set(items, forKey: key)
        NotificationCenter.default.post(name: .removeItem, object: nil)
    }

    func update() {
        items = userdefaults.array(forKey: key) as! [Int]
    }

    func removeDeplicates(deliveryItems newItems: [DeliveryItem]) {
        items = newItems.compactMap {
            $0.statusList.isEmpty ? nil : $0.deliveryID
        }
        userdefaults.set(items, forKey: key)
    }
}
