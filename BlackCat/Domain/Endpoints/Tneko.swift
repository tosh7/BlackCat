import Foundation

struct TnekoRequest: RequestType, URLQueryEncodable {
    static let path: String = "tneko"
    static let method: HTTPMethod = .post

    private let number00: Int = 1
    private let number01: Int
    private let number02: Int?
    private let number03: Int?
    private let number04: Int?
    private let number05: Int?
    private let number06: Int?
    private let number07: Int?
    private let number08: Int?
    private let number09: Int?
    private let number10: Int?

    init(number01: Int, number02: Int? = nil, number03: Int? = nil, number04: Int? = nil, number05: Int? = nil, number06: Int? = nil, number07: Int? = nil, number08: Int? = nil, number09: Int? = nil, number10: Int? = nil) {
        self.number01 = number01
        self.number02 = number02
        self.number03 = number03
        self.number04 = number04
        self.number05 = number05
        self.number06 = number06
        self.number07 = number07
        self.number08 = number08
        self.number09 = number09
        self.number10 = number10
    }
}

struct Tneko: ResponseType {
    var deriveryList: [DeliveryList]

    struct DeliveryList: ResponseType {
        var deliveryID: Int
        var statusList: [StatusList]

        init(deliveryID: Int, statusList: [Tneko.DeliveryList.StatusList]) {
            self.deliveryID = deliveryID
            self.statusList = statusList
        }

        struct StatusList: ResponseType {
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
