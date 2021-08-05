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
        // pure is pastel color
        static let pureGreen = Color(hex: "0x7fff7f")
        static let pureRed = Color(hex: "0x#ff7f7f")
        static let pureBlue = Color(hex: "0x7f7fff")
        static let purePurple = Color(hex: "0xbf7fff")

        // natural is vivid color
        static let naturalGreen = Color(hex: "0x00ff00")
        static let naturalRed = Color(hex: "0xff3333")

        // shadow is monotone color
        // level's number get larger, color get darker
        static let shadowLevel1 = Color(hex: "0xe0e0e0")
        static let shadowLevel2 = Color(hex: "0xc0c0c0")
        static let shadowLevel3 = Color(hex: "0xa0a0a0")
        static let shadowLevel4 = Color(hex: "0x808080")
        static let shadowLevel5 = Color(hex: "0x606060")
        static let shadowLevel6 = Color(hex: "0x404040")
        static let shadowLevel7 = Color(hex: "0x202020")
    }
}
