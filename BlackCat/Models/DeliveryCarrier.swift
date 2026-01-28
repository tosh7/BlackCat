import Foundation
import SwiftUI

enum DeliveryCarrier: String, CaseIterable, Identifiable {
    case yamato = "ヤマト運輸"
    case sagawa = "佐川急便"
    case japanPost = "日本郵便"

    var id: String { self.rawValue }

    var displayName: String {
        return self.rawValue
    }

    var apiEndpoint: String {
        switch self {
        case .yamato:
            return "tneko"
        case .sagawa:
            return "sagawa"
        case .japanPost:
            return "japanpost"
        }
    }

    /// SF Symbol icon for the carrier
    var iconName: String {
        switch self {
        case .yamato:
            return "shippingbox.fill"
        case .sagawa:
            return "truck.box.fill"
        case .japanPost:
            return "envelope.fill"
        }
    }

    /// Brand color for the carrier
    var brandColor: Color {
        switch self {
        case .yamato:
            return Color(hex: "0x2C3E50") // Dark navy for Yamato
        case .sagawa:
            return Color(hex: "0x1E88E5") // Blue for Sagawa
        case .japanPost:
            return Color(hex: "0xCC0000") // Red for Japan Post
        }
    }

    /// Short description for the carrier
    var shortDescription: String {
        switch self {
        case .yamato:
            return "クロネコヤマト"
        case .sagawa:
            return "飛脚宅配便"
        case .japanPost:
            return "ゆうパック"
        }
    }

    /// Tracking number digit count
    var trackingNumberLength: Int {
        switch self {
        case .yamato:
            return 12
        case .sagawa:
            return 12
        case .japanPost:
            return 12
        }
    }

    /// Generate tracking URL for the carrier
    /// - Parameter trackingNumber: The tracking number to look up
    /// - Returns: URL for tracking the package on the carrier's website
    func trackingURL(for trackingNumber: String) -> URL? {
        let urlString: String
        switch self {
        case .yamato:
            urlString = "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko?number=\(trackingNumber)"
        case .sagawa:
            urlString = "https://k2k.sagawa-exp.co.jp/p/web/okurijosearch.do?okurijoNo=\(trackingNumber)"
        case .japanPost:
            urlString = "https://trackings.post.japanpost.jp/services/srv/search/?requestNo1=\(trackingNumber)"
        }
        return URL(string: urlString)
    }

    /// Base tracking URL for the carrier (without tracking number)
    var trackingBaseURL: String {
        switch self {
        case .yamato:
            return "https://toi.kuronekoyamato.co.jp/"
        case .sagawa:
            return "https://k2k.sagawa-exp.co.jp/"
        case .japanPost:
            return "https://trackings.post.japanpost.jp/"
        }
    }
}

// MARK: - 伝票番号自動判別機能

/// 伝票番号判別結果
enum CarrierDetectionResult: Equatable {
    /// 単一の配送業者が判別された
    case detected(DeliveryCarrier)
    /// 複数の候補がある（ユーザーに選択を促す）
    case multipleCandidates([DeliveryCarrier])
    /// 判別不可（パターンに一致しない）
    case unknown
    /// 入力が不十分（桁数不足など）
    case insufficientInput

    var isDetected: Bool {
        if case .detected = self { return true }
        return false
    }

    var detectedCarrier: DeliveryCarrier? {
        if case .detected(let carrier) = self { return carrier }
        return nil
    }

    var candidates: [DeliveryCarrier] {
        switch self {
        case .detected(let carrier):
            return [carrier]
        case .multipleCandidates(let carriers):
            return carriers
        default:
            return []
        }
    }

    var feedbackMessage: String? {
        switch self {
        case .detected(let carrier):
            return "\(carrier.displayName)の伝票番号を検出しました"
        case .multipleCandidates(let carriers):
            let names = carriers.map { $0.displayName }.joined(separator: "または")
            return "複数の候補があります: \(names)"
        case .unknown:
            return "配送業者を判別できませんでした"
        case .insufficientInput:
            return nil
        }
    }
}

extension DeliveryCarrier {

    // MARK: - 伝票番号パターン定義

