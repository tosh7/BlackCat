import Foundation

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

// MARK: - キャッシュプロトコル
public protocol DeliveryCacheProtocol: Sendable {
    func get(for trackingNumber: String, carrier: DeliveryCarrierType) async -> UnifiedDeliveryInfo?
    func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType) async
    func remove(for trackingNumber: String, carrier: DeliveryCarrierType) async
    func removeAll() async
    func removeExpired() async
}

// MARK: - メモリキャッシュ
public actor DeliveryMemoryCache: DeliveryCacheProtocol {
    public static let shared = DeliveryMemoryCache()

    private var cache: [String: CacheEntry<UnifiedDeliveryInfo>] = [:]
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
        guard let entry = cache[key] else { return nil }

        if entry.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    public func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType) {
        // キャッシュサイズの制限チェック
        if cache.count >= maxEntries {
            removeOldestEntry()
        }

        let key = cacheKey(trackingNumber: trackingNumber, carrier: carrier)
        let entry = CacheEntry(value: info, ttl: defaultTTL)
        cache[key] = entry
    }

    public func remove(for trackingNumber: String, carrier: DeliveryCarrierType) {
        let key = cacheKey(trackingNumber: trackingNumber, carrier: carrier)
        cache.removeValue(forKey: key)
    }

    public func removeAll() {
        cache.removeAll()
    }

    public func removeExpired() {
        cache = cache.filter { !$0.value.isExpired }
    }

    private func removeOldestEntry() {
        guard let oldest = cache.min(by: { $0.value.timestamp < $1.value.timestamp }) else { return }
        cache.removeValue(forKey: oldest.key)
    }
}

// MARK: - ディスクキャッシュ
public actor DeliveryDiskCache: DeliveryCacheProtocol {
    public static let shared = DeliveryDiskCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let defaultTTL: TimeInterval
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaultTTL: TimeInterval = 3600) { // デフォルト1時間
        self.defaultTTL = defaultTTL

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
              let entry = try? decoder.decode(CacheEntry<UnifiedDeliveryInfo>.self, from: data) else {
            return nil
        }

        if entry.isExpired {
            try? fileManager.removeItem(at: url)
            return nil
        }

        return entry.value
    }

    public func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType) {
        let url = fileURL(trackingNumber: trackingNumber, carrier: carrier)
        let entry = CacheEntry(value: info, ttl: defaultTTL)

        guard let data = try? encoder.encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
    }

    public func remove(for trackingNumber: String, carrier: DeliveryCarrierType) {
        let url = fileURL(trackingNumber: trackingNumber, carrier: carrier)
        try? fileManager.removeItem(at: url)
    }

    public func removeAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    public func removeExpired() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }

        for file in files {
            if let data = try? Data(contentsOf: file),
               let entry = try? decoder.decode(CacheEntry<UnifiedDeliveryInfo>.self, from: data),
               entry.isExpired {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// MARK: - 2段キャッシュ (メモリ + ディスク)
public actor DeliveryTieredCache: DeliveryCacheProtocol {
    public static let shared = DeliveryTieredCache()

    private let memoryCache: DeliveryMemoryCache
    private let diskCache: DeliveryDiskCache

    public init(memoryCache: DeliveryMemoryCache = .shared, diskCache: DeliveryDiskCache = .shared) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }

    public func get(for trackingNumber: String, carrier: DeliveryCarrierType) async -> UnifiedDeliveryInfo? {
        // まずメモリキャッシュを確認
        if let info = await memoryCache.get(for: trackingNumber, carrier: carrier) {
            return info
        }

        // メモリになければディスクキャッシュを確認
        if let info = await diskCache.get(for: trackingNumber, carrier: carrier) {
            // ディスクにあればメモリにも保存
            await memoryCache.set(info, for: trackingNumber, carrier: carrier)
            return info
        }

        return nil
    }

    public func set(_ info: UnifiedDeliveryInfo, for trackingNumber: String, carrier: DeliveryCarrierType) async {
        await memoryCache.set(info, for: trackingNumber, carrier: carrier)
        await diskCache.set(info, for: trackingNumber, carrier: carrier)
    }

    public func remove(for trackingNumber: String, carrier: DeliveryCarrierType) async {
        await memoryCache.remove(for: trackingNumber, carrier: carrier)
        await diskCache.remove(for: trackingNumber, carrier: carrier)
    }

    public func removeAll() async {
        await memoryCache.removeAll()
        await diskCache.removeAll()
    }

    public func removeExpired() async {
        await memoryCache.removeExpired()
        await diskCache.removeExpired()
    }
}
