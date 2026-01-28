import WidgetKit
import SwiftUI
import Intents

// MARK: - Shared Data Models

/// ウィジェットで使用する配達アイテムモデル
struct WidgetDeliveryItem: Identifiable, Codable {
    let id: UUID
    let deliveryID: Int
    let latestStatus: String
    let latestDate: String
    let latestTime: String?
    let shopName: String
    let statusType: WidgetDeliveryStatusType

    init(id: UUID = UUID(), deliveryID: Int, latestStatus: String, latestDate: String, latestTime: String?, shopName: String, statusType: WidgetDeliveryStatusType) {
        self.id = id
        self.deliveryID = deliveryID
        self.latestStatus = latestStatus
        self.latestDate = latestDate
        self.latestTime = latestTime
        self.shopName = shopName
        self.statusType = statusType
    }
}

/// 配達ステータスの種類
enum WidgetDeliveryStatusType: String, Codable {
    case received = "荷物受付"
    case sended = "発送済み"
    case shipping = "輸送中"
    case delivering = "配達中"
    case delivered = "配達完了"
    case unknown = "不明"

    var color: Color {
        switch self {
        case .received:
            return Color(hex: "0x7f7fff") // pureBlue
        case .sended:
            return Color(hex: "0xff7fbf") // purePink
        case .shipping:
            return Color(hex: "0xffbf7f") // pureOrange
        case .delivering:
            return Color(hex: "0xff7f7f") // pureRed
        case .delivered:
            return Color(hex: "0x404040") // shadowLevel6
        case .unknown:
            return Color(hex: "0x808080") // shadowLevel4
        }
    }

