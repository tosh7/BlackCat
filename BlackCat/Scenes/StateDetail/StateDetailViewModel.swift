import Foundation

final class StateDetailViewModel: ObservableObject {
    @Published var showingAlert: Bool = false
    @Published var showConfetti: Bool = false

    private let userDefaults: UserDefaults
    private let confettiShownKey = "confetti_shown_for_delivery_"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func deleteDeliveryItem(id: Int) {
        showingAlert = true
        LocalDeliveryItems.shared.remove(id: id)
    }

    /// Checks if confetti should be shown for a delivered item
    /// - Parameters:
    ///   - deliveryID: The delivery ID to check
    ///   - isDelivered: Whether the delivery status is "delivered"
    func checkAndShowConfetti(for deliveryID: Int, isDelivered: Bool) {
        guard isDelivered else { return }
        guard SettingsManager.shared.confettiEnabled else { return }

        let key = confettiShownKey + String(deliveryID)

        // Only show confetti if not already shown for this delivery
        if !userDefaults.bool(forKey: key) {
            userDefaults.set(true, forKey: key)
            showConfetti = true

            // Trigger success haptic
            HapticManager.shared.success()
        }
    }

    /// Clears confetti shown state for a delivery (for testing purposes)
    func clearConfettiState(for deliveryID: Int) {
        let key = confettiShownKey + String(deliveryID)
        userDefaults.removeObject(forKey: key)
    }
}
