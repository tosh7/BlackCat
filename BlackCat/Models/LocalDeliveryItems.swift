import Foundation
import WidgetKit

// MARK: - StoredDeliveryItem

/// キャリア情報を含む配達アイテムの永続化モデル
struct StoredDeliveryItem: Codable, Equatable {
    let trackingNumber: String
    let carrier: DeliveryCarrier

    /// 後方互換性のため、trackingNumber を Int に変換して返す（変換不可の場合は nil）
    var trackingNumberInt: Int? {
        return Int(trackingNumber)
    }
}

// MARK: - LocalDeliveryItems

final class LocalDeliveryItems {
    static let shared = LocalDeliveryItems()
    private let key = "ItemList"
    private let storedItemsKey = "StoredItemList"
    /// App Group identifier for sharing data with widget
    private let appGroupIdentifier = "group.com.blackcat.delivery"

    /// Codable ベースの保存データ
    private(set) var storedItems: [StoredDeliveryItem]

    /// 後方互換性のための computed property
    /// storedItems から trackingNumber の Int 値を返す
    var items: [Int] {
        return storedItems.compactMap { $0.trackingNumberInt }
    }

    /// Standard UserDefaults (fallback)
    private let userdefaults = UserDefaults.standard

    /// Shared UserDefaults for App Group
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    init() {
        let sharedDefaultsInstance = UserDefaults(suiteName: appGroupIdentifier)

        // 1. まず新形式 (StoredDeliveryItem) のデータを試みる
        if let loaded = Self.loadStoredItems(from: sharedDefaultsInstance, key: "StoredItemList") {
            storedItems = loaded
        } else if let loaded = Self.loadStoredItems(from: UserDefaults.standard, key: "StoredItemList") {
            storedItems = loaded
            // shared defaults へ同期
            Self.saveStoredItems(loaded, to: sharedDefaultsInstance, key: "StoredItemList")
        }
        // 2. 新形式がなければ旧形式 ([Int]) からマイグレーション
        else if let sharedDefaults = sharedDefaultsInstance,
                let array = sharedDefaults.array(forKey: key) as? [Int] {
            storedItems = Self.migrateFromIntArray(array)
            Self.saveStoredItems(storedItems, to: sharedDefaultsInstance, key: "StoredItemList")
            Self.saveStoredItems(storedItems, to: UserDefaults.standard, key: "StoredItemList")
        } else if let array = UserDefaults.standard.array(forKey: key) as? [Int] {
            storedItems = Self.migrateFromIntArray(array)
            Self.saveStoredItems(storedItems, to: sharedDefaultsInstance, key: "StoredItemList")
            Self.saveStoredItems(storedItems, to: UserDefaults.standard, key: "StoredItemList")
        } else {
            storedItems = []
        }

        // 旧形式のデータも引き続き同期しておく（Widget フォールバック用）
        syncLegacyItems()
    }

    // MARK: - Public Methods

    func add(_ content: Int, carrier: DeliveryCarrier = .yamato) {
        let item = StoredDeliveryItem(trackingNumber: String(content), carrier: carrier)
        storedItems.insert(item, at: 0)
        saveItems()
        NotificationCenter.default.post(name: .addItem, object: nil)
        reloadWidget()
    }

    /// 文字列の追跡番号を追加（キャリア情報付き）
    func addTrackingNumber(_ trackingNumber: String, carrier: DeliveryCarrier = .yamato) {
        let cleanedNumber = trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        let item = StoredDeliveryItem(trackingNumber: cleanedNumber, carrier: carrier)
        storedItems.insert(item, at: 0)
        saveItems()
        NotificationCenter.default.post(name: .addItem, object: nil)
        reloadWidget()
    }

    func remove(id: Int) {
        storedItems.removeAll(where: { $0.trackingNumberInt == id })
        saveItems()
        NotificationCenter.default.post(name: .removeItem, object: nil)
        reloadWidget()
    }

    func update() {
        let sharedDefaultsInstance = UserDefaults(suiteName: appGroupIdentifier)
        if let loaded = Self.loadStoredItems(from: sharedDefaultsInstance, key: storedItemsKey) {
            storedItems = loaded
        } else if let loaded = Self.loadStoredItems(from: userdefaults, key: storedItemsKey) {
            storedItems = loaded
        } else if let sharedDefaults = sharedDefaultsInstance,
                  let array = sharedDefaults.array(forKey: key) as? [Int] {
            storedItems = Self.migrateFromIntArray(array)
        } else if let array = userdefaults.array(forKey: key) as? [Int] {
            storedItems = Self.migrateFromIntArray(array)
        }
    }

    func removeDeplicates(deliveryItems newItems: [DeliveryItem]) {
        let validIDs = Set(newItems.compactMap { item -> Int? in
            item.statusList.isEmpty ? nil : item.deliveryID
        })
        storedItems = storedItems.filter { item in
            guard let intValue = item.trackingNumberInt else { return true }
            return validIDs.contains(intValue)
        }
        saveItems()
    }

    /// 特定の追跡番号に対応する StoredDeliveryItem を取得
    func storedItem(for trackingNumber: Int) -> StoredDeliveryItem? {
        return storedItems.first(where: { $0.trackingNumberInt == trackingNumber })
    }

    /// 特定の追跡番号のキャリアを取得（見つからない場合は .yamato をデフォルトで返す）
    func carrier(for trackingNumber: Int) -> DeliveryCarrier {
        return storedItem(for: trackingNumber)?.carrier ?? .yamato
    }

    // MARK: - Private Methods

    /// Save items to both standard and shared UserDefaults
    private func saveItems() {
        // 新形式で保存
        Self.saveStoredItems(storedItems, to: userdefaults, key: storedItemsKey)
        Self.saveStoredItems(storedItems, to: sharedDefaults, key: storedItemsKey)

        // 旧形式も同期（Widget フォールバック用）
        syncLegacyItems()
    }

    /// 旧形式の [Int] データを同期（後方互換性・Widget用）
    private func syncLegacyItems() {
        let legacyItems = items
        userdefaults.set(legacyItems, forKey: key)
        sharedDefaults?.set(legacyItems, forKey: key)
    }

    /// Reload widget timeline
    private func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "BlackCarWidget")
    }

    // MARK: - Static Helpers

    /// 旧形式の [Int] 配列を StoredDeliveryItem 配列にマイグレーション
    /// 既存データは全て .yamato として扱う
    private static func migrateFromIntArray(_ array: [Int]) -> [StoredDeliveryItem] {
        return array.map { StoredDeliveryItem(trackingNumber: String($0), carrier: .yamato) }
    }

    /// UserDefaults から StoredDeliveryItem 配列を読み込む
    private static func loadStoredItems(from defaults: UserDefaults?, key: String) -> [StoredDeliveryItem]? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([StoredDeliveryItem].self, from: data)
    }

    /// UserDefaults に StoredDeliveryItem 配列を保存する
    private static func saveStoredItems(_ items: [StoredDeliveryItem], to defaults: UserDefaults?, key: String) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }
}
