import Foundation

public struct JapanPostRequest: RequestType, URLQueryEncodable {
    public static let path: String = "services/srv/search/"
    public static let method: HTTPMethod = .post

    private let trackingNo: String

    public init(trackingNumber: String) {
        self.trackingNo = trackingNumber
    }

    var trackingNumber: String {
        return trackingNo
    }

    public func encode() -> [String: Any] {
        return [
            "requestNo1": trackingNo,
            "locale": "ja"
        ]
    }
}

public struct JapanPost: ResponseType, Equatable {
    public var trackingList: [TrackingInfo]

    public struct TrackingInfo: Codable, Equatable {
        public var trackingNumber: String
        public var statusList: [DeliveryStatus]

        public init(trackingNumber: String, statusList: [DeliveryStatus]) {
            self.trackingNumber = trackingNumber
            self.statusList = statusList
        }

        public struct DeliveryStatus: Codable, Equatable {
            public var status: String
            public var date: String
            public var time: String?
            public var location: String

            public init(status: String, date: String, time: String?, location: String) {
                self.status = status
                self.date = date
                self.time = time
                self.location = location
            }
        }
    }

    public init(trackingList: [TrackingInfo]) {
        self.trackingList = trackingList
    }
}

extension JapanPost {
    public init(trackingNumber: String, response: String) {
        let parser = JapanPostResponseParser()
        self.trackingList = parser.parse(trackingNumber: trackingNumber, htmlContent: response)
    }
}

private struct JapanPostResponseParser {
    func parse(trackingNumber: String, htmlContent: String) -> [JapanPost.TrackingInfo] {
        var statusList: [JapanPost.TrackingInfo.DeliveryStatus] = []

        let lines = htmlContent.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            // 日本郵便の追跡ページでは、ステータス情報がテーブル形式で表示される
            // 「引受」「到着」「お届け先にお届け済み」などのキーワードを検索
            if containsStatusKeyword(line) {
                let statusInfo = parseStatusLine(lines, startIndex: index)
                if let status = statusInfo.status,
                   let date = statusInfo.date,
                   let location = statusInfo.location {
                    let deliveryStatus = JapanPost.TrackingInfo.DeliveryStatus(
                        status: status,
                        date: date,
                        time: statusInfo.time,
                        location: location
                    )
                    statusList.append(deliveryStatus)
                }
            }
        }

        let trackingInfo = JapanPost.TrackingInfo(
            trackingNumber: trackingNumber,
            statusList: statusList
        )

        return [trackingInfo]
    }

    private func containsStatusKeyword(_ line: String) -> Bool {
        let keywords = [
            "引受",
            "到着",
            "発送",
            "通過",
            "配達中",
            "お届け先にお届け済み",
            "お届け済み",
            "持ち出し中",
            "ご不在のため持ち戻り",
            "保管"
        ]
        return keywords.contains { line.contains($0) }
    }

    private func parseStatusLine(_ lines: [String], startIndex: Int) -> (status: String?, date: String?, time: String?, location: String?) {
        // 現在の行とその前後の行を解析してステータス情報を抽出
        var status: String?
        var date: String?
        var time: String?
        var location: String?

        // 検索範囲を現在の行から前後数行に限定
        let startRange = max(0, startIndex - 2)
        let endRange = min(lines.count - 1, startIndex + 2)

        for i in startRange...endRange {
            let line = lines[i]
            let cleanLine = line.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            // ステータスの抽出
            if status == nil {
                status = extractStatus(from: cleanLine)
            }

            // 日付の抽出（例: 1月15日、2024/01/15、01/15など）
            if date == nil {
                date = extractDate(from: cleanLine)
            }

            // 時刻の抽出（例: 14:30、14時30分など）
            if time == nil {
                time = extractTime(from: cleanLine)
            }

            // 場所の抽出（郵便局名など）
            if location == nil {
                location = extractLocation(from: cleanLine)
            }
        }

        return (status: status, date: date, time: time, location: location)
    }

    private func extractStatus(from text: String) -> String? {
        let statusKeywords = [
            "お届け先にお届け済み",
            "お届け済み",
            "ご不在のため持ち戻り",
            "持ち出し中",
            "配達中",
            "到着",
            "発送",
            "通過",
            "引受",
            "保管"
        ]

        for keyword in statusKeywords {
            if text.contains(keyword) {
                return keyword
            }
        }
        return nil
    }

    private func extractDate(from text: String) -> String? {
        // パターン1: 1月15日 形式
        let pattern1 = "(\\d{1,2})月(\\d{1,2})日"
        if let regex = try? NSRegularExpression(pattern: pattern1),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let monthRange = Range(match.range(at: 1), in: text),
               let dayRange = Range(match.range(at: 2), in: text) {
                let month = String(text[monthRange])
                let day = String(text[dayRange])
                return "\(month)/\(day)"
            }
        }

        // パターン2: 2024/01/15 または 01/15 形式
        let pattern2 = "(\\d{2,4})/(\\d{1,2})/(\\d{1,2})"
        if let regex = try? NSRegularExpression(pattern: pattern2),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let monthRange = Range(match.range(at: 2), in: text),
               let dayRange = Range(match.range(at: 3), in: text) {
                let month = String(text[monthRange])
                let day = String(text[dayRange])
                return "\(month)/\(day)"
            }
        }

        return nil
    }

    private func extractTime(from text: String) -> String? {
        // パターン1: 14:30 形式
        let pattern1 = "(\\d{1,2}):(\\d{2})"
        if let regex = try? NSRegularExpression(pattern: pattern1),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
        }

        // パターン2: 14時30分 形式
        let pattern2 = "(\\d{1,2})時(\\d{1,2})分"
        if let regex = try? NSRegularExpression(pattern: pattern2),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let hourRange = Range(match.range(at: 1), in: text),
               let minRange = Range(match.range(at: 2), in: text) {
                let hour = String(text[hourRange])
                let min = String(text[minRange])
                return "\(hour):\(min)"
            }
        }

        return nil
    }

    private func extractLocation(from text: String) -> String? {
        // 郵便局名のパターン（○○郵便局）
        let pattern = "([\\u4E00-\\u9FFF\\u3040-\\u309F\\u30A0-\\u30FF]+郵便局)"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }

        // 「○○支店」や「○○センター」のパターン
        let patterns = ["支店", "センター", "局"]
        for suffix in patterns {
            if text.contains(suffix) {
                let components = text.components(separatedBy: .whitespaces)
                for component in components {
                    if component.contains(suffix) && component.count >= 3 {
                        return component
                    }
                }
            }
        }

        return nil
    }
}
