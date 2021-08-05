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
