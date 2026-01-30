//
//  WatchDeliveryData.swift
//  BlackCat
//
//  Apple Watch用の軽量配達データモデル
//  iOSとwatchOS間でのデータ同期に使用
//

import Foundation

// MARK: - Watch用配達データモデル

/// Apple Watch向けの軽量な配達情報
/// Codableプロトコルに対応し、WatchConnectivityでの転送に最適化
struct WatchDeliveryData: Codable, Identifiable, Equatable {
    let id: String
    let deliveryID: String
    let carrierName: String
    let carrierIcon: String
    let latestStatus: String
    let latestStatusType: String
    let latestDate: String
    let latestTime: String?
    let latestLocation: String
    let registeredDate: Date
    let isDelivered: Bool

    /// メンバーワイズイニシャライザ
    init(
        id: String,
        deliveryID: String,
        carrierName: String,
        carrierIcon: String,
        latestStatus: String,
        latestStatusType: String,
        latestDate: String,
        latestTime: String?,
        latestLocation: String,
        registeredDate: Date,
        isDelivered: Bool
    ) {
        self.id = id
        self.deliveryID = deliveryID
        self.carrierName = carrierName
        self.carrierIcon = carrierIcon
        self.latestStatus = latestStatus
        self.latestStatusType = latestStatusType
        self.latestDate = latestDate
        self.latestTime = latestTime
        self.latestLocation = latestLocation
        self.registeredDate = registeredDate
        self.isDelivered = isDelivered
    }

    /// ディクショナリからの初期化
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let deliveryID = dictionary["deliveryID"] as? String,
              let carrierName = dictionary["carrierName"] as? String,
              let carrierIcon = dictionary["carrierIcon"] as? String,
              let latestStatus = dictionary["latestStatus"] as? String,
              let latestStatusType = dictionary["latestStatusType"] as? String,
              let latestDate = dictionary["latestDate"] as? String,
              let latestLocation = dictionary["latestLocation"] as? String,
              let registeredTimestamp = dictionary["registeredDate"] as? TimeInterval,
              let isDelivered = dictionary["isDelivered"] as? Bool else {
            return nil
        }

        self.id = id
        self.deliveryID = deliveryID
        self.carrierName = carrierName
        self.carrierIcon = carrierIcon
        self.latestStatus = latestStatus
        self.latestStatusType = latestStatusType
        self.latestDate = latestDate
        self.latestTime = dictionary["latestTime"] as? String
        self.latestLocation = latestLocation
        self.registeredDate = Date(timeIntervalSince1970: registeredTimestamp)
        self.isDelivered = isDelivered
    }

    /// ディクショナリへの変換
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "deliveryID": deliveryID,
            "carrierName": carrierName,
            "carrierIcon": carrierIcon,
            "latestStatus": latestStatus,
            "latestStatusType": latestStatusType,
            "latestDate": latestDate,
            "latestLocation": latestLocation,
            "registeredDate": registeredDate.timeIntervalSince1970,
            "isDelivered": isDelivered
        ]

        if let latestTime = latestTime {
            dict["latestTime"] = latestTime
        }

        return dict
    }
}

// MARK: - Watch同期メッセージタイプ

/// iOS-Watch間の通信メッセージタイプ
enum WatchMessageType: String, Codable {
    /// 全配達データのリクエスト
    case requestAllDeliveries = "request_all_deliveries"
    /// 全配達データの応答
    case allDeliveriesResponse = "all_deliveries_response"
    /// 単一配達の更新
    case deliveryUpdate = "delivery_update"
    /// 配達データの削除
    case deliveryDeleted = "delivery_deleted"
    /// ステータス更新リクエスト
    case requestStatusRefresh = "request_status_refresh"
    /// ステータス更新完了通知
    case statusRefreshComplete = "status_refresh_complete"
    /// エラー通知
    case error = "error"
    /// ハートビート（接続確認）
    case heartbeat = "heartbeat"
}

// MARK: - Watch同期メッセージ

/// iOS-Watch間で交換するメッセージ
struct WatchSyncMessage: Codable {
    let type: WatchMessageType
    let timestamp: Date
    let payload: Data?

    init(type: WatchMessageType, payload: Data? = nil) {
        self.type = type
        self.timestamp = Date()
        self.payload = payload
    }

    /// ディクショナリからの初期化
    init?(dictionary: [String: Any]) {
        guard let typeString = dictionary["type"] as? String,
              let type = WatchMessageType(rawValue: typeString),
              let timestamp = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }

        self.type = type
        self.timestamp = Date(timeIntervalSince1970: timestamp)
        self.payload = dictionary["payload"] as? Data
    }

    /// ディクショナリへの変換
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": type.rawValue,
            "timestamp": timestamp.timeIntervalSince1970
        ]

        if let payload = payload {
            dict["payload"] = payload
        }

        return dict
    }
}

// MARK: - 同期エラー

/// Watch同期に関するエラー
enum WatchSyncError: Error, LocalizedError {
    case sessionNotSupported
    case sessionNotActivated
    case watchNotReachable
    case encodingFailed
    case decodingFailed
    case transferFailed(String)
    case timeout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .sessionNotSupported:
            return "このデバイスはWatch Connectivityをサポートしていません"
        case .sessionNotActivated:
            return "Watch Connectivityセッションがアクティブではありません"
        case .watchNotReachable:
            return "Apple Watchに接続できません"
        case .encodingFailed:
            return "データのエンコードに失敗しました"
        case .decodingFailed:
            return "データのデコードに失敗しました"
        case .transferFailed(let message):
            return "データ転送に失敗しました: \(message)"
        case .timeout:
            return "通信がタイムアウトしました"
        case .unknown(let message):
            return "不明なエラー: \(message)"
        }
    }
}

// MARK: - 同期状態

/// Watch同期の状態
enum WatchSyncState: Equatable {
    case idle
    case syncing
    case success
    case error(String)

    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }
}

// MARK: - ユーザーコンテキスト

/// バックグラウンドで同期されるアプリケーションコンテキスト
struct WatchApplicationContext: Codable {
    let lastSyncDate: Date
    let activeDeliveryCount: Int
    let deliveredCount: Int
    let deliveries: [WatchDeliveryData]

    /// ディクショナリへの変換
    func toDictionary() -> [String: Any] {
        return [
            "lastSyncDate": lastSyncDate.timeIntervalSince1970,
            "activeDeliveryCount": activeDeliveryCount,
            "deliveredCount": deliveredCount,
            "deliveries": deliveries.map { $0.toDictionary() }
        ]
    }

    /// ディクショナリからの初期化
    init?(dictionary: [String: Any]) {
        guard let lastSyncTimestamp = dictionary["lastSyncDate"] as? TimeInterval,
              let activeDeliveryCount = dictionary["activeDeliveryCount"] as? Int,
              let deliveredCount = dictionary["deliveredCount"] as? Int,
              let deliveriesArray = dictionary["deliveries"] as? [[String: Any]] else {
            return nil
        }

        self.lastSyncDate = Date(timeIntervalSince1970: lastSyncTimestamp)
        self.activeDeliveryCount = activeDeliveryCount
        self.deliveredCount = deliveredCount
        self.deliveries = deliveriesArray.compactMap { WatchDeliveryData(dictionary: $0) }
    }

    init(lastSyncDate: Date, activeDeliveryCount: Int, deliveredCount: Int, deliveries: [WatchDeliveryData]) {
        self.lastSyncDate = lastSyncDate
        self.activeDeliveryCount = activeDeliveryCount
        self.deliveredCount = deliveredCount
        self.deliveries = deliveries
    }
}
