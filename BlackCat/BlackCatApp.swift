import SwiftUI
import Domain

let apiClient = ApiClient.shared

@main
struct BlackCatApp: App {
    var body: some Scene {
        WindowGroup {
            DeliveryListView()
        }
    }
}
