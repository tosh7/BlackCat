import SwiftUI

enum DeliveryStatusType {
    case received
    case sended
    case delivering
    case delivered

    var color: Color {
        switch self {
        case .received:
            return .green
        case .sended:
            return .blue
        case .delivering:
            return .red
        case .delivered:
            return .gray
        }
    }
}
