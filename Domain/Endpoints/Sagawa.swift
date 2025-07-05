import Foundation

public struct SagawaRequest: RequestType, URLQueryEncodable {
    public static let path: String = "web/okurijoinput.jsp"
    public static let method: HTTPMethod = .post
    
    private let no: String
    
    public init(trackingNumber: String) {
        self.no = trackingNumber
    }
    
    var trackingNumber: String {
        return no
    }
    
    public func encode() -> [String: Any] {
        return ["no": no]
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
    func parse(trackingNumber: String, htmlContent: String) -> [Sagawa.TrackingInfo] {
        var statusList: [Sagawa.TrackingInfo.DeliveryStatus] = []
        
        let lines = htmlContent.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            if line.contains("配達状況") || line.contains("輸送状況") {
                let statusInfo = parseStatusLine(line)
                if let status = statusInfo.status, 
                   let date = statusInfo.date,
                   let location = statusInfo.location {
                    let deliveryStatus = Sagawa.TrackingInfo.DeliveryStatus(
                        status: status,
                        date: date,
                        time: statusInfo.time,
                        location: location
                    )
                    statusList.append(deliveryStatus)
                }
            }
        }
        
        let trackingInfo = Sagawa.TrackingInfo(
            trackingNumber: trackingNumber,
            statusList: statusList
        )
        
        return [trackingInfo]
    }
    
    private func parseStatusLine(_ line: String) -> (status: String?, date: String?, time: String?, location: String?) {
        let cleanLine = line.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let components = cleanLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var status: String?
        var date: String?
        var time: String?
        var location: String?
        
        for component in components {
            if component.contains("月") && component.contains("日") {
                date = component.replacingOccurrences(of: "月", with: "/").replacingOccurrences(of: "日", with: "")
            } else if component.contains(":") {
                time = component
            } else if component.contains("営業所") || component.contains("センター") || component.contains("店") {
                location = component
            } else if component.contains("集荷") || component.contains("配送") || component.contains("到着") || component.contains("完了") {
                status = component
            }
        }
        
        return (status: status, date: date, time: time, location: location)
    }
}