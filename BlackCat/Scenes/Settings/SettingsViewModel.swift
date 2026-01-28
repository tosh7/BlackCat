import Foundation
import Combine

// MARK: - Settings Keys
enum SettingsKey: String {
    case statusUpdateNotification = "settings_status_update_notification"
    case deliveryCompletedNotification = "settings_delivery_completed_notification"
    case defaultCarrier = "settings_default_carrier"
    case listSortOrder = "settings_list_sort_order"
    case autoDeleteDays = "settings_auto_delete_days"
    case hapticEnabled = "settings_haptic_enabled"
    case confettiEnabled = "settings_confetti_enabled"
}

// MARK: - Sort Order
enum ListSortOrder: String, CaseIterable, Identifiable {
    case newestFirst = "newest_first"
    case oldestFirst = "oldest_first"
    case byStatus = "by_status"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .newestFirst:
            return "新しい順"
        case .oldestFirst:
            return "古い順"
        case .byStatus:
            return "ステータス順"
        }
    }
}

// MARK: - Auto Delete Options
enum AutoDeleteOption: Int, CaseIterable, Identifiable {
    case never = 0
    case days7 = 7
    case days14 = 14
    case days30 = 30
    case days60 = 60

    var id: Int { self.rawValue }

    var displayName: String {
        switch self {
        case .never:
            return "自動削除しない"
        case .days7:
            return "7日後"
        case .days14:
            return "14日後"
        case .days30:
            return "30日後"
        case .days60:
            return "60日後"
        }
    }
}

// MARK: - ViewModel Protocol
protocol SettingsViewModelInputs {
    func setStatusUpdateNotification(_ enabled: Bool)
    func setDeliveryCompletedNotification(_ enabled: Bool)
    func setDefaultCarrier(_ carrier: DeliveryCarrier)
    func setListSortOrder(_ order: ListSortOrder)
    func setAutoDeleteDays(_ option: AutoDeleteOption)
    func setHapticEnabled(_ enabled: Bool)
    func setConfettiEnabled(_ enabled: Bool)
    func deleteAllData()
}

protocol SettingsViewModelOutputs {
    var statusUpdateNotificationEnabled: Bool { get }
    var deliveryCompletedNotificationEnabled: Bool { get }
    var defaultCarrier: DeliveryCarrier { get }
    var listSortOrder: ListSortOrder { get }
    var autoDeleteOption: AutoDeleteOption { get }
    var hapticEnabled: Bool { get }
    var confettiEnabled: Bool { get }
    var appVersion: String { get }
}

protocol SettingsViewModelType {
    var input: SettingsViewModelInputs { get }
    var output: SettingsViewModelOutputs { get }
}

// MARK: - ViewModel Implementation
final class SettingsViewModel: ObservableObject, SettingsViewModelType, SettingsViewModelInputs, SettingsViewModelOutputs {

    private let userDefaults: UserDefaults
    private let notificationManager = NotificationManager.shared

    // MARK: - Published Properties
    @Published var statusUpdateNotificationEnabled: Bool {
        didSet {
            userDefaults.set(statusUpdateNotificationEnabled, forKey: SettingsKey.statusUpdateNotification.rawValue)
        }
    }

    @Published var deliveryCompletedNotificationEnabled: Bool {
        didSet {
            userDefaults.set(deliveryCompletedNotificationEnabled, forKey: SettingsKey.deliveryCompletedNotification.rawValue)
        }
    }

    @Published var defaultCarrier: DeliveryCarrier {
        didSet {
            userDefaults.set(defaultCarrier.rawValue, forKey: SettingsKey.defaultCarrier.rawValue)
        }
    }

    @Published var listSortOrder: ListSortOrder {
        didSet {
            userDefaults.set(listSortOrder.rawValue, forKey: SettingsKey.listSortOrder.rawValue)
        }
    }

    @Published var autoDeleteOption: AutoDeleteOption {
        didSet {
            userDefaults.set(autoDeleteOption.rawValue, forKey: SettingsKey.autoDeleteDays.rawValue)
        }
    }

    @Published var hapticEnabled: Bool {
        didSet {
            userDefaults.set(hapticEnabled, forKey: SettingsKey.hapticEnabled.rawValue)
            HapticManager.shared.isHapticEnabled = hapticEnabled
        }
    }

    @Published var confettiEnabled: Bool {
        didSet {
            userDefaults.set(confettiEnabled, forKey: SettingsKey.confettiEnabled.rawValue)
        }
    }

    @Published var showDeleteConfirmation: Bool = false
    @Published var showDeleteSuccessAlert: Bool = false

