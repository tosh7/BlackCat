import Foundation

// FIXME: initialization isn't right code, gotta fix it!
struct Tneko {
    var deriveryList: [DeliveryList]

    struct DeliveryList {
        var deliveryID: Int
        var statusList: [StatusList]

        init(deliveryID: Int, statusList: String) {
            self.deliveryID = deliveryID
            self.statusList = statusList.components(separatedBy: "\n").map {
                StatusList(statusList: $0)
            }
        }

        struct StatusList {
            var status: String
            var date: String
            var time: String
            var shopName: String
            var shopID: String

            init(statusList: String) {
                let separatedStatusList = statusList.components(separatedBy: "\n")
                self.status = separatedStatusList[0]
                self.date = separatedStatusList[1]
                self.time = separatedStatusList[2]
                self.shopName = separatedStatusList[3]
                self.shopID = separatedStatusList[4]
            }
        }
    }
}

extension Tneko {
    init(idList: [Int], response: String) {
        self.deriveryList = idList.map {
            DeliveryList(deliveryID: $0, statusList: response)
        }
    }
}