    var icon: String {
        switch self {
        case .received:
            return "shippingbox"
        case .sended:
            return "paperplane.fill"
        case .shipping:
            return "truck.box.fill"
        case .delivering:
            return "figure.walk"
        case .delivered:
            return "checkmark.circle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    static func from(status: String) -> WidgetDeliveryStatusType {
        switch status {
        case "荷物受付":
            return .received
        case "発送済み":
            return .sended
        case "輸送中":
            return .shipping
        case "配達中", "持戻（ご不在）", "配達日・時間帯指定（保管中）":
            return .delivering
        case "配達完了", "配達完了（宅配ボックス）":
            return .delivered
        default:
            return .unknown
        }
    }
}

// MARK: - Color Extension for Widget

extension Color {
    init(hex: String) {
        var color: UInt64 = 0
        var r: Double = 0, g: Double = 0, b: Double = 0
        if Scanner(string: hex.replacingOccurrences(of: "#", with: "").replacingOccurrences(of: "0x", with: "")).scanHexInt64(&color) {
            r = Double((color & 0xFF0000) >> 16) / 255.0
            g = Double((color & 0x00FF00) >> 8) / 255.0
            b = Double(color & 0x0000FF) / 255.0
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Shared Data Manager

/// App Groupを使用してアプリとウィジェット間でデータを共有するマネージャー
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    /// App Group identifier - 実際のプロジェクトに合わせて変更してください
    private let appGroupIdentifier = "group.com.blackcat.delivery"
    private let deliveryItemsKey = "WidgetDeliveryItems"
    private let lastUpdateKey = "WidgetLastUpdate"
    private let itemListKey = "ItemList"

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    /// 標準のUserDefaultsにフォールバック
    private var standardDefaults: UserDefaults {
        return UserDefaults.standard
    }

    init() {}

    /// 配達アイテムリストを保存
    func saveDeliveryItems(_ items: [WidgetDeliveryItem]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(items) {
            sharedDefaults?.set(encoded, forKey: deliveryItemsKey)
            sharedDefaults?.set(Date(), forKey: lastUpdateKey)
        }
    }

    /// 配達アイテムリストを取得
    func loadDeliveryItems() -> [WidgetDeliveryItem] {
        // まずApp Groupから読み込み
        if let data = sharedDefaults?.data(forKey: deliveryItemsKey) {
            let decoder = JSONDecoder()
            if let items = try? decoder.decode([WidgetDeliveryItem].self, from: data) {
                return items
            }
        }

        // フォールバック: 標準UserDefaultsからIDリストを読み込み、モックデータを生成
        let itemIds = loadItemIds()
        return itemIds.prefix(5).enumerated().map { index, id in
            createMockItem(deliveryID: id, index: index)
        }
    }

    /// LocalDeliveryItemsと同じキーからIDリストを取得
    private func loadItemIds() -> [Int] {
        // App Groupから読み込み
        if let array = sharedDefaults?.array(forKey: itemListKey) as? [Int], !array.isEmpty {
            return array
        }
        // 標準UserDefaultsからフォールバック
        if let array = standardDefaults.array(forKey: itemListKey) as? [Int] {
            return array
        }
        return []
    }

    /// 最後の更新日時を取得
    func lastUpdateDate() -> Date? {
        return sharedDefaults?.object(forKey: lastUpdateKey) as? Date
    }

    /// モックアイテムを生成（デモ用）
    private func createMockItem(deliveryID: Int, index: Int) -> WidgetDeliveryItem {
        let statuses: [(String, WidgetDeliveryStatusType)] = [
            ("配達中", .delivering),
            ("輸送中", .shipping),
            ("発送済み", .sended),
            ("荷物受付", .received),
            ("配達完了", .delivered)
        ]
        let status = statuses[index % statuses.count]

        return WidgetDeliveryItem(
            deliveryID: deliveryID,
            latestStatus: status.0,
            latestDate: "01/29",
            latestTime: "14:30",
            shopName: "配送センター",
            statusType: status.1
        )
    }
}

// MARK: - Timeline Entry

struct DeliveryEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let deliveryItems: [WidgetDeliveryItem]
    let lastUpdate: Date?

    static var placeholder: DeliveryEntry {
        DeliveryEntry(
            date: Date(),
            configuration: ConfigurationIntent(),
            deliveryItems: [
                WidgetDeliveryItem(
                    deliveryID: 123456789012,
                    latestStatus: "配達中",
                    latestDate: "01/29",
                    latestTime: "14:30",
                    shopName: "ヤマト運輸 新宿営業所",
                    statusType: .delivering
                )
            ],
            lastUpdate: Date()
        )
    }

    static var empty: DeliveryEntry {
        DeliveryEntry(
            date: Date(),
            configuration: ConfigurationIntent(),
            deliveryItems: [],
            lastUpdate: nil
        )
    }
}

// MARK: - Timeline Provider

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> DeliveryEntry {
        return DeliveryEntry.placeholder
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (DeliveryEntry) -> Void) {
        if context.isPreview {
            completion(DeliveryEntry.placeholder)
        } else {
            let items = WidgetDataManager.shared.loadDeliveryItems()
            let entry = DeliveryEntry(
                date: Date(),
                configuration: configuration,
                deliveryItems: items,
                lastUpdate: WidgetDataManager.shared.lastUpdateDate()
            )
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<DeliveryEntry>) -> Void) {
        let items = WidgetDataManager.shared.loadDeliveryItems()
        let currentDate = Date()

        var entries: [DeliveryEntry] = []

        // 現在のエントリ
        let entry = DeliveryEntry(
            date: currentDate,
            configuration: configuration,
            deliveryItems: items,
            lastUpdate: WidgetDataManager.shared.lastUpdateDate()
        )
        entries.append(entry)

        // 15分後に次の更新をスケジュール
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!

        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

/// 小サイズウィジェット用ビュー
struct SmallWidgetView: View {
    let entry: DeliveryEntry

    var body: some View {
        if let item = entry.deliveryItems.first {
            VStack(alignment: .leading, spacing: 8) {
                // ヘッダー
                HStack {
                    Image(systemName: item.statusType.icon)
                        .font(.title2)
                        .foregroundColor(item.statusType.color)
                    Spacer()
                    Text(item.latestDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // ステータス
                Text(item.latestStatus)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // 伝票番号
                Text(formatDeliveryID(item.deliveryID))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                // 更新時刻
                if let time = item.latestTime {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(time)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        } else {
            EmptyStateView(isSmall: true)
        }
    }

    private func formatDeliveryID(_ id: Int) -> String {
        let str = String(id)
        if str.count == 12 {
            return "\(str.prefix(4))-\(str.dropFirst(4).prefix(4))-\(str.suffix(4))"
        }
        return str
    }
}

/// 中サイズウィジェット用ビュー
struct MediumWidgetView: View {
    let entry: DeliveryEntry

    var body: some View {
        if entry.deliveryItems.isEmpty {
            EmptyStateView(isSmall: false)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // ヘッダー
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(.orange)
                    Text("配達状況")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    if let lastUpdate = entry.lastUpdate {
                        Text(lastUpdate, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // 配達アイテムリスト（最大2件）
                ForEach(entry.deliveryItems.prefix(2)) { item in
                    DeliveryItemRow(item: item)
                }

                // 残りのアイテム数
                if entry.deliveryItems.count > 2 {
                    HStack {
                        Spacer()
                        Text("他 \(entry.deliveryItems.count - 2) 件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

/// 大サイズウィジェット用ビュー
struct LargeWidgetView: View {
    let entry: DeliveryEntry

    var body: some View {
        if entry.deliveryItems.isEmpty {
            EmptyStateView(isSmall: false)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("配達状況一覧")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(entry.deliveryItems.count) 件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let lastUpdate = entry.lastUpdate {
                            Text("更新: \(lastUpdate, style: .time)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // 配達アイテムリスト（最大5件）
                ForEach(entry.deliveryItems.prefix(5)) { item in
                    DeliveryItemDetailRow(item: item)
                    if item.id != entry.deliveryItems.prefix(5).last?.id {
                        Divider()
                    }
                }

                Spacer()

                // 残りのアイテム数
                if entry.deliveryItems.count > 5 {
                    HStack {
                        Spacer()
                        Text("他 \(entry.deliveryItems.count - 5) 件の配達があります")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

/// 配達アイテムの行表示（中サイズ用）
struct DeliveryItemRow: View {
    let item: WidgetDeliveryItem

    var body: some View {
        HStack(spacing: 12) {
            // ステータスアイコン
            Circle()
                .fill(item.statusType.color)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: item.statusType.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                )

            // 情報
            VStack(alignment: .leading, spacing: 2) {
                Text(item.latestStatus)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(formatDeliveryID(item.deliveryID))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 日時
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.latestDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let time = item.latestTime {
                    Text(time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDeliveryID(_ id: Int) -> String {
        let str = String(id)
        if str.count == 12 {
            return "\(str.prefix(4))-\(str.dropFirst(4).prefix(4))-\(str.suffix(4))"
        }
        return str
    }
}

/// 配達アイテムの詳細行表示（大サイズ用）
struct DeliveryItemDetailRow: View {
    let item: WidgetDeliveryItem

    var body: some View {
        HStack(spacing: 12) {
            // ステータスインジケーター
            RoundedRectangle(cornerRadius: 4)
                .fill(item.statusType.color)
                .frame(width: 4, height: 40)

            // アイコン
            Image(systemName: item.statusType.icon)
                .font(.title3)
                .foregroundColor(item.statusType.color)
                .frame(width: 30)

            // 情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.latestStatus)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(item.latestDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let time = item.latestTime {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text(formatDeliveryID(item.deliveryID))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(item.shopName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func formatDeliveryID(_ id: Int) -> String {
        let str = String(id)
        if str.count == 12 {
            return "\(str.prefix(4))-\(str.dropFirst(4).prefix(4))-\(str.suffix(4))"
        }
        return str
    }
}

/// 空状態のビュー
struct EmptyStateView: View {
    let isSmall: Bool

    var body: some View {
        VStack(spacing: isSmall ? 8 : 16) {
            Image(systemName: "shippingbox")
                .font(isSmall ? .title2 : .largeTitle)
                .foregroundColor(.secondary)

            if isSmall {
                Text("配達なし")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    Text("配達アイテムがありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("タップしてアプリを開く")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Main Entry View

struct BlackCarWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Widget Configuration

@main
struct BlackCarWidget: Widget {
    let kind: String = "BlackCarWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                BlackCarWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .widgetURL(URL(string: "blackcat://delivery"))
            } else {
                BlackCarWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .widgetURL(URL(string: "blackcat://delivery"))
            }
        }
        .configurationDisplayName("配達状況")
        .description("配達中の荷物の最新状況を表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Extension for App

extension WidgetCenter {
    /// アプリからウィジェットのリロードをリクエストする
    static func reloadDeliveryWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "BlackCarWidget")
    }
}

// MARK: - Previews

struct BlackCarWidget_Previews: PreviewProvider {
    static var mockItems: [WidgetDeliveryItem] = [
        WidgetDeliveryItem(
            deliveryID: 123456789012,
            latestStatus: "配達中",
            latestDate: "01/29",
            latestTime: "14:30",
            shopName: "ヤマト運輸 新宿営業所",
            statusType: .delivering
        ),
        WidgetDeliveryItem(
            deliveryID: 987654321098,
            latestStatus: "輸送中",
            latestDate: "01/28",
            latestTime: "10:15",
            shopName: "佐川急便 渋谷営業所",
            statusType: .shipping
        ),
        WidgetDeliveryItem(
            deliveryID: 456789123456,
            latestStatus: "発送済み",
            latestDate: "01/27",
            latestTime: nil,
            shopName: "Amazon配送センター",
            statusType: .sended
        ),
        WidgetDeliveryItem(
            deliveryID: 111222333444,
            latestStatus: "荷物受付",
            latestDate: "01/26",
            latestTime: "09:00",
            shopName: "楽天物流センター",
            statusType: .received
        ),
        WidgetDeliveryItem(
            deliveryID: 555666777888,
            latestStatus: "配達完了",
            latestDate: "01/25",
            latestTime: "16:45",
            shopName: "日本郵便 品川局",
            statusType: .delivered
        )
    ]

    static var previewEntry: DeliveryEntry {
        DeliveryEntry(
            date: Date(),
            configuration: ConfigurationIntent(),
            deliveryItems: mockItems,
            lastUpdate: Date()
        )
    }

    static var previews: some View {
        Group {
            // Small Widget
            BlackCarWidgetEntryView(entry: previewEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")

            // Medium Widget
            BlackCarWidgetEntryView(entry: previewEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")

            // Large Widget
            BlackCarWidgetEntryView(entry: previewEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large")

            // Empty State - Small
            BlackCarWidgetEntryView(entry: DeliveryEntry.empty)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Empty - Small")

            // Empty State - Medium
            BlackCarWidgetEntryView(entry: DeliveryEntry.empty)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Empty - Medium")
        }
    }
}
