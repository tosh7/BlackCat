//
//  WatchConnectivityManager.swift
//  BlackCat
//
//  iOS側のWatch Connectivity管理クラス
//  Apple Watchとの配達データ同期を担当
//

import Foundation
import WatchConnectivity
import Combine

// MARK: - iOS側 WatchConnectivityManager

/// iOSアプリ側のWatch Connectivity管理クラス
/// シングルトンパターンで実装し、アプリ全体で共有
final class WatchConnectivityManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties

    /// 同期状態
    @Published private(set) var syncState: WatchSyncState = .idle

    /// Apple Watchが接続されているか
    @Published private(set) var isWatchConnected: Bool = false

    /// Apple Watchがリーチャブルか（即時通信可能か）
    @Published private(set) var isWatchReachable: Bool = false

    /// Apple Watchアプリがインストールされているか
    @Published private(set) var isWatchAppInstalled: Bool = false

    /// 最後の同期日時
    @Published private(set) var lastSyncDate: Date?

    // MARK: - Private Properties

    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()

    /// データ取得用のコールバック
    private var deliveryDataProvider: (() -> [WatchDeliveryData])?

    /// ステータス更新リクエスト用のコールバック
    private var statusRefreshHandler: ((@escaping (Bool) -> Void) -> Void)?

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

        print("[WatchConnectivity] iOS session setup completed")
    }

    // MARK: - Public Methods

    /// 配達データプロバイダーを設定
    /// - Parameter provider: 配達データを返すクロージャ
    func setDeliveryDataProvider(_ provider: @escaping () -> [WatchDeliveryData]) {
        self.deliveryDataProvider = provider
    }

    /// ステータス更新ハンドラーを設定
    /// - Parameter handler: 更新リクエストを処理するクロージャ
    func setStatusRefreshHandler(_ handler: @escaping (@escaping (Bool) -> Void) -> Void) {
        self.statusRefreshHandler = handler
    }

    /// Apple Watchに配達データを送信
    /// - Parameter deliveries: 送信する配達データ
    func sendDeliveries(_ deliveries: [WatchDeliveryData]) {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated")
            DispatchQueue.main.async { [weak self] in
                self?.syncState = .error(WatchSyncError.sessionNotActivated.localizedDescription)
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.syncState = .syncing
        }

        // Application Contextを使用してバックグラウンドでも同期
        let activeCount = deliveries.filter { !$0.isDelivered }.count
        let deliveredCount = deliveries.filter { $0.isDelivered }.count

        let context = WatchApplicationContext(
            lastSyncDate: Date(),
            activeDeliveryCount: activeCount,
            deliveredCount: deliveredCount,
            deliveries: deliveries
        )

        do {
            try session.updateApplicationContext(context.toDictionary())
            DispatchQueue.main.async { [weak self] in
                self?.lastSyncDate = Date()
                self?.syncState = .success
            }

            print("[WatchConnectivity] Application context updated with \(deliveries.count) deliveries")
        } catch {
            print("[WatchConnectivity] Failed to update application context: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.syncState = .error(error.localizedDescription)
            }
        }

        // Watchがリーチャブルならメッセージも送信（即時反映のため）
        if session.isReachable {
            sendMessageToWatch(deliveries: deliveries)
        }
    }

    /// 単一の配達データ更新を送信
    /// - Parameter delivery: 更新する配達データ
    func sendDeliveryUpdate(_ delivery: WatchDeliveryData) {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else {
            // リーチャブルでない場合はApplication Contextで同期
            if let deliveries = deliveryDataProvider?() {
                sendDeliveries(deliveries)
            }
            return
        }

        do {
            let data = try JSONEncoder().encode(delivery)
            let message: [String: Any] = [
                "type": WatchMessageType.deliveryUpdate.rawValue,
                "timestamp": Date().timeIntervalSince1970,
                "payload": data
            ]

            session.sendMessage(message, replyHandler: nil) { error in
                print("[WatchConnectivity] Failed to send delivery update: \(error)")
            }

            print("[WatchConnectivity] Delivery update sent for ID: \(delivery.deliveryID)")
        } catch {
            print("[WatchConnectivity] Failed to encode delivery data: \(error)")
        }
    }

    /// 配達削除通知を送信
    /// - Parameter deliveryID: 削除された配達ID
    func sendDeliveryDeleted(deliveryID: String) {
        guard let session = session,
              session.activationState == .activated else {
            return
        }

        let message: [String: Any] = [
            "type": WatchMessageType.deliveryDeleted.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "deliveryID": deliveryID
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("[WatchConnectivity] Failed to send deletion notification: \(error)")
            }
        }

        // Application Contextも更新
        if let deliveries = deliveryDataProvider?() {
            sendDeliveries(deliveries)
        }

        print("[WatchConnectivity] Delivery deletion notification sent for ID: \(deliveryID)")
    }

    /// 手動で同期を実行
    func syncNow() {
        let deliveries: [WatchDeliveryData]?
        // deliveryDataProviderはDeliveryListViewModelのdeliveryListにアクセスするためメインスレッドで実行
        if Thread.isMainThread {
            deliveries = deliveryDataProvider?()
        } else {
            deliveries = DispatchQueue.main.sync { deliveryDataProvider?() }
        }

        guard let deliveries else {
            print("[WatchConnectivity] No delivery data provider set")
            return
        }

        sendDeliveries(deliveries)
    }

    // MARK: - Private Methods

    /// メッセージでWatchに配達データを送信
    private func sendMessageToWatch(deliveries: [WatchDeliveryData]) {
        guard let session = session, session.isReachable else {
            return
        }

        do {
            let data = try JSONEncoder().encode(deliveries)
            let message: [String: Any] = [
                "type": WatchMessageType.allDeliveriesResponse.rawValue,
                "timestamp": Date().timeIntervalSince1970,
                "payload": data
            ]

            session.sendMessage(message, replyHandler: { reply in
                print("[WatchConnectivity] Watch acknowledged receipt")
            }) { error in
                print("[WatchConnectivity] Failed to send message: \(error)")
            }
        } catch {
            print("[WatchConnectivity] Failed to encode deliveries: \(error)")
        }
    }

    /// Watchからのリクエストを処理
    private func handleWatchRequest(message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let typeString = message["type"] as? String,
              let messageType = WatchMessageType(rawValue: typeString) else {
            replyHandler(["error": "Invalid message type"])
            return
        }

        switch messageType {
        case .requestAllDeliveries:
            handleAllDeliveriesRequest(replyHandler: replyHandler)

        case .requestStatusRefresh:
            handleStatusRefreshRequest(replyHandler: replyHandler)

        case .heartbeat:
            replyHandler([
                "type": WatchMessageType.heartbeat.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])

        default:
            replyHandler(["error": "Unsupported message type"])
        }
    }

    /// 全配達データリクエストの処理
    private func handleAllDeliveriesRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        // deliveryDataProviderはDeliveryListViewModelにアクセスするためメインスレッドで実行
        DispatchQueue.main.async { [weak self] in
            guard let self, let deliveries = self.deliveryDataProvider?() else {
                replyHandler([
                    "type": WatchMessageType.error.rawValue,
                    "error": "No delivery data available"
                ])
                return
            }

            do {
                let data = try JSONEncoder().encode(deliveries)
                replyHandler([
                    "type": WatchMessageType.allDeliveriesResponse.rawValue,
                    "timestamp": Date().timeIntervalSince1970,
                    "payload": data
                ])

                print("[WatchConnectivity] Sent \(deliveries.count) deliveries to Watch")
            } catch {
                replyHandler([
                    "type": WatchMessageType.error.rawValue,
                    "error": error.localizedDescription
                ])
            }
        }
    }

    /// ステータス更新リクエストの処理
    private func handleStatusRefreshRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        guard let refreshHandler = statusRefreshHandler else {
            replyHandler([
                "type": WatchMessageType.error.rawValue,
                "error": "Refresh handler not configured"
            ])
            return
        }

        refreshHandler { [weak self] success in
            if success {
                // 更新成功、最新データをメインスレッドで取得して返す
                DispatchQueue.main.async {
                    guard let deliveries = self?.deliveryDataProvider?() else {
                        replyHandler([
                            "type": WatchMessageType.error.rawValue,
                            "error": "No delivery data available"
                        ])
                        return
                    }
                    do {
                        let data = try JSONEncoder().encode(deliveries)
                        replyHandler([
                            "type": WatchMessageType.statusRefreshComplete.rawValue,
                            "timestamp": Date().timeIntervalSince1970,
                            "payload": data
                        ])
                    } catch {
                        replyHandler([
                            "type": WatchMessageType.error.rawValue,
                            "error": error.localizedDescription
                        ])
                    }
                }
            } else {
                replyHandler([
                    "type": WatchMessageType.error.rawValue,
                    "error": "Refresh failed"
                ])
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("[WatchConnectivity] Activation failed: \(error)")
                self?.syncState = .error(error.localizedDescription)
                return
            }

            print("[WatchConnectivity] Session activated with state: \(activationState.rawValue)")

            self?.isWatchConnected = session.isPaired
            self?.isWatchAppInstalled = session.isWatchAppInstalled
            self?.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WatchConnectivity] Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[WatchConnectivity] Session deactivated")
        // 再アクティベート
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isWatchConnected = session.isPaired
            self?.isWatchAppInstalled = session.isWatchAppInstalled
            self?.isWatchReachable = session.isReachable

            print("[WatchConnectivity] Watch state changed - Paired: \(session.isPaired), Installed: \(session.isWatchAppInstalled), Reachable: \(session.isReachable)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isWatchReachable = session.isReachable

            print("[WatchConnectivity] Reachability changed: \(session.isReachable)")

            // リーチャブルになったら自動同期
            if session.isReachable {
                self?.syncNow()
            }
        }
    }

    // メッセージ受信（リプライハンドラーあり）
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("[WatchConnectivity] Received message with reply handler")
        handleWatchRequest(message: message, replyHandler: replyHandler)
    }

    // メッセージ受信（リプライハンドラーなし）
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("[WatchConnectivity] Received message without reply handler")

        guard let typeString = message["type"] as? String,
              let messageType = WatchMessageType(rawValue: typeString) else {
            return
        }

        switch messageType {
        case .heartbeat:
            print("[WatchConnectivity] Heartbeat received from Watch")
        default:
            break
        }
    }

    // Application Context受信
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("[WatchConnectivity] Received application context from Watch")
        // Watchからのコンテキスト更新があれば処理（通常はWatchへの送信のみ）
    }

    // ユーザー情報転送完了
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if let error = error {
            print("[WatchConnectivity] User info transfer failed: \(error)")
        } else {
            print("[WatchConnectivity] User info transfer completed")
        }
    }
}

// MARK: - DeliveryItem Extension

/// DeliveryItemからWatchDeliveryDataへの変換
extension WatchDeliveryData {
    /// DeliveryItemから初期化（iOS側で使用）
    /// 注: この初期化子はiOSアプリ側でのみ使用
    init(from item: DeliveryItem, carrier: DeliveryCarrier) {
        self.id = item.id.uuidString
        self.deliveryID = String(item.deliveryID)
        self.carrierName = carrier.displayName
        self.carrierIcon = carrier.iconName
        self.latestStatus = item.latestStatus?.status ?? "不明"
        self.latestStatusType = item.latestStatusType.map { String(describing: $0) } ?? "unknown"
        self.latestDate = item.latestStatus?.date ?? ""
        self.latestTime = item.latestStatus?.time
        self.latestLocation = item.latestStatus?.shopName ?? ""
        self.registeredDate = item.registeredDate
        self.isDelivered = item.latestStatusType == .delivered
    }
}
