import Foundation

/// Helper struct to generate shareable content for delivery items
struct DeliveryShareContent {
    let deliveryItem: DeliveryItem

    /// Generate shareable text content for the delivery item
    var shareText: String {
        var text = "荷物追跡情報\n"
        text += "━━━━━━━━━━━━━━━\n\n"

        // Tracking number
        text += "伝票番号: \(deliveryItem.deliveryID)\n"

        // Carrier
        text += "配送業者: \(deliveryItem.carrier.displayName)\n"

        // Current status
        if let latestStatus = deliveryItem.statusList.last {
            text += "現在の状態: \(latestStatus.status)\n"

            // Date and time
            var dateTimeText = "更新日時: \(latestStatus.date)"
            if let time = latestStatus.time {
                dateTimeText += " \(time)"
            }
            text += dateTimeText + "\n"

            // Location
            if !latestStatus.shopName.isEmpty {
                text += "場所: \(latestStatus.shopName)\n"
            }
        }

        text += "\n"

        // Tracking URL
        if let trackingURL = deliveryItem.carrier.trackingURL(for: String(deliveryItem.deliveryID)) {
            text += "追跡URL:\n\(trackingURL.absoluteString)\n"
        }

        text += "\n━━━━━━━━━━━━━━━"

        return text
    }

    /// Generate a shorter shareable text for quick sharing
    var shortShareText: String {
        var text = "【荷物追跡】\n"
        text += "\(deliveryItem.carrier.displayName): \(deliveryItem.deliveryID)\n"

        if let latestStatus = deliveryItem.statusList.last {
            text += "状態: \(latestStatus.status)\n"
        }

        if let trackingURL = deliveryItem.carrier.trackingURL(for: String(deliveryItem.deliveryID)) {
            text += trackingURL.absoluteString
        }

        return text
    }

    /// Get the tracking URL for the delivery item
    var trackingURL: URL? {
        deliveryItem.carrier.trackingURL(for: String(deliveryItem.deliveryID))
    }
}
