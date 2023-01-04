import Foundation

struct WidgetDeliveryItem {

    private let key = "WidgetItem"
    private let ud = UserDefaults.standard

    func addWidgetModel(deliveryItem: DeliveryItem) {
        ud.set(deliveryItem, forKey: key)
    }

    func getWidgetModel() -> DeliveryItem? {
        ud.object(forKey: key) as? DeliveryItem
    }

}
