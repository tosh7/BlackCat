import Foundation

public struct TnekoRequest: RequestType, URLQueryEncodable {
    public static let path: String = "tneko"
    public static let method: HTTPMethod = .post

    private let number00: Int = 1
    private let number01: Int?
    private let number02: Int?
    private let number03: Int?
    private let number04: Int?
    private let number05: Int?
    private let number06: Int?
    private let number07: Int?
    private let number08: Int?
    private let number09: Int?
    private let number10: Int?

    public init(number01: Int?, number02: Int? = nil, number03: Int? = nil, number04: Int? = nil, number05: Int? = nil, number06: Int? = nil, number07: Int? = nil, number08: Int? = nil, number09: Int? = nil, number10: Int? = nil) {
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

    // should have at least one content
    public init(numbers: [Int]) {
        self.init(number01: numbers[safe: 0],
                  number02: numbers[safe: 1],
                  number03: numbers[safe: 2],
                  number04: numbers[safe: 3],
                  number05: numbers[safe: 4],
                  number06: numbers[safe: 5],
                  number07: numbers[safe: 6],
                  number08: numbers[safe: 7],
                  number09: numbers[safe: 8],
                  number10: numbers[safe: 9])
    }

    func idList() -> [Int] {
        let numbers: [Int?] = [
            number01,
            number02,
            number03,
            number04,
            number05,
            number06,
            number07,
            number08,
            number09,
            number10
        ]
        return numbers.compactMap { $0 }
    }
}

public struct Tneko: ResponseType {
    public var deriveryList: [DeliveryList]

    public struct DeliveryList: ResponseType {
        public var deliveryID: Int
        public var statusList: [DeliveryStatus]

        public init(deliveryID: Int, statusList: [Tneko.DeliveryList.DeliveryStatus]) {
            self.deliveryID = deliveryID
            self.statusList = statusList
        }

        public struct DeliveryStatus: ResponseType {
            public var status: String
            public var date: String
            public var time: String
            public var shopName: String
            public var shopID: String

            public init(status: String, date: String, time: String, shopName: String, shopID: String) {
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
    public init(idList: [Int], response: String) {
        self.deriveryList = idList.enumerated().map { initialIndex, id in
            let stringList = response.components(separatedBy: "\n")
            var newStatusList: [Tneko.DeliveryList.DeliveryStatus] = []
            var indexCounter = 0
            stringList.enumerated().forEach { index, str in
                if str == "担当店コード" {
                    if initialIndex == indexCounter {
                        var counter = 0
                        var statusCode = stringList[index + counter * 6 + 2]
                        while statusCode.isValidStatusCode {
                            let newIndex = index + counter * 6
                            let status = Tneko.DeliveryList.DeliveryStatus(
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

extension Array {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension String {
    var isValidStatusCode: Bool {
        return self == "荷物受付" || self == "発送済み" || self == "輸送中" || self == "配達中" || self == "配達完了"
    }
}
