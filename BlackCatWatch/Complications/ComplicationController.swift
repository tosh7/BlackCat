import WidgetKit
import SwiftUI

// MARK: - Watch Complication Entry

/// Complication用のTimelineEntry
struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let deliveries: [WatchDeliveryData]
    let lastUpdate: Date?

    /// アクティブな配達（配達完了以外）の数
    var activeDeliveryCount: Int {
        deliveries.filter { !$0.isDelivered }.count
    }

    /// 最新のアクティブな配達
    var latestActiveDelivery: WatchDeliveryData? {
        deliveries.first { !$0.isDelivered } ?? deliveries.first
    }

    // MARK: - Static Entries

    static var placeholder: WatchComplicationEntry {
        WatchComplicationEntry(
            date: Date(),
            deliveries: [
                WatchDeliveryData(
                    id: UUID().uuidString,
                    deliveryID: 123456789012,
                    carrierName: "ヤマト運輸",
                    carrierIcon: "shippingbox.fill",
                    latestStatus: "配達中",
                    latestStatusType: "delivering",
                    latestDate: "01/29",
                    latestTime: "14:30",
                    latestLocation: "配送センター",
                    registeredDate: Date(),
                    isDelivered: false
                )
            ],
            lastUpdate: Date()
        )
    }

    static var empty: WatchComplicationEntry {
        WatchComplicationEntry(
            date: Date(),
            deliveries: [],
            lastUpdate: nil
        )
    }

    static var preview: WatchComplicationEntry {
        WatchComplicationEntry(
            date: Date(),
            deliveries: [
                WatchDeliveryData(
                    id: UUID().uuidString,
                    deliveryID: 123456789012,
                    carrierName: "ヤマト運輸",
                    carrierIcon: "shippingbox.fill",
                    latestStatus: "配達中",
                    latestStatusType: "delivering",
                    latestDate: "01/29",
                    latestTime: "14:30",
                    latestLocation: "ヤマト運輸",
                    registeredDate: Date(),
                    isDelivered: false
                ),
                WatchDeliveryData(
                    id: UUID().uuidString,
                    deliveryID: 987654321098,
                    carrierName: "佐川急便",
                    carrierIcon: "truck.box.fill",
                    latestStatus: "輸送中",
                    latestStatusType: "shipping",
                    latestDate: "01/28",
                    latestTime: "10:15",
                    latestLocation: "佐川急便",
                    registeredDate: Date(),
                    isDelivered: false
                )
            ],
            lastUpdate: Date()
        )
    }
}

// MARK: - WatchDeliveryData Extension for Complication

extension WatchDeliveryData {
    /// ステータスに対応するSF Symbolアイコン（Complication用）
    var complicationIcon: String {
        switch latestStatusType {
        case "received":
            return "shippingbox"
        case "sended":
            return "paperplane.fill"
        case "shipping":
            return "truck.box.fill"
        case "delivering":
            return "figure.walk"
        case "delivered":
            return "checkmark.circle.fill"
        default:
            return "questionmark.circle"
        }
    }

    /// 短縮ステータス名（Complication用）
    var shortStatusName: String {
        switch latestStatusType {
        case "received":
            return "受付"
        case "sended":
            return "発送"
        case "shipping":
            return "輸送"
        case "delivering":
            return "配達"
        case "delivered":
            return "完了"
        default:
            return "不明"
        }
    }

    /// ステータスの日本語表示名（Complication用）
    var displayStatusName: String {
        switch latestStatusType {
        case "received":
            return "荷物受付"
        case "sended":
            return "発送済み"
        case "shipping":
            return "輸送中"
        case "delivering":
            return "配達中"
        case "delivered":
            return "配達完了"
        default:
            return "不明"
        }
    }

    /// 伝票番号（文字列形式）
    var trackingNumberString: String {
        String(deliveryID)
    }
}

// MARK: - Complication Data Manager

/// Complication用のデータ管理クラス
/// WatchConnectivityManagerと連携してデータを取得
final class ComplicationDataManager {
    static let shared = ComplicationDataManager()

    /// App Group identifier
    private let appGroupIdentifier = "group.com.blackcat.delivery"
    private let deliveryDataKey = "WatchDeliveryDataForComplication"
    private let lastUpdateKey = "ComplicationLastUpdate"

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    /// 配達データを保存（WatchConnectivityManagerから呼び出し）
    func saveDeliveries(_ deliveries: [WatchDeliveryData]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(deliveries) {
            sharedDefaults?.set(encoded, forKey: deliveryDataKey)
            sharedDefaults?.set(Date(), forKey: lastUpdateKey)
        }
    }

    /// 配達データを取得
    func loadDeliveries() -> [WatchDeliveryData] {
        guard let data = sharedDefaults?.data(forKey: deliveryDataKey) else {
            return []
        }

        let decoder = JSONDecoder()
        if let deliveries = try? decoder.decode([WatchDeliveryData].self, from: data) {
            return deliveries
        }
        return []
    }

    /// 最後の更新日時を取得
    func lastUpdateDate() -> Date? {
        return sharedDefaults?.object(forKey: lastUpdateKey) as? Date
    }

