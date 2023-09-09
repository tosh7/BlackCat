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
            public var time: String?
            public var shopName: String

            public init(status: String, date: String, time: String?, shopName: String) {
                self.status = status
                self.date = date
                self.time = time
                self.shopName = shopName
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
                if str.contains("お届け予定日時：") {
                    if initialIndex == indexCounter {
                        var counter = 0
                        let initialStatusGroup = stringList[index + 1].split(separator: " ")
                        if var countId = initialStatusGroup[0].split(separator: "\t")[safe: 0]?.description {
                            while countId.isValidStatusCode {
                                let statusCode = stringList[index + counter + 1].split(separator: " ")[0].split(separator: "\t")[safe: 1]?.description ?? ""
                                let newStatusGroup = stringList[index + counter + 1].split(separator: " ")
                                let date = newStatusGroup[1].split(separator: " ")[0].description.replacingOccurrences(of: "月", with: "/").replacingOccurrences(of: "日", with: "")
                                let time = (newStatusGroup[1].split(separator: " ")[safe: 1])?.description
                                let shopName = newStatusGroup[2].description
                                let status = Tneko.DeliveryList.DeliveryStatus(
                                    status: statusCode,
                                    date: date,
                                    time: time,
                                    shopName: shopName
                                )
                                newStatusList.append(status)
                                counter += 1
                                countId = stringList[index + counter + 1].split(separator: " ")[0].split(separator: "\t")[safe: 0]?.description ?? ""
                            }
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

private extension String {
    var isValidStatusCode: Bool {
        let pattern = "^[\\d]+.$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
        return matches.count > 0
    }
}
