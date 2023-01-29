import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {

    func placeholder(in context: Context) -> DeliveryItemEntry {
        let mockItem = TnekoMock.tnekoClient.deliveryList[0]
        return DeliveryItemEntry(date: Date(), configuration: ConfigurationIntent(), item: mockItem)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (DeliveryItemEntry) -> ()) {
        let item = WidgetDeliveryItem().getWidgetModel()
        let entry = DeliveryItemEntry(date: Date(), configuration: configuration, item: item)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [DeliveryItemEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let item = WidgetDeliveryItem().getWidgetModel()
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = DeliveryItemEntry(date: entryDate, configuration: configuration, item: item)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct DeliveryItemEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let item: DeliveryItem?
}

struct BlackCatWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let item = entry.item {
            LuggageItemGrid(deliveryItem: item)
        } else {
            Text("アプリからアイテムを追加してくれよな！")
        }
    }
}

@main
struct BlackCatWidget: Widget {
    let kind: String = "BlackCatWidget"
    let item = WidgetDeliveryItem().getWidgetModel()

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            BlackCatWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct BlackCatWidget_Previews: PreviewProvider {
    static var previews: some View {
        let mockItem = TnekoMock.tnekoClient.deliveryList[0]
        BlackCatWidgetEntryView(entry: DeliveryItemEntry(date: Date(), configuration: ConfigurationIntent(), item: mockItem))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
