//
//  WatchConnectivityManager.swift
//  BlackCatWatch
//
//  watchOS側のWatch Connectivity管理クラス
//  iOSアプリとの配達データ同期を担当
//

import Foundation
import WatchConnectivity
import Combine

// MARK: - watchOS側 WatchConnectivityManager

/// watchOSアプリ側のWatch Connectivity管理クラス
/// シングルトンパターンで実装し、アプリ全体で共有
final class WatchConnectivityManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties

    /// 同期状態
    @Published private(set) var syncState: WatchSyncState = .idle

    /// iOSアプリがリーチャブルか（即時通信可能か）
    @Published private(set) var isPhoneReachable: Bool = false

    /// 配達データ
    @Published private(set) var deliveries: [WatchDeliveryData] = []

    /// アクティブな配達数
    @Published private(set) var activeDeliveryCount: Int = 0

    /// 配達完了数
    @Published private(set) var deliveredCount: Int = 0

    /// 最後の同期日時
    @Published private(set) var lastSyncDate: Date?

    /// エラーメッセージ
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()

    /// リクエストタイムアウト（秒）
    private let requestTimeout: TimeInterval = 30

    // MARK: - Initialization

    private override init() {
        super.init()
        setupSession()
    }

    // MARK: - Setup

    /// WCSessionのセットアップ
    private func setupSession() {
        guard WCSession.isSupported() else {
            print("[WatchConnectivity] WCSession is not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        print("[WatchConnectivity] Watch session setup completed")
    }

    // MARK: - Public Methods

    /// iOSアプリから全配達データをリクエスト
    func requestAllDeliveries() {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated")
            errorMessage = WatchSyncError.sessionNotActivated.localizedDescription
            syncState = .error(WatchSyncError.sessionNotActivated.localizedDescription)
            return
        }

        guard session.isReachable else {
            print("[WatchConnectivity] iPhone is not reachable, using cached data")
            // リーチャブルでない場合はApplication Contextから読み込み
            loadFromApplicationContext()
            return
        }

        syncState = .syncing
        errorMessage = nil

        let message: [String: Any] = [
            "type": WatchMessageType.requestAllDeliveries.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: { [weak self] reply in
            self?.handleDeliveriesResponse(reply)
        }) { [weak self] error in
            DispatchQueue.main.async {
                print("[WatchConnectivity] Failed to request deliveries: \(error)")
                self?.errorMessage = error.localizedDescription
                self?.syncState = .error(error.localizedDescription)

                // フォールバック: Application Contextから読み込み
                self?.loadFromApplicationContext()
            }
        }
    }

    /// iOSアプリにステータス更新をリクエスト
    func requestStatusRefresh() {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else {
            errorMessage = WatchSyncError.watchNotReachable.localizedDescription
            syncState = .error(WatchSyncError.watchNotReachable.localizedDescription)
            return
        }

        syncState = .syncing
        errorMessage = nil

        let message: [String: Any] = [
            "type": WatchMessageType.requestStatusRefresh.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: { [weak self] reply in
            self?.handleRefreshResponse(reply)
        }) { [weak self] error in
            DispatchQueue.main.async {
                print("[WatchConnectivity] Failed to request refresh: \(error)")
                self?.errorMessage = error.localizedDescription
                self?.syncState = .error(error.localizedDescription)
            }
        }
    }

    /// ハートビートを送信（接続確認）
    func sendHeartbeat() {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else {
            return
        }

        let message: [String: Any] = [
            "type": WatchMessageType.heartbeat.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: { reply in
            print("[WatchConnectivity] Heartbeat acknowledged")
        }) { error in
            print("[WatchConnectivity] Heartbeat failed: \(error)")
        }
    }

    /// キャッシュされたデータをクリア
    func clearCache() {
        DispatchQueue.main.async { [weak self] in
            self?.deliveries = []
            self?.activeDeliveryCount = 0
            self?.deliveredCount = 0
            self?.lastSyncDate = nil
        }
    }

    // MARK: - Private Methods

    /// Application Contextからデータを読み込み
    private func loadFromApplicationContext() {
        guard let session = session else { return }

        let context = session.receivedApplicationContext

        guard !context.isEmpty,
              let appContext = WatchApplicationContext(dictionary: context) else {
            print("[WatchConnectivity] No valid application context available")
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.deliveries = appContext.deliveries
            self?.activeDeliveryCount = appContext.activeDeliveryCount
            self?.deliveredCount = appContext.deliveredCount
            self?.lastSyncDate = appContext.lastSyncDate
            self?.syncState = .success

            // Complicationを更新
            self?.updateComplication(with: appContext.deliveries)

            print("[WatchConnectivity] Loaded \(appContext.deliveries.count) deliveries from application context")
        }
    }

    /// Complicationのデータを更新
    private func updateComplication(with deliveries: [WatchDeliveryData]) {
        ComplicationDataManager.shared.saveDeliveries(deliveries)
        ComplicationDataManager.shared.reloadComplications()
    }

    /// 配達データレスポンスの処理
    private func handleDeliveriesResponse(_ reply: [String: Any]) {
        guard let typeString = reply["type"] as? String,
              let messageType = WatchMessageType(rawValue: typeString) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid response type"
                self?.syncState = .error("Invalid response type")
            }
            return
        }

        switch messageType {
        case .allDeliveriesResponse, .statusRefreshComplete:
            guard let payload = reply["payload"] as? Data else {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "No payload in response"
                    self?.syncState = .error("No payload in response")
                }
                return
            }

            do {
                let receivedDeliveries = try JSONDecoder().decode([WatchDeliveryData].self, from: payload)

                DispatchQueue.main.async { [weak self] in
                    self?.deliveries = receivedDeliveries
                    self?.activeDeliveryCount = receivedDeliveries.filter { !$0.isDelivered }.count
                    self?.deliveredCount = receivedDeliveries.filter { $0.isDelivered }.count
                    self?.lastSyncDate = Date()
                    self?.syncState = .success
                    self?.errorMessage = nil

                    // Complicationを更新
                    self?.updateComplication(with: receivedDeliveries)

                    print("[WatchConnectivity] Received \(receivedDeliveries.count) deliveries")
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    print("[WatchConnectivity] Failed to decode deliveries: \(error)")
                    self?.errorMessage = WatchSyncError.decodingFailed.localizedDescription
                    self?.syncState = .error(WatchSyncError.decodingFailed.localizedDescription)
                }
            }

        case .error:
            let errorMsg = reply["error"] as? String ?? "Unknown error"
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = errorMsg
                self?.syncState = .error(errorMsg)
            }

        default:
            break
        }
    }

    /// ステータス更新レスポンスの処理
    private func handleRefreshResponse(_ reply: [String: Any]) {
        handleDeliveriesResponse(reply)
    }

    /// 配達更新メッセージの処理
    private func handleDeliveryUpdate(_ message: [String: Any]) {
        guard let payload = message["payload"] as? Data else {
            return
        }

        do {
            let updatedDelivery = try JSONDecoder().decode(WatchDeliveryData.self, from: payload)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // 既存の配達を更新または追加
                if let index = self.deliveries.firstIndex(where: { $0.deliveryID == updatedDelivery.deliveryID }) {
                    self.deliveries[index] = updatedDelivery
                } else {
                    self.deliveries.append(updatedDelivery)
                }

                // カウントを更新
                self.activeDeliveryCount = self.deliveries.filter { !$0.isDelivered }.count
                self.deliveredCount = self.deliveries.filter { $0.isDelivered }.count
                self.lastSyncDate = Date()

                print("[WatchConnectivity] Updated delivery: \(updatedDelivery.deliveryID)")
            }
        } catch {
            print("[WatchConnectivity] Failed to decode delivery update: \(error)")
        }
    }

    /// 配達削除メッセージの処理
    private func handleDeliveryDeleted(_ message: [String: Any]) {
        guard let deliveryID = message["deliveryID"] as? Int else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.deliveries.removeAll { $0.deliveryID == deliveryID }

            // カウントを更新
            self.activeDeliveryCount = self.deliveries.filter { !$0.isDelivered }.count
            self.deliveredCount = self.deliveries.filter { $0.isDelivered }.count
            self.lastSyncDate = Date()

            print("[WatchConnectivity] Deleted delivery: \(deliveryID)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("[WatchConnectivity] Activation failed: \(error)")
                self?.errorMessage = error.localizedDescription
                self?.syncState = .error(error.localizedDescription)
                return
            }

            print("[WatchConnectivity] Watch session activated with state: \(activationState.rawValue)")

            self?.isPhoneReachable = session.isReachable

            // アクティベート完了後、Application Contextからデータを読み込み
            self?.loadFromApplicationContext()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isPhoneReachable = session.isReachable

            print("[WatchConnectivity] Phone reachability changed: \(session.isReachable)")

            // iPhoneがリーチャブルになったら自動で同期リクエスト
            if session.isReachable {
                self?.requestAllDeliveries()
            }
        }
    }

    // メッセージ受信（リプライハンドラーあり）
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("[WatchConnectivity] Received message with reply handler")

        // 受信確認を返す
        replyHandler(["received": true, "timestamp": Date().timeIntervalSince1970])

        processReceivedMessage(message)
    }

    // メッセージ受信（リプライハンドラーなし）
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("[WatchConnectivity] Received message without reply handler")
        processReceivedMessage(message)
    }

    // Application Context受信
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("[WatchConnectivity] Received application context")

        guard let appContext = WatchApplicationContext(dictionary: applicationContext) else {
            print("[WatchConnectivity] Failed to parse application context")
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.deliveries = appContext.deliveries
            self?.activeDeliveryCount = appContext.activeDeliveryCount
            self?.deliveredCount = appContext.deliveredCount
            self?.lastSyncDate = appContext.lastSyncDate
            self?.syncState = .success

            // Complicationを更新
            self?.updateComplication(with: appContext.deliveries)

            print("[WatchConnectivity] Updated from application context: \(appContext.deliveries.count) deliveries")
        }
    }

    // MARK: - Private Helper

    /// 受信メッセージの処理
    private func processReceivedMessage(_ message: [String: Any]) {
        guard let typeString = message["type"] as? String,
              let messageType = WatchMessageType(rawValue: typeString) else {
            return
        }

        switch messageType {
        case .allDeliveriesResponse:
            handleDeliveriesResponse(message)

        case .deliveryUpdate:
            handleDeliveryUpdate(message)

        case .deliveryDeleted:
            handleDeliveryDeleted(message)

        case .statusRefreshComplete:
            handleRefreshResponse(message)

        case .heartbeat:
            print("[WatchConnectivity] Heartbeat received from iOS")

        default:
            break
        }
    }
}

// MARK: - Convenience Extensions

extension WatchConnectivityManager {

    /// アクティブな配達のみを取得
    var activeDeliveries: [WatchDeliveryData] {
        deliveries.filter { !$0.isDelivered }
    }

    /// 配達完了した配達のみを取得
    var completedDeliveries: [WatchDeliveryData] {
        deliveries.filter { $0.isDelivered }
    }

    /// 同期が必要か判定
    var needsSync: Bool {
        guard let lastSync = lastSyncDate else { return true }
        // 5分以上経過していたら同期が必要
        return Date().timeIntervalSince(lastSync) > 300
    }

    /// フォーマット済みの最終同期日時
    var formattedLastSyncDate: String {
        guard let date = lastSyncDate else { return "未同期" }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
