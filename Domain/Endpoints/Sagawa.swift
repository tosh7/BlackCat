import Foundation

public struct SagawaRequest: RequestType, URLQueryEncodable {
    public static let path: String = "web/okurijosearch.do"
    public static let method: HTTPMethod = .get

    private let okurijoNo: String

    public init(trackingNumber: String) {
        self.okurijoNo = trackingNumber
    }

    var trackingNumber: String {
        return okurijoNo
    }
}

public struct Sagawa: ResponseType, Equatable {
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

extension Sagawa {
    public init(trackingNumber: String, response: String) {
        let parser = SagawaResponseParser()
        self.trackingList = parser.parse(trackingNumber: trackingNumber, htmlContent: response)
    }
}

private struct SagawaResponseParser {
    // 佐川急便のステータスキーワード
    private static let statusKeywords = [
        "集荷", "輸送中", "配達中", "配達完了", "持戻り", "不在",
        "保管中", "配送中", "到着", "出荷"
    ]

    // 場所を示すキーワード
    private static let locationKeywords = ["営業所", "センター", "店", "支店", "デポ"]

    // 日付パターン: M/DD, MM/DD, M月D日, MM月DD日
    private static let datePattern = #"(\d{1,2})/(\d{1,2})"#
    private static let japaneseDatePattern = #"(\d{1,2})月(\d{1,2})日"#

    // 時刻パターン: HH:MM
    private static let timePattern = #"\d{1,2}:\d{2}"#

    func parse(trackingNumber: String, htmlContent: String) -> [Sagawa.TrackingInfo] {
        var statusList: [Sagawa.TrackingInfo.DeliveryStatus] = []

        let lines = htmlContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in lines {
            let parsed = parseStatusLine(line)
            if let status = parsed.status,
               let date = parsed.date,
               let location = parsed.location {
                let deliveryStatus = Sagawa.TrackingInfo.DeliveryStatus(
                    status: status,
                    date: date,
                    time: parsed.time,
                    location: location
                )
                statusList.append(deliveryStatus)
            }
        }

        let trackingInfo = Sagawa.TrackingInfo(
            trackingNumber: trackingNumber,
            statusList: statusList
        )

        return [trackingInfo]
    }

    private func parseStatusLine(_ line: String) -> (status: String?, date: String?, time: String?, location: String?) {
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        var status: String?
        var date: String?
        var time: String?
        var location: String?

        for component in components {
            // 日付の検出（M月D日 形式）
            if date == nil,
               let match = component.range(of: Self.japaneseDatePattern, options: .regularExpression) {
                let matched = String(component[match])
                date = matched
                    .replacingOccurrences(of: "月", with: "/")
                    .replacingOccurrences(of: "日", with: "")
            }
            // 日付の検出（M/DD 形式）
            else if date == nil,
                    component.range(of: Self.datePattern, options: .regularExpression) != nil {
                date = component
            }
            // 時刻の検出
            else if time == nil,
                    component.range(of: Self.timePattern, options: .regularExpression) != nil {
                time = component
            }
            // 場所の検出
            else if location == nil,
                    Self.locationKeywords.contains(where: { component.contains($0) }) {
                location = component
            }
            // ステータスの検出
            else if status == nil,
                    Self.statusKeywords.contains(where: { component.contains($0) }) {
                status = component
            }
        }

        return (status: status, date: date, time: time, location: location)
    }
}