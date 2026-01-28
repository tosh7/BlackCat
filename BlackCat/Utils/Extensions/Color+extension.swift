import SwiftUI

extension Color {
    init(hex: String) {
        var color: UInt64 = 0
        var r: Double = 0, g: Double = 0, b: Double = 0
        if Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&color) {
            r = Double((color & 0xFF0000) >> 16) / 255.0
            g = Double((color & 0x00FF00) >>  8) / 255.0
            b = Double( color & 0x0000FF       ) / 255.0
        }
        self.init(red: r, green: g, blue: b)
    }
}

extension Color {
    struct BlackCat {
        // MARK: - Primary Colors
        // Main brand colors for the app
        static let primaryBlue = Color(hex: "0x4A90D9")
        static let primaryGreen = Color(hex: "0x50C878")
        static let primaryOrange = Color(hex: "0xFF9F43")
        static let primaryRed = Color(hex: "0xE74C3C")

        // MARK: - Pastel Colors (pure)
        // Soft pastel colors for backgrounds and cards
        static let pureGreen = Color(hex: "0x7fff7f")
        static let pureRed = Color(hex: "0xff7f7f")
        static let pureBlue = Color(hex: "0x7f7fff")
        static let purePurple = Color(hex: "0xbf7fff")
        static let pureYellow = Color(hex: "0xffff7f")
        static let pureOrange = Color(hex: "0xffbf7f")
        static let purePink = Color(hex: "0xff7fbf")

        // Legacy support
        static let pureYello = pureYellow

        // MARK: - Vivid Colors (natural)
        // High contrast colors for important UI elements
        static let naturalGreen = Color(hex: "0x2ECC71")
        static let naturalRed = Color(hex: "0xE74C3C")
        static let naturalBlue = Color(hex: "0x3498DB")
        static let naturalYellow = Color(hex: "0xF1C40F")
        static let naturalOrange = Color(hex: "0xE67E22")

        // MARK: - Status Colors
        // Colors representing delivery status
        static let statusReceived = Color(hex: "0x5DADE2")    // Light blue - received
        static let statusShipped = Color(hex: "0x9B59B6")     // Purple - shipped
        static let statusInTransit = Color(hex: "0xF39C12")   // Orange - in transit
        static let statusOutForDelivery = Color(hex: "0xE74C3C") // Red - out for delivery
        static let statusDelivered = Color(hex: "0x27AE60")   // Green - delivered

        // MARK: - Shadow/Monotone Colors
        // Grayscale colors for backgrounds and text
        // Level's number get larger, color get darker
        static let shadowLevel1 = Color(hex: "0xe0e0e0")
        static let shadowLevel2 = Color(hex: "0xc0c0c0")
        static let shadowLevel3 = Color(hex: "0xa0a0a0")
        static let shadowLevel4 = Color(hex: "0x808080")
        static let shadowLevel5 = Color(hex: "0x606060")
        static let shadowLevel6 = Color(hex: "0x404040")
        static let shadowLevel7 = Color(hex: "0x202020")

        // MARK: - Background Colors
        static let backgroundPrimary = Color(hex: "0x1A1A2E")
        static let backgroundSecondary = Color(hex: "0x16213E")
        static let backgroundCard = Color(hex: "0x0F3460")

        // MARK: - Accent Colors
        static let accentPrimary = Color(hex: "0xE94560")
        static let accentSecondary = Color(hex: "0x533483")

        // MARK: - Gradient Helpers
        static var primaryGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [primaryBlue, purePurple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var cardGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [backgroundCard, backgroundSecondary]),
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var successGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [naturalGreen, Color(hex: "0x1ABC9C")]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Animation Extensions
extension Animation {
    static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
    static let gentleEaseOut = Animation.easeOut(duration: 0.4)
    static let cardAppear = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
}
