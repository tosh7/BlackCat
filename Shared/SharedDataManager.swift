import Foundation

/// App Groupを使用してiOS/watchOS間でデータを共有するマネージャー
/// 両プラットフォームで共通で使用される
public final class SharedDataManager {
    public static let shared = SharedDataManager()

    // MARK: - Constants

    /// App Group識別子
    public static let appGroupIdentifier = "group.com.blackcat.delivery"

    /// 配達アイテムのキー
    private let deliveryItemsKey = "SharedDeliveryItems"

    /// 最終更新日時のキー
    private let lastUpdateKey = "SharedLastUpdate"

    // MARK: - Properties

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: SharedDataManager.appGroupIdentifier)
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 配達アイテムを保存する
    /// - Parameter items: 保存する配達アイテムの配列
    public func saveDeliveryItems(_ items: [SharedDeliveryItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let encoded = try encoder.encode(items)
            sharedDefaults?.set(encoded, forKey: deliveryItemsKey)
            sharedDefaults?.set(Date(), forKey: lastUpdateKey)
            sharedDefaults?.synchronize()
        } catch {
            print("[SharedDataManager] Failed to encode delivery items: \(error)")
        }
    }

    /// 配達アイテムを読み込む
    /// - Returns: 保存されている配達アイテムの配列
    public func loadDeliveryItems() -> [SharedDeliveryItem] {
        guard let data = sharedDefaults?.data(forKey: deliveryItemsKey) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let items = try decoder.decode([SharedDeliveryItem].self, from: data)
            return items
        } catch {
            print("[SharedDataManager] Failed to decode delivery items: \(error)")
            return []
        }
    }

    /// 最終更新日時を取得する
    /// - Returns: 最終更新日時（存在しない場合はnil）
    public func lastUpdateDate() -> Date? {
        return sharedDefaults?.object(forKey: lastUpdateKey) as? Date
    }

    /// すべての共有データをクリアする
    public func clearAllData() {
        sharedDefaults?.removeObject(forKey: deliveryItemsKey)
        sharedDefaults?.removeObject(forKey: lastUpdateKey)
        sharedDefaults?.synchronize()
    }

    /// 特定のアイテムを削除する
    /// - Parameter id: 削除するアイテムのID
    public func removeItem(withId id: UUID) {
        var items = loadDeliveryItems()
        items.removeAll { $0.id == id }
        saveDeliveryItems(items)
    }

    /// アイテムを追加する
    /// - Parameter item: 追加するアイテム
    public func addItem(_ item: SharedDeliveryItem) {
        var items = loadDeliveryItems()
        items.append(item)
        saveDeliveryItems(items)
    }

    /// アイテムを更新する
    /// - Parameter item: 更新するアイテム
    public func updateItem(_ item: SharedDeliveryItem) {
        var items = loadDeliveryItems()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveDeliveryItems(items)
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    /// 共有データが更新された時の通知
    static let sharedDataDidUpdate = Notification.Name("sharedDataDidUpdate")
}
