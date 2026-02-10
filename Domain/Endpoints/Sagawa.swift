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

    /// 佐川のHTMLをパースして配達ステータスリストを生成
    /// データは3行1セットで構成される:
    ///   行1: ステータス (例: "↓集荷", "↓輸送中", "⇒配達完了")
    ///   行2: 日時 (例: "02/09 10:43")
    ///   行3: 営業所 (例: "野田営業所")
    func parse(trackingNumber: String, htmlContent: String) -> [Sagawa.TrackingInfo] {

        var statusList: [Sagawa.TrackingInfo.DeliveryStatus] = []

        let lines = htmlContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // State machine: collect status → date/time → location across lines
        var pendingStatus: String?
        var pendingDate: String?
        var pendingTime: String?

        for line in lines {
            let lineType = classifyLine(line)

            switch lineType {
            case .status(let status):
                // New status found — flush any incomplete pending entry
                pendingStatus = status
                pendingDate = nil
                pendingTime = nil

            case .dateTime(let date, let time):
                if pendingStatus != nil {
                    pendingDate = date
                    pendingTime = time
                }

            case .location(let location):
                if let status = pendingStatus, let date = pendingDate {
                    let entry = Sagawa.TrackingInfo.DeliveryStatus(
                        status: status,
                        date: date,
                        time: pendingTime,
                        location: location
                    )
                    statusList.append(entry)
                }
                pendingStatus = nil
                pendingDate = nil
                pendingTime = nil

            case .other:
                break
            }
        }

        return [Sagawa.TrackingInfo(trackingNumber: trackingNumber, statusList: statusList)]
    }

    // MARK: - Line Classification

    private enum LineType {
        case status(String)
        case dateTime(date: String, time: String?)
        case location(String)
        case other
    }

    private func classifyLine(_ line: String) -> LineType {
        // ステータス判定: "↓集荷", "↓輸送中", "⇒配達完了" など
        if Self.statusKeywords.contains(where: { line.contains($0) }) {
            // 先頭の矢印記号を除去してステータス名を取得
            let cleaned = line.replacingOccurrences(of: "↓", with: "")
                              .replacingOccurrences(of: "⇒", with: "")
                              .trimmingCharacters(in: .whitespaces)
            return .status(cleaned)
        }

        // 日時判定: "02/09 10:43" or "02月09日"
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if let firstComp = components.first {
            // MM/DD形式
            if firstComp.range(of: Self.datePattern, options: .regularExpression) != nil {
                let time = components.count > 1 && components[1].range(of: Self.timePattern, options: .regularExpression) != nil
                    ? components[1] : nil
                return .dateTime(date: firstComp, time: time)
            }
            // M月D日形式
            if let match = firstComp.range(of: Self.japaneseDatePattern, options: .regularExpression) {
                let matched = String(firstComp[match])
                let date = matched
                    .replacingOccurrences(of: "月", with: "/")
                    .replacingOccurrences(of: "日", with: "")
                let time = components.count > 1 && components[1].range(of: Self.timePattern, options: .regularExpression) != nil
                    ? components[1] : nil
                return .dateTime(date: date, time: time)
            }
        }

        // 場所判定: "野田営業所", "東関東中継センター" など
        if Self.locationKeywords.contains(where: { line.contains($0) }) {
            // TEL/FAX情報を除去して営業所名のみ取得
            let name = components.first ?? line
            return .location(name)
        }

        return .other
    }
}