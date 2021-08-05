import SwiftUI

enum DeliveryStatusType {
    case received
    case sended
    case delivering
    case delivered

    var color: Color {
        switch self {
        case .received:
            return Color.BlackCat.pureBlue
        case .sended:
            return Color.BlackCat.purePink
        case .delivering:
            return Color.BlackCat.pureOrange
        case .delivered:
            return Color.BlackCat.shadowLevel6
        }
    }
}
