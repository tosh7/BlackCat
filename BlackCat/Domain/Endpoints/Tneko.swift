import Foundation

struct Tneko {
    var deriveryList: [DeliveryList]

    struct DeliveryList {
        var deliveryID: Int
        var statusList: [StatusList]

        init(deliveryID: Int, statusList: [Tneko.DeliveryList.StatusList]) {
            self.deliveryID = deliveryID
            self.statusList = statusList
        }

        struct StatusList {
            var status: String
            var date: String
            var time: String
            var shopName: String
            var shopID: String

            init(status: String, date: String, time: String, shopName: String, shopID: String) {
                self.status = status
                self.date = date
                self.time = time
                self.shopName = shopName
                self.shopID = shopID
            }
        }
    }
}

extension Tneko {
    init(idList: [Int], response: String) {
        self.deriveryList = idList.enumerated().map { initialIndex, id in
            let stringList = response.components(separatedBy: "\n")
            var newStatusList: [Tneko.DeliveryList.StatusList] = []
            var indexCounter = 0
            stringList.enumerated().forEach { index, str in
                if str == "担当店コード" {
                    if initialIndex == indexCounter {
                        var counter = 0
                        var statusCode = stringList[index + counter * 6 + 2]
                        while statusCode.isValidStatusCode {
                            let newIndex = index + counter * 6
                            let status = Tneko.DeliveryList.StatusList(
                                status: stringList[newIndex + 2],
                                date: stringList[newIndex + 3],
                                time: stringList[newIndex + 4],
                                shopName: stringList[newIndex + 5],
                                shopID: stringList[newIndex + 6]
                            )
                            newStatusList.append(status)
                            counter += 1
                            statusCode = stringList[index + counter * 6 + 2]
                        }
                    }
                    indexCounter += 1
                }
            }
            
            return DeliveryList(deliveryID: id, statusList: newStatusList)
        }
    }
}
