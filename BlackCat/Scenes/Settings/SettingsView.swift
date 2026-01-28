import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var backgroundRefreshManager = BackgroundRefreshManager.shared
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var showingBackgroundRefreshAlert = false

    var body: some View {
        ZStack {
            Color.BlackCat.backgroundPrimary
                .edgesIgnoringSafeArea(.all)

            Form {
                // MARK: - Background Refresh Settings
                backgroundRefreshSection

                // MARK: - Notification Settings
                notificationSection

                // MARK: - Display Settings
                displaySection

                // MARK: - Data Management
                dataManagementSection

                // MARK: - App Information
                appInfoSection
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
        .alert("データ削除", isPresented: $viewModel.showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("削除する", role: .destructive) {
                viewModel.deleteAllData()
                HapticManager.shared.success()
            }
        } message: {
            Text("全ての配達データを削除しますか？\nこの操作は取り消せません。")
        }
        .alert("削除完了", isPresented: $viewModel.showDeleteSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("全てのデータが削除されました。")
        }
        .alert("バックグラウンド更新が無効です", isPresented: $showingBackgroundRefreshAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("バックグラウンド更新を使用するには、設定アプリでこのアプリのバックグラウンド更新を許可してください。")
        }
    }

    // MARK: - Background Refresh Section
    private var backgroundRefreshSection: some View {
        Section {
            // バックグラウンド更新のON/OFF
            Toggle(isOn: $backgroundRefreshManager.isEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("バックグラウンド更新")
                            .foregroundColor(.white)
                        Text("アプリを閉じても定期的に更新")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                } icon: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(Color.BlackCat.primaryBlue)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.BlackCat.accentPrimary))
            .listRowBackground(Color.BlackCat.backgroundCard)
            .onChange(of: backgroundRefreshManager.isEnabled) { newValue in
                if newValue && !backgroundRefreshManager.isBackgroundRefreshAvailable {
                    showingBackgroundRefreshAlert = true
                    backgroundRefreshManager.isEnabled = false
                }
            }

            // 更新間隔の選択
            if backgroundRefreshManager.isEnabled {
                HStack {
                    Label {
                        Text("更新間隔")
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color.BlackCat.primaryOrange)
                    }

                    Spacer()

                    Picker("", selection: $backgroundRefreshManager.refreshInterval) {
                        ForEach(BackgroundRefreshInterval.allCases) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(Color.BlackCat.accentPrimary)
                }
                .listRowBackground(Color.BlackCat.backgroundCard)

                // 最後の更新日時
                if let lastRefresh = backgroundRefreshManager.lastRefreshDate {
                    HStack {
                        Label {
                            Text("最終更新")
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(Color.BlackCat.shadowLevel3)
                        }

                        Spacer()

                        Text(formatDate(lastRefresh))
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                    .listRowBackground(Color.BlackCat.backgroundCard)
                }

                // システム設定の状態
                HStack {
                    Label {
                        Text("システム設定")
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: backgroundRefreshStatusIcon)
                            .foregroundColor(backgroundRefreshStatusColor)
                    }

                    Spacer()

                    Text(backgroundRefreshStatusText)
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                }
                .listRowBackground(Color.BlackCat.backgroundCard)

                // 低電力モードの警告
                if ProcessInfo.processInfo.isLowPowerModeEnabled {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("低電力モード")
                                    .foregroundColor(.white)
                                Text("更新間隔が自動的に延長されます")
                                    .font(.caption)
                                    .foregroundColor(Color.BlackCat.naturalYellow)
                            }
                        } icon: {
                            Image(systemName: "battery.25")
                                .foregroundColor(Color.BlackCat.naturalYellow)
                        }

                        Spacer()

                        Text("オン")
                            .foregroundColor(Color.BlackCat.naturalYellow)
                    }
                    .listRowBackground(Color.BlackCat.backgroundCard)
                }
            }
        } header: {
            sectionHeader(title: "バックグラウンド更新", icon: "arrow.clockwise")
        } footer: {
            Text("バックグラウンド更新を有効にすると、アプリを閉じていても定期的に配達状況をチェックし、変更があれば通知でお知らせします。")
                .foregroundColor(Color.BlackCat.shadowLevel4)
        }
    }

    // MARK: - Background Refresh Helpers
    private var backgroundRefreshStatusIcon: String {
        switch backgroundRefreshManager.checkBackgroundRefreshStatus() {
        case .available:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .restricted:
            return "exclamationmark.triangle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    private var backgroundRefreshStatusColor: Color {
        switch backgroundRefreshManager.checkBackgroundRefreshStatus() {
        case .available:
            return Color.BlackCat.naturalGreen
        case .denied:
            return Color.BlackCat.naturalRed
        case .restricted:
            return Color.BlackCat.naturalYellow
        @unknown default:
            return Color.BlackCat.shadowLevel3
        }
    }

    private var backgroundRefreshStatusText: String {
        switch backgroundRefreshManager.checkBackgroundRefreshStatus() {
        case .available:
            return "有効"
        case .denied:
            return "無効"
        case .restricted:
            return "制限あり"
        @unknown default:
            return "不明"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Notification Section
    private var notificationSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.output.statusUpdateNotificationEnabled },
                set: { viewModel.input.setStatusUpdateNotification($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("配達状況更新通知")
                            .foregroundColor(.white)
                        Text("配達状況が変わった時に通知")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                } icon: {
                    Image(systemName: "bell.badge")
                        .foregroundColor(Color.BlackCat.primaryBlue)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.BlackCat.accentPrimary))
            .listRowBackground(Color.BlackCat.backgroundCard)

            Toggle(isOn: Binding(
                get: { viewModel.output.deliveryCompletedNotificationEnabled },
                set: { viewModel.input.setDeliveryCompletedNotification($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("配達完了通知")
                            .foregroundColor(.white)
                        Text("荷物が届いた時に通知")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                } icon: {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(Color.BlackCat.naturalGreen)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.BlackCat.accentPrimary))
            .listRowBackground(Color.BlackCat.backgroundCard)
        } header: {
            sectionHeader(title: "通知設定", icon: "bell.fill")
        }
    }

    // MARK: - Display Section
    private var displaySection: some View {
        Section {
            // Haptic Feedback Toggle
            Toggle(isOn: Binding(
                get: { viewModel.output.hapticEnabled },
                set: { viewModel.input.setHapticEnabled($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("触覚フィードバック")
                            .foregroundColor(.white)
                        Text("操作時に振動でフィードバック")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                } icon: {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(Color.BlackCat.primaryBlue)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.BlackCat.accentPrimary))
            .listRowBackground(Color.BlackCat.backgroundCard)

            // Default Carrier Picker
            HStack {
                Label {
                    Text("デフォルト配送業者")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "shippingbox")
                        .foregroundColor(Color.BlackCat.primaryOrange)
                }

                Spacer()

                Picker("", selection: Binding(
                    get: { viewModel.output.defaultCarrier },
                    set: { viewModel.input.setDefaultCarrier($0) }
                )) {
                    ForEach(DeliveryCarrier.allCases) { carrier in
                        Text(carrier.displayName).tag(carrier)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.BlackCat.accentPrimary)
            }
            .listRowBackground(Color.BlackCat.backgroundCard)

            // Sort Order Picker
            HStack {
                Label {
                    Text("リスト表示順")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(Color.BlackCat.purePurple)
                }

                Spacer()

                Picker("", selection: Binding(
                    get: { viewModel.output.listSortOrder },
                    set: { viewModel.input.setListSortOrder($0) }
                )) {
                    ForEach(ListSortOrder.allCases) { order in
                        Text(order.displayName).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.BlackCat.accentPrimary)
            }
            .listRowBackground(Color.BlackCat.backgroundCard)
        } header: {
            sectionHeader(title: "表示設定", icon: "eye.fill")
        }
    }

    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        Section {
            // Auto Delete Setting
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("配達完了アイテムの自動削除")
                            .foregroundColor(.white)
                        Text("配達完了後、指定日数で自動削除")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Color.BlackCat.naturalYellow)
                }

                Spacer()

                Picker("", selection: Binding(
                    get: { viewModel.output.autoDeleteOption },
                    set: { viewModel.input.setAutoDeleteDays($0) }
                )) {
                    ForEach(AutoDeleteOption.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.BlackCat.accentPrimary)
            }
            .listRowBackground(Color.BlackCat.backgroundCard)

            // Delete All Data Button
            Button(action: {
                HapticManager.shared.deleteConfirmation()
                viewModel.showDeleteConfirmation = true
            }) {
                Label {
                    Text("全データを削除")
                        .foregroundColor(Color.BlackCat.naturalRed)
                } icon: {
                    Image(systemName: "trash")
                        .foregroundColor(Color.BlackCat.naturalRed)
                }
            }
            .listRowBackground(Color.BlackCat.backgroundCard)
        } header: {
            sectionHeader(title: "データ管理", icon: "externaldrive.fill")
        }
    }

    // MARK: - App Info Section
    private var appInfoSection: some View {
        Section {
            // Help & FAQ
            NavigationLink {
                HelpView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ヘルプ・FAQ")
                            .foregroundColor(.white)
                        Text("使い方やよくある質問")
                            .font(.caption)
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }
                } icon: {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(Color.BlackCat.primaryOrange)
                }
            }
            .listRowBackground(Color.BlackCat.backgroundCard)

            // Version
            HStack {
                Label {
                    Text("バージョン")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                }

                Spacer()

                Text(viewModel.output.appVersion)
                    .foregroundColor(Color.BlackCat.shadowLevel3)
            }
            .listRowBackground(Color.BlackCat.backgroundCard)

            // License
            NavigationLink {
                LicenseView()
            } label: {
                Label {
                    Text("ライセンス")
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "doc.text")
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                }
            }
            .listRowBackground(Color.BlackCat.backgroundCard)

            // Privacy Policy
            Button(action: {
                if let url = URL(string: "https://example.com/privacy-policy") {
                    openURL(url)
                }
            }) {
                HStack {
                    Label {
                        Text("プライバシーポリシー")
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "hand.raised")
                            .foregroundColor(Color.BlackCat.shadowLevel3)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(Color.BlackCat.shadowLevel3)
                        .font(.caption)
                }
            }
            .listRowBackground(Color.BlackCat.backgroundCard)
        } header: {
            sectionHeader(title: "アプリ情報", icon: "info.circle.fill")
        } footer: {
            Text("BlackCat - 荷物追跡アプリ")
                .font(.caption)
                .foregroundColor(Color.BlackCat.shadowLevel4)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        }
    }

    // MARK: - Section Header Helper
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color.BlackCat.accentPrimary)
                .font(.caption)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.BlackCat.shadowLevel2)
        }
        .textCase(nil)
    }
}

// MARK: - License View
struct LicenseView: View {
    var body: some View {
        ZStack {
            Color.BlackCat.backgroundPrimary
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App License
                    licenseSection(
                        title: "BlackCat",
                        license: """
                        Copyright (c) 2024 BlackCat Team

                        This application is provided "as is" without warranty of any kind.
                        """
                    )

                    // Open Source Licenses
                    licenseSection(
                        title: "オープンソースライセンス",
                        license: """
                        このアプリケーションは以下のオープンソースソフトウェアを使用しています。

                        ---

                        Swift Package Manager
                        Copyright (c) Apple Inc.
                        Licensed under Apache License 2.0

                        ---

                        Combine Framework
                        Copyright (c) Apple Inc.
                        """
                    )
                }
                .padding()
            }
        }
        .navigationTitle("ライセンス")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func licenseSection(title: String, license: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(license)
                .font(.caption)
                .foregroundColor(Color.BlackCat.shadowLevel2)
                .padding()
                .background(Color.BlackCat.backgroundCard)
                .cornerRadius(12)
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