    /// Complicationをリロード
    func reloadComplications() {
        WidgetCenter.shared.reloadTimelines(ofKind: "BlackCatWatchComplication")
    }
}

// MARK: - Timeline Provider

/// Complication用のTimelineProvider
struct ComplicationTimelineProvider: TimelineProvider {
    typealias Entry = WatchComplicationEntry

    func placeholder(in context: Context) -> WatchComplicationEntry {
        return .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        if context.isPreview {
            completion(.preview)
        } else {
            let deliveries = ComplicationDataManager.shared.loadDeliveries()
            let entry = WatchComplicationEntry(
                date: Date(),
                deliveries: deliveries,
                lastUpdate: ComplicationDataManager.shared.lastUpdateDate()
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let deliveries = ComplicationDataManager.shared.loadDeliveries()
        let currentDate = Date()

        // 現在のエントリを作成
        let entry = WatchComplicationEntry(
            date: currentDate,
            deliveries: deliveries,
            lastUpdate: ComplicationDataManager.shared.lastUpdateDate()
        )

        // 15分後に次の更新をスケジュール
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Views

/// accessoryCircular用ビュー - 小さな円形（ステータスアイコン）
struct AccessoryCircularView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let delivery = entry.latestActiveDelivery {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: delivery.complicationIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(delivery.statusColor)

                    if entry.activeDeliveryCount > 1 {
                        Text("\(entry.activeDeliveryCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "shippingbox")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// accessoryRectangular用ビュー - 長方形（伝票番号+ステータス）
struct AccessoryRectangularView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let delivery = entry.latestActiveDelivery {
            VStack(alignment: .leading, spacing: 2) {
                // ステータス行
                HStack(spacing: 4) {
                    Image(systemName: delivery.complicationIcon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(delivery.statusColor)

                    Text(delivery.displayStatusName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    if entry.activeDeliveryCount > 1 {
                        Text("+\(entry.activeDeliveryCount - 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                // 伝票番号
                Text(delivery.trackingNumberString)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // 日時
                HStack(spacing: 4) {
                    if !delivery.latestDate.isEmpty {
                        Text(delivery.latestDate)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    if let time = delivery.latestTime {
                        Text(time)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 12))
                    Text("配達状況")
                        .font(.system(size: 13, weight: .semibold))
                }

                Text("追跡中の荷物はありません")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// accessoryInline用ビュー - インライン（ステータステキスト）
struct AccessoryInlineView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let delivery = entry.latestActiveDelivery {
            Label {
                if entry.activeDeliveryCount > 1 {
                    Text("\(delivery.shortStatusName) (\(entry.activeDeliveryCount)件)")
                } else {
                    Text(delivery.displayStatusName)
                }
            } icon: {
                Image(systemName: delivery.complicationIcon)
            }
        } else {
            Label("配達なし", systemImage: "shippingbox")
        }
    }
}

/// accessoryCorner用ビュー - コーナー（アイコン）
struct AccessoryCornerView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let delivery = entry.latestActiveDelivery {
            ZStack {
                Image(systemName: delivery.complicationIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(delivery.statusColor)
            }
            .widgetLabel {
                Text(delivery.shortStatusName)
            }
        } else {
            Image(systemName: "shippingbox")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .widgetLabel {
                    Text("配達")
                }
        }
    }
}

// MARK: - Main Complication Widget

/// BlackCat Watch Complication Widget
struct BlackCatWatchComplication: Widget {
    let kind: String = "BlackCatWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationTimelineProvider()) { entry in
            ComplicationEntryView(entry: entry)
                .widgetURL(URL(string: "blackcat://watch/delivery"))
        }
        .configurationDisplayName("配達状況")
        .description("配達中の荷物の最新状況を文字盤に表示します")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

// MARK: - Complication Entry View

/// Complicationファミリーに応じたビューを表示
struct ComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WatchComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        case .accessoryCorner:
            AccessoryCornerView(entry: entry)
        default:
            // フォールバック: Circularビューを使用
            AccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

/// Complication Widget Bundle
/// NOTE: @main はBlackCatWatchApp.swiftで宣言済みのため、ここでは宣言しない。
/// Complicationを有効にするには、独立したWidget Extensionターゲットを作成するか、
/// BlackCatWatchAppにWidgetBundleを統合する必要がある。
struct BlackCatWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        BlackCatWatchComplication()
    }
}

// MARK: - Previews

#if DEBUG
struct BlackCatWatchComplication_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Circular - アクティブな配達あり
            ComplicationEntryView(entry: .preview)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular - Active")

            // Circular - 配達なし
            ComplicationEntryView(entry: .empty)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular - Empty")

            // Rectangular - アクティブな配達あり
            ComplicationEntryView(entry: .preview)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular - Active")

            // Rectangular - 配達なし
            ComplicationEntryView(entry: .empty)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular - Empty")

            // Inline
            ComplicationEntryView(entry: .preview)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")

            // Corner
            ComplicationEntryView(entry: .preview)
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")
        }
    }
}
#endif