    /// 各配送業者の伝票番号パターン（正規表現）
    private var trackingNumberPattern: String {
        switch self {
        case .yamato:
            // ヤマト運輸: 12桁の数字
            // 先頭が1, 2, 3, 4で始まることが多い
            return "^[1-4]\\d{11}$"
        case .sagawa:
            // 佐川急便: 12桁の数字
            // 先頭が5, 6, 7で始まることが多い
            return "^[5-7]\\d{11}$"
        case .japanPost:
            // 日本郵便: 11〜13桁
            // ゆうパック: 11〜12桁の数字
            // 書留・レターパック: 英字を含む場合もある（例: EA123456789JP）
            return "^(\\d{11,13}|[A-Z]{2}\\d{9}[A-Z]{2})$"
        }
    }

    /// 伝票番号が当該配送業者のパターンに一致するか判定
    /// - Parameter trackingNumber: 伝票番号
    /// - Returns: パターンに一致する場合true
    func matches(trackingNumber: String) -> Bool {
        let cleanedNumber = trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = try? NSRegularExpression(pattern: trackingNumberPattern, options: []) else {
            return false
        }
        let range = NSRange(cleanedNumber.startIndex..., in: cleanedNumber)
        return regex.firstMatch(in: cleanedNumber, options: [], range: range) != nil
    }

    /// 伝票番号のマッチ度（優先度判定用）
    /// - Parameter trackingNumber: 伝票番号
    /// - Returns: マッチ度スコア（0.0〜1.0）
    func matchScore(for trackingNumber: String) -> Double {
        let cleanedNumber = trackingNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        // 基本的なマッチ判定
        guard matches(trackingNumber: cleanedNumber) else {
            return 0.0
        }

        // 追加の特徴に基づくスコア加算
        var score = 0.5

        switch self {
        case .yamato:
            // ヤマト運輸の特徴的なパターン
            if cleanedNumber.count == 12 && cleanedNumber.hasPrefix("1") {
                score += 0.3
            } else if cleanedNumber.count == 12 {
                score += 0.2
            }

        case .sagawa:
            // 佐川急便の特徴的なパターン
            if cleanedNumber.count == 12 && (cleanedNumber.hasPrefix("5") || cleanedNumber.hasPrefix("6")) {
                score += 0.3
            } else if cleanedNumber.count == 12 {
                score += 0.2
            }

        case .japanPost:
            // 日本郵便の特徴的なパターン
            // 国際郵便形式（例: EA123456789JP）
            if cleanedNumber.count == 13 && cleanedNumber.hasSuffix("JP") {
                score += 0.4
            }
            // ゆうパック（11桁）
            else if cleanedNumber.count == 11 {
                score += 0.3
            }
        }

        return min(score, 1.0)
    }

    // MARK: - 静的判別メソッド

    /// 伝票番号から配送業者を自動判別
    /// - Parameter trackingNumber: 伝票番号
    /// - Returns: 判別結果
    static func detect(from trackingNumber: String) -> CarrierDetectionResult {
        let cleanedNumber = trackingNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        // 入力チェック
        guard !cleanedNumber.isEmpty else {
            return .insufficientInput
        }

        // 数字のみの場合、最低桁数チェック
        if cleanedNumber.allSatisfy({ $0.isNumber }) {
            guard cleanedNumber.count >= 11 else {
                return .insufficientInput
            }
        }

        // 全配送業者でマッチング
        var matchedCarriers: [(carrier: DeliveryCarrier, score: Double)] = []

        for carrier in DeliveryCarrier.allCases {
            let score = carrier.matchScore(for: cleanedNumber)
            if score > 0 {
                matchedCarriers.append((carrier, score))
            }
        }

        // マッチ結果の判定
        switch matchedCarriers.count {
        case 0:
            // 一致なし
            return .unknown

        case 1:
            // 単一マッチ
            return .detected(matchedCarriers[0].carrier)

        default:
            // 複数マッチ - スコアで判定
            let sorted = matchedCarriers.sorted { $0.score > $1.score }

            // 最高スコアと2位の差が大きい場合は確定
            if sorted[0].score - sorted[1].score >= 0.2 {
                return .detected(sorted[0].carrier)
            }

            // 差が小さい場合は候補として提示
            return .multipleCandidates(sorted.map { $0.carrier })
        }
    }

    /// 伝票番号の形式を検証
    /// - Parameter trackingNumber: 伝票番号
    /// - Returns: 有効な形式の場合true
    static func isValidTrackingNumber(_ trackingNumber: String) -> Bool {
        let result = detect(from: trackingNumber)
        switch result {
        case .detected, .multipleCandidates:
            return true
        default:
            return false
        }
    }
}