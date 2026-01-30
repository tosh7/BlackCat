import Foundation

// MARK: - APIクライアント設定
public struct APIClientConfiguration {
    /// タイムアウト時間（秒）
    public var timeoutInterval: TimeInterval

    /// リトライ最大回数
    public var maxRetryCount: Int

    /// リトライ間隔の基準時間（秒）
    public var retryBaseDelay: TimeInterval

    /// Exponential Backoffを使用するか
    public var useExponentialBackoff: Bool

    /// キャッシュを有効にするか
    public var cacheEnabled: Bool

    /// キャッシュTTL（秒）
    public var cacheTTL: TimeInterval

    /// ネットワークエラー時にキャッシュを返すか
    public var returnCacheOnError: Bool

    public init(
        timeoutInterval: TimeInterval = 30.0,
        maxRetryCount: Int = 3,
        retryBaseDelay: TimeInterval = 1.0,
        useExponentialBackoff: Bool = true,
        cacheEnabled: Bool = true,
        cacheTTL: TimeInterval = 300,
        returnCacheOnError: Bool = true
    ) {
        self.timeoutInterval = timeoutInterval
        self.maxRetryCount = maxRetryCount
        self.retryBaseDelay = retryBaseDelay
        self.useExponentialBackoff = useExponentialBackoff
        self.cacheEnabled = cacheEnabled
        self.cacheTTL = cacheTTL
        self.returnCacheOnError = returnCacheOnError
    }

    /// デフォルト設定
    public static let `default` = APIClientConfiguration()

    /// 高速設定（短いタイムアウト、少ないリトライ）
    public static let fast = APIClientConfiguration(
        timeoutInterval: 10.0,
        maxRetryCount: 1,
        retryBaseDelay: 0.5,
        cacheEnabled: true
    )

    /// 堅牢設定（長いタイムアウト、多いリトライ）
    public static let robust = APIClientConfiguration(
        timeoutInterval: 60.0,
        maxRetryCount: 5,
        retryBaseDelay: 2.0,
        cacheEnabled: true
    )
}

// MARK: - リトライポリシー
public struct RetryPolicy {
    public let maxRetryCount: Int
    public let baseDelay: TimeInterval
    public let useExponentialBackoff: Bool
    public let retryableErrors: Set<APIError>

    public init(
        maxRetryCount: Int = 3,
        baseDelay: TimeInterval = 1.0,
        useExponentialBackoff: Bool = true,
        retryableErrors: Set<APIError> = [.timeout, .noConnection]
    ) {
        self.maxRetryCount = maxRetryCount
        self.baseDelay = baseDelay
        self.useExponentialBackoff = useExponentialBackoff
        self.retryableErrors = retryableErrors
    }

    /// 指定された試行回数後の待機時間を計算
    public func delay(for attempt: Int) -> TimeInterval {
        if useExponentialBackoff {
            // Exponential backoff with jitter
            let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
            let jitter = Double.random(in: 0...0.3) * exponentialDelay
            return exponentialDelay + jitter
        } else {
            return baseDelay
        }
    }

    /// エラーがリトライ可能かどうか判定
    public func shouldRetry(error: APIError, currentAttempt: Int) -> Bool {
        guard currentAttempt < maxRetryCount else { return false }
        return error.isRetryable
    }
}
