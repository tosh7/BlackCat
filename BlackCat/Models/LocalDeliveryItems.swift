import Foundation

final class LocalDeliveryItems {
    static let shared = LocalDeliveryItems()
    private let key = "ItemList"
    /// Items should be a read only property
    /// if you want to add a content, use add method
    private(set) var items: [Int]
    private let userdefaults = UserDefaults.standard

    init() {
        items = userdefaults.array(forKey: key) as! [Int]
    }

    func add(_ content: Int) {
        items.insert(content, at: 0)
        userdefaults.set(items, forKey: key)
    }

    func remove(_ index: Int) {
        items.remove(at: index)
        userdefaults.set(items, forKey: key)
    }

    func update() {
        items = userdefaults.array(forKey: key) as! [Int]
    }
}