    // MARK: - App Info
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load saved settings or use defaults
        self.statusUpdateNotificationEnabled = userDefaults.object(forKey: SettingsKey.statusUpdateNotification.rawValue) as? Bool ?? true
        self.deliveryCompletedNotificationEnabled = userDefaults.object(forKey: SettingsKey.deliveryCompletedNotification.rawValue) as? Bool ?? true

        if let carrierRaw = userDefaults.string(forKey: SettingsKey.defaultCarrier.rawValue),
           let carrier = DeliveryCarrier(rawValue: carrierRaw) {
            self.defaultCarrier = carrier
        } else {
            self.defaultCarrier = .yamato
        }

        if let sortOrderRaw = userDefaults.string(forKey: SettingsKey.listSortOrder.rawValue),
           let sortOrder = ListSortOrder(rawValue: sortOrderRaw) {
            self.listSortOrder = sortOrder
        } else {
            self.listSortOrder = .newestFirst
        }

        let autoDeleteDays = userDefaults.integer(forKey: SettingsKey.autoDeleteDays.rawValue)
        self.autoDeleteOption = AutoDeleteOption(rawValue: autoDeleteDays) ?? .never

        // Haptic設定を読み込み（デフォルトはtrue）
        if userDefaults.object(forKey: SettingsKey.hapticEnabled.rawValue) != nil {
            self.hapticEnabled = userDefaults.bool(forKey: SettingsKey.hapticEnabled.rawValue)
        } else {
            self.hapticEnabled = true
        }
        HapticManager.shared.isHapticEnabled = self.hapticEnabled

        // Confetti設定を読み込み（デフォルトはtrue）
        if userDefaults.object(forKey: SettingsKey.confettiEnabled.rawValue) != nil {
            self.confettiEnabled = userDefaults.bool(forKey: SettingsKey.confettiEnabled.rawValue)
        } else {
            self.confettiEnabled = true
        }
    }

    // MARK: - Input Methods
    func setStatusUpdateNotification(_ enabled: Bool) {
        statusUpdateNotificationEnabled = enabled
        if enabled {
            notificationManager.requestAuthorization()
        }
    }

    func setDeliveryCompletedNotification(_ enabled: Bool) {
        deliveryCompletedNotificationEnabled = enabled
        if enabled {
            notificationManager.requestAuthorization()
        }
    }

    func setDefaultCarrier(_ carrier: DeliveryCarrier) {
        defaultCarrier = carrier
    }

    func setListSortOrder(_ order: ListSortOrder) {
        listSortOrder = order
    }

    func setAutoDeleteDays(_ option: AutoDeleteOption) {
        autoDeleteOption = option
    }

    func setHapticEnabled(_ enabled: Bool) {
        hapticEnabled = enabled
        // 設定変更時にフィードバックを実行（有効にした場合のみ）
        if enabled {
            HapticManager.shared.selection()
        }
    }

    func setConfettiEnabled(_ enabled: Bool) {
        confettiEnabled = enabled
    }

    func deleteAllData() {
        // Clear all delivery items
        let localItems = LocalDeliveryItems.shared
        for item in localItems.items {
            localItems.remove(id: item)
        }

        // Cancel all notifications
        notificationManager.cancelAllNotifications()
        notificationManager.clearBadge()

        showDeleteSuccessAlert = true
    }

    // MARK: - Protocol Conformance
    var input: SettingsViewModelInputs { return self }
    var output: SettingsViewModelOutputs { return self }
}

// MARK: - Settings Manager (Global Access)
final class SettingsManager {
    static let shared = SettingsManager()

    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var statusUpdateNotificationEnabled: Bool {
        return userDefaults.object(forKey: SettingsKey.statusUpdateNotification.rawValue) as? Bool ?? true
    }

    var deliveryCompletedNotificationEnabled: Bool {
        return userDefaults.object(forKey: SettingsKey.deliveryCompletedNotification.rawValue) as? Bool ?? true
    }

    var defaultCarrier: DeliveryCarrier {
        if let carrierRaw = userDefaults.string(forKey: SettingsKey.defaultCarrier.rawValue),
           let carrier = DeliveryCarrier(rawValue: carrierRaw) {
            return carrier
        }
        return .yamato
    }

    var listSortOrder: ListSortOrder {
        if let sortOrderRaw = userDefaults.string(forKey: SettingsKey.listSortOrder.rawValue),
           let sortOrder = ListSortOrder(rawValue: sortOrderRaw) {
            return sortOrder
        }
        return .newestFirst
    }

    var autoDeleteDays: Int {
        return userDefaults.integer(forKey: SettingsKey.autoDeleteDays.rawValue)
    }

    var confettiEnabled: Bool {
        if userDefaults.object(forKey: SettingsKey.confettiEnabled.rawValue) != nil {
            return userDefaults.bool(forKey: SettingsKey.confettiEnabled.rawValue)
        }
        return true // Default is enabled
    }
}
