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

public struct Tneko: ResponseType, Equatable {
    public var deliveryList: [DeliveryList]

    public struct DeliveryList: Codable, Equatable {
        public var deliveryID: Int
        public var statusList: [DeliveryStatus]

        public init(deliveryID: Int, statusList: [Tneko.DeliveryList.DeliveryStatus]) {
            self.deliveryID = deliveryID
            self.statusList = statusList
        }

        public struct DeliveryStatus: Codable, Equatable {
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

    public init(deliveryList: [DeliveryList]) {
        self.deliveryList = deliveryList
    }
}

extension Tneko {
    public init(idList: [Int], response: String) {
        self.deliveryList = idList.enumerated().map { initialIndex, id in
            let stringList = response.components(separatedBy: "\n")
            var newStatusList: [Tneko.DeliveryList.DeliveryStatus] = []
            var indexCounter = 0

            for (index, str) in stringList.enumerated() {
                if str.contains("お届け予定日時：") {
                    if initialIndex == indexCounter {
                        var currentIndex = index + 1

                        while currentIndex < stringList.count {
                            let currentLine = stringList[currentIndex].trimmingCharacters(in: .whitespaces)

                            // 次の荷物セクションまたはページの終わりを検出
                            if currentLine.contains("tracking-invoice-block-title") ||
                               currentLine.contains("page-content-information") {
                                break
                            }

                            // ステータス名を含む行を検出（<div class="item">で始まり、「：」を含まない）
                            if currentLine.hasPrefix("<div class=\"item\">") && !currentLine.contains("：") {
                                let statusName = currentLine
                                    .replacingOccurrences(of: "<div class=\"item\">", with: "")
                                    .replacingOccurrences(of: "</div>", with: "")
                                    .trimmingCharacters(in: .whitespaces)

                                // 空行をスキップして日付行を取得
                                var dateIndex = currentIndex + 1
                                while dateIndex < stringList.count {
                                    let dateLine = stringList[dateIndex].trimmingCharacters(in: .whitespaces)
                                    if dateLine.hasPrefix("<div class=\"date\">") {
                                        break
                                    }
                                    dateIndex += 1
                                }

                                var dateStr = ""
                                var timeStr: String?

                                if dateIndex < stringList.count {
                                    let dateLine = stringList[dateIndex]
                                        .replacingOccurrences(of: "<div class=\"date\">", with: "")
                                        .replacingOccurrences(of: "</div>", with: "")
                                        .trimmingCharacters(in: .whitespaces)

                                    let dateComponents = dateLine.split(separator: " ")
                                    if let first = dateComponents.first {
                                        dateStr = String(first)
                                            .replacingOccurrences(of: "月", with: "/")
                                            .replacingOccurrences(of: "日", with: "")
                                    }
                                    if dateComponents.count > 1 {
                                        timeStr = String(dateComponents[1])
                                    }
                                }

                                // 空行をスキップして店舗名行を取得
                                var nameIndex = dateIndex + 1
                                while nameIndex < stringList.count {
                                    let nameLine = stringList[nameIndex].trimmingCharacters(in: .whitespaces)
                                    if nameLine.hasPrefix("<div class=\"name\">") {
                                        break
                                    }
                                    nameIndex += 1
                                }

                                var shopName = ""
                                if nameIndex < stringList.count {
                                    var nameLine = stringList[nameIndex]
                                        .replacingOccurrences(of: "<div class=\"name\">", with: "")
                                        .replacingOccurrences(of: "</div>", with: "")

                                    // <a>タグから店舗名を抽出
                                    if nameLine.contains("<a href=") {
                                        if let startRange = nameLine.range(of: ">"),
                                           let endRange = nameLine.range(of: "</a>") {
                                            nameLine = String(nameLine[startRange.upperBound..<endRange.lowerBound])
                                        }
                                    }
                                    shopName = nameLine.trimmingCharacters(in: .whitespaces)
                                }

                                let status = Tneko.DeliveryList.DeliveryStatus(
                                    status: statusName,
                                    date: dateStr,
                                    time: timeStr,
                                    shopName: shopName
                                )
                                newStatusList.append(status)

                                currentIndex = nameIndex
                            }

                            currentIndex += 1
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
