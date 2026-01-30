import UIKit
import SwiftUI

/// Haptic Feedback（触覚フィードバック）を管理するシングルトンクラス
/// システム設定とアプリ設定の両方を考慮してフィードバックを制御
final class HapticManager {

    // MARK: - Singleton
    static let shared = HapticManager()

    // MARK: - UserDefaults Key
    private static let hapticEnabledKey = "settings_haptic_enabled"

    // MARK: - Feedback Generators
    private let impactLightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let impactMediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Properties

    /// Haptic Feedbackが有効かどうか（アプリ設定）
    var isHapticEnabled: Bool {
        get {
            // デフォルトはtrue（有効）
            if UserDefaults.standard.object(forKey: Self.hapticEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Self.hapticEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.hapticEnabledKey)
        }
    }

    /// システム設定でHapticが利用可能かどうか
    /// 注意: iOSはシステムレベルのHaptic設定を直接取得するAPIを提供していないため、
    /// デバイスがHapticをサポートしているかどうかで判断
    var isSystemHapticAvailable: Bool {
        // iPhone 7以降のデバイスでTaptic Engineが利用可能
        // UIDevice.current.model で判断するか、実際にフィードバックを試みる
        return true
    }

    /// Haptic Feedbackを実行可能かどうか
    private var canTriggerHaptic: Bool {
        return isHapticEnabled && isSystemHapticAvailable
    }

    // MARK: - Initialization

    private init() {
        prepareGenerators()
    }

    // MARK: - Prepare Generators

    /// ジェネレーターを事前準備（レイテンシー削減のため）
    func prepareGenerators() {
        impactLightGenerator.prepare()
        impactMediumGenerator.prepare()
        impactHeavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Impact Feedback

    /// 軽いインパクトフィードバック
    /// 使用例: ボタンタップ、軽い操作
    func lightImpact() {
        guard canTriggerHaptic else { return }
        impactLightGenerator.impactOccurred()
        impactLightGenerator.prepare()
    }

    /// 中程度のインパクトフィードバック
    /// 使用例: 重要なボタンタップ、確認操作
    func mediumImpact() {
        guard canTriggerHaptic else { return }
        impactMediumGenerator.impactOccurred()
        impactMediumGenerator.prepare()
    }

    /// 強いインパクトフィードバック
    /// 使用例: 重要な操作完了、強調したいアクション
    func heavyImpact() {
        guard canTriggerHaptic else { return }
        impactHeavyGenerator.impactOccurred()
        impactHeavyGenerator.prepare()
    }

    /// カスタム強度のインパクトフィードバック
    /// - Parameter intensity: フィードバックの強度 (0.0 ~ 1.0)
    func impact(intensity: CGFloat) {
        guard canTriggerHaptic else { return }
        impactMediumGenerator.impactOccurred(intensity: intensity)
        impactMediumGenerator.prepare()
    }

    // MARK: - Notification Feedback

    /// 成功通知フィードバック
    /// 使用例: 登録成功、保存完了、操作成功
    func success() {
        guard canTriggerHaptic else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// 警告通知フィードバック
    /// 使用例: 削除確認、注意が必要な操作
    func warning() {
        guard canTriggerHaptic else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// エラー通知フィードバック
    /// 使用例: エラー発生、入力エラー、操作失敗
    func error() {
        guard canTriggerHaptic else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Selection Feedback

    /// 選択変更フィードバック
    /// 使用例: ピッカー選択、セグメント切り替え、オプション選択
    func selection() {
        guard canTriggerHaptic else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Convenience Methods

    /// ボタンタップ用フィードバック（軽いインパクト）
    func buttonTap() {
        lightImpact()
    }

    /// 登録成功用フィードバック
    func registrationSuccess() {
        success()
    }

    /// プルリフレッシュ完了用フィードバック
    func refreshComplete() {
        mediumImpact()
    }

    /// 削除確認用フィードバック（警告）
    func deleteConfirmation() {
        warning()
    }

    /// ページ遷移用フィードバック（選択）
    func pageTransition() {
        selection()
    }

    /// 配送業者選択変更用フィードバック
    func carrierSelection() {
        selection()
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// ボタンタップ時にHaptic Feedbackを追加するモディファイア
    func hapticOnTap(style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .light:
                    HapticManager.shared.lightImpact()
                case .medium:
                    HapticManager.shared.mediumImpact()
                case .heavy:
                    HapticManager.shared.heavyImpact()
                case .success:
                    HapticManager.shared.success()
                case .warning:
                    HapticManager.shared.warning()
                case .error:
                    HapticManager.shared.error()
                case .selection:
                    HapticManager.shared.selection()
                }
            }
        )
    }
}

/// Haptic Feedbackのスタイル
enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}
