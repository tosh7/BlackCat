import Foundation
import SwiftUI

enum DeliveryCarrier: String, CaseIterable, Identifiable {
    case yamato = "ヤマト運輸"
    case sagawa = "佐川急便"
    case japanPost = "日本郵便"

    var id: String { self.rawValue }

    var displayName: String {
        return self.rawValue
    }

    var apiEndpoint: String {
        switch self {
        case .yamato:
            return "tneko"
        case .sagawa:
            return "sagawa"
        case .japanPost:
            return "japanpost"
        }
    }

    /// SF Symbol icon for the carrier
    var iconName: String {
        switch self {
        case .yamato:
            return "shippingbox.fill"
        case .sagawa:
            return "truck.box.fill"
        case .japanPost:
            return "envelope.fill"
        }
    }

    /// Brand color for the carrier
    var brandColor: Color {
        switch self {
        case .yamato:
            return Color(hex: "0x2C3E50") // Dark navy for Yamato
        case .sagawa:
            return Color(hex: "0x1E88E5") // Blue for Sagawa
        case .japanPost:
            return Color(hex: "0xCC0000") // Red for Japan Post
        }
    }

    /// Short description for the carrier
    var shortDescription: String {
        switch self {
        case .yamato:
            return "クロネコヤマト"
        case .sagawa:
            return "飛脚宅配便"
        case .japanPost:
            return "ゆうパック"
        }
    }

    /// Tracking number digit count
    var trackingNumberLength: Int {
        switch self {
        case .yamato:
            return 12
        case .sagawa:
            return 12
        case .japanPost:
            return 12
        }
    }

    /// Generate tracking URL for the carrier
    /// - Parameter trackingNumber: The tracking number to look up
    /// - Returns: URL for tracking the package on the carrier's website
    func trackingURL(for trackingNumber: String) -> URL? {
        let urlString: String
        switch self {
        case .yamato:
            urlString = "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko?number=\(trackingNumber)"
        case .sagawa:
            urlString = "https://k2k.sagawa-exp.co.jp/p/web/okurijosearch.do?okurijoNo=\(trackingNumber)"
        case .japanPost:
            urlString = "https://trackings.post.japanpost.jp/services/srv/search/?requestNo1=\(trackingNumber)"
        }
        return URL(string: urlString)
    }

    /// Base tracking URL for the carrier (without tracking number)
    var trackingBaseURL: String {
        switch self {
        case .yamato:
            return "https://toi.kuronekoyamato.co.jp/"
        case .sagawa:
            return "https://k2k.sagawa-exp.co.jp/"
        case .japanPost:
            return "https://trackings.post.japanpost.jp/"
        }
    }
}
