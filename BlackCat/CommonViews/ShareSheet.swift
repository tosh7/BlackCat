import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIActivityViewController to share content
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

/// A modifier to present a share sheet
struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ShareSheet(items: items)
            }
    }
}

extension View {
    /// Present a share sheet with the specified items
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - items: Items to share
    /// - Returns: Modified view with share sheet capability
    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        modifier(ShareSheetModifier(isPresented: isPresented, items: items))
    }
}
