import Foundation
import Synchronization

// MARK: - キャッシュエントリ
public struct CacheEntry<T: Codable>: Codable {
    public let value: T
    public let timestamp: Date
    public let expiresAt: Date

    public init(value: T, ttl: TimeInterval) {
        self.value = value
        self.timestamp = Date()
        self.expiresAt = Date().addingTimeInterval(ttl)
    }

    public var isExpired: Bool {
        return Date() > expiresAt
    }
}

extension CacheEntry: Sendable where T: Sendable {}

// MARK: - キャッシュプロトコル
public protocol DeliveryCacheProtocol: Sendable {
    func get(for trackingNumber: String, carrier: DeliveryCarrierType) -> UnifiedDeliveryInfo?
    func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType)
    func remove(for trackingNumber: String, carrier: DeliveryCarrierType)
    func removeAll()
    func removeExpired()
}

// MARK: - メモリキャッシュ
public final class DeliveryMemoryCache: DeliveryCacheProtocol, Sendable {
    public static let shared = DeliveryMemoryCache()

    private let storage = Mutex<[String: CacheEntry<UnifiedDeliveryInfo>]>([:])
    private let defaultTTL: TimeInterval

    /// キャッシュの最大エントリ数
    public let maxEntries: Int = 100

    public init(defaultTTL: TimeInterval = 300) { // デフォルト5分
        self.defaultTTL = defaultTTL
    }

    private func cacheKey(trackingNumber: String, carrier: DeliveryCarrierType) -> String {
        return "\(carrier.rawValue)_\(trackingNumber)"
    }

    public func get(for trackingNumber: String, carrier: DeliveryCarrierType) -> UnifiedDeliveryInfo? {
        let key = cacheKey(trackingNumber: trackingNumber, carrier: carrier)
        return storage.withLock { cache in
            guard let entry = cache[key] else { return nil }

            if entry.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }

            return entry.value
        }
    }

    public func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType) {
        let key = cacheKey(trackingNumber: trackingNumber, carrier: carrier)
        let entry = CacheEntry(value: info, ttl: defaultTTL)
        storage.withLock { cache in
            // キャッシュサイズの制限チェック（最古エントリを削除）
            if cache.count >= maxEntries,
               let oldest = cache.min(by: { $0.value.timestamp < $1.value.timestamp }) {
                cache.removeValue(forKey: oldest.key)
            }
            cache[key] = entry
        }
    }

    public func remove(for trackingNumber: String, carrier: DeliveryCarrierType) {
        let key = cacheKey(trackingNumber: trackingNumber, carrier: carrier)
        storage.withLock { $0.removeValue(forKey: key) }
    }

    public func removeAll() {
        storage.withLock { $0.removeAll() }
    }

    public func removeExpired() {
        storage.withLock { cache in
            cache = cache.filter { !$0.value.isExpired }
        }
    }
}

// MARK: - ディスクキャッシュ
public final class DeliveryDiskCache: DeliveryCacheProtocol, Sendable {
    public static let shared = DeliveryDiskCache()

    private let cacheDirectory: URL
    private let defaultTTL: TimeInterval

    public init(defaultTTL: TimeInterval = 3600) { // デフォルト1時間
        self.defaultTTL = defaultTTL

        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDir.appendingPathComponent("DeliveryCache", isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(trackingNumber: String, carrier: DeliveryCarrierType) -> URL {
        let filename = "\(carrier.rawValue)_\(trackingNumber).cache"
        return cacheDirectory.appendingPathComponent(filename)
    }

    public func get(for trackingNumber: String, carrier: DeliveryCarrierType) -> UnifiedDeliveryInfo? {
        let url = fileURL(trackingNumber: trackingNumber, carrier: carrier)

        guard let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(CacheEntry<UnifiedDeliveryInfo>.self, from: data) else {
            return nil
        }

        if entry.isExpired {
            try? FileManager.default.removeItem(at: url)
            return nil
        }

        return entry.value
    }

    public func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType) {
        let url = fileURL(trackingNumber: trackingNumber, carrier: carrier)
        let entry = CacheEntry(value: info, ttl: defaultTTL)

        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
    }

    public func remove(for trackingNumber: String, carrier: DeliveryCarrierType) {
        let url = fileURL(trackingNumber: trackingNumber, carrier: carrier)
        try? FileManager.default.removeItem(at: url)
    }

    public func removeAll() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    public func removeExpired() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }

        for file in files {
            if let data = try? Data(contentsOf: file),
               let entry = try? JSONDecoder().decode(CacheEntry<UnifiedDeliveryInfo>.self, from: data),
               entry.isExpired {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// MARK: - 2段キャッシュ (メモリ + ディスク)
public final class DeliveryTieredCache: DeliveryCacheProtocol, Sendable {
    public static let shared = DeliveryTieredCache()

    private let memoryCache: DeliveryMemoryCache
    private let diskCache: DeliveryDiskCache

    public init(memoryCache: DeliveryMemoryCache = .shared, diskCache: DeliveryDiskCache = .shared) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }

    public func get(for trackingNumber: String, carrier: DeliveryCarrierType) -> UnifiedDeliveryInfo? {
        // まずメモリキャッシュを確認
        if let info = memoryCache.get(for: trackingNumber, carrier: carrier) {
            return info
        }

        // メモリになければディスクキャッシュを確認
        if let info = diskCache.get(for: trackingNumber, carrier: carrier) {
            // ディスクにあればメモリにも保存
            memoryCache.set(info, for: trackingNumber, carrier: carrier)
            return info
        }

        return nil
    }

    public func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType) {
        memoryCache.set(info, for: trackingNumber, carrier: carrier)
        diskCache.set(info, for: trackingNumber, carrier: carrier)
    }

    public func remove(for trackingNumber: String, carrier: DeliveryCarrierType) {
        memoryCache.remove(for: trackingNumber, carrier: carrier)
        diskCache.remove(for: trackingNumber, carrier: carrier)
    }

    public func removeAll() {
        memoryCache.removeAll()
        diskCache.removeAll()
    }

    public func removeExpired() {
        memoryCache.removeExpired()
        diskCache.removeExpired()
    }
}
