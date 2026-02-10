import Foundation
import WidgetKit

// MARK: - StoredDeliveryItem

/// Persistent model for delivery items with carrier information
struct StoredDeliveryItem: Codable, Equatable {
    let trackingNumber: String
    let carrier: DeliveryCarrier

    /// Converts trackingNumber to Int for backward compatibility (nil if not convertible)
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

    /// Codable-based stored data
    private(set) var storedItems: [StoredDeliveryItem]

    /// Computed property for backward compatibility
    /// Returns Int values of trackingNumber from storedItems
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

        // 1. Try loading new format (StoredDeliveryItem) first
        if let loaded = Self.loadStoredItems(from: sharedDefaultsInstance, key: "StoredItemList") {
            storedItems = loaded
        } else if let loaded = Self.loadStoredItems(from: UserDefaults.standard, key: "StoredItemList") {
            storedItems = loaded
            // Sync to shared defaults
            Self.saveStoredItems(loaded, to: sharedDefaultsInstance, key: "StoredItemList")
        }
        // 2. Fall back to legacy format ([Int]) and migrate
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

        // Keep legacy format in sync for Widget fallback
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

    /// Add tracking number as string with carrier info
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

    /// Get StoredDeliveryItem for a specific tracking number
    func storedItem(for trackingNumber: Int) -> StoredDeliveryItem? {
        return storedItems.first(where: { $0.trackingNumberInt == trackingNumber })
    }

    /// Get carrier for a specific tracking number (defaults to .yamato if not found)
    func carrier(for trackingNumber: Int) -> DeliveryCarrier {
        return storedItem(for: trackingNumber)?.carrier ?? .yamato
    }

    // MARK: - Private Methods

    /// Save items to both standard and shared UserDefaults
    private func saveItems() {
        // Save in new format
        Self.saveStoredItems(storedItems, to: userdefaults, key: storedItemsKey)
        Self.saveStoredItems(storedItems, to: sharedDefaults, key: storedItemsKey)

        // Sync legacy format for Widget fallback
        syncLegacyItems()
    }

    /// Sync legacy [Int] data for backward compatibility and Widget
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

    /// Migrate legacy [Int] array to StoredDeliveryItem array
    /// All existing data is treated as .yamato
    private static func migrateFromIntArray(_ array: [Int]) -> [StoredDeliveryItem] {
        return array.map { StoredDeliveryItem(trackingNumber: String($0), carrier: .yamato) }
    }

    /// Load StoredDeliveryItem array from UserDefaults
    private static func loadStoredItems(from defaults: UserDefaults?, key: String) -> [StoredDeliveryItem]? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([StoredDeliveryItem].self, from: data)
    }

    /// Save StoredDeliveryItem array to UserDefaults
    private static func saveStoredItems(_ items: [StoredDeliveryItem], to defaults: UserDefaults?, key: String) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }
}
