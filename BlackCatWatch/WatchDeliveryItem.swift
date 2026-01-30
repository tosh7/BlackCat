//
//  WatchDeliveryItem.swift
//  BlackCatWatch
//
//  watchOS用の配達アイテム表示モデル
//  WatchDeliveryDataをwatchOS UIで使いやすい形に拡張
//

import SwiftUI

// MARK: - WatchDeliveryItem

/// watchOS UI表示用の配達アイテム
/// WatchDeliveryDataのラッパーとして機能し、watchOS固有のUI情報を提供
struct WatchDeliveryItem: Identifiable, Equatable {
    let id: String
    let deliveryData: WatchDeliveryData

    init(from data: WatchDeliveryData) {
        self.id = data.id
        self.deliveryData = data
    }

    // MARK: - Convenience Properties

    var deliveryID: Int { deliveryData.deliveryID }
    var carrierName: String { deliveryData.carrierName }
    var latestStatus: String { deliveryData.latestStatus }
    var latestDate: String { deliveryData.latestDate }
    var latestTime: String? { deliveryData.latestTime }
    var latestLocation: String { deliveryData.latestLocation }
    var isDelivered: Bool { deliveryData.isDelivered }
    var registeredDate: Date { deliveryData.registeredDate }

    /// 伝票番号の文字列表現
    var trackingNumberString: String {
        String(deliveryData.deliveryID)
    }

    /// 日時のフォーマット済み表示
    var formattedDateTime: String {
        if let time = latestTime {
            return "\(latestDate) \(time)"
        }
        return latestDate
    }
}

// MARK: - Array Extension

extension Array where Element == WatchDeliveryData {
    /// WatchDeliveryDataの配列をWatchDeliveryItemの配列に変換
    func toWatchDeliveryItems() -> [WatchDeliveryItem] {
        map { WatchDeliveryItem(from: $0) }
    }
}
