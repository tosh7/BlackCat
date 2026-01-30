import XCTest
@testable import Domain

class SagawaTests: XCTestCase {
    let apiClient = ApiClient.shared
    
    func test_SagawaRequest_initialization() {
        let trackingNumber = "1234567890"
        let request = SagawaRequest(trackingNumber: trackingNumber)
        XCTAssertEqual(request.trackingNumber, trackingNumber)
        XCTAssertEqual(SagawaRequest.path, "web/okurijoinput.jsp")
        XCTAssertEqual(SagawaRequest.method, .post)
    }
    
    func test_SagawaRequest_encode() {
        let trackingNumber = "1234567890"
        let request = SagawaRequest(trackingNumber: trackingNumber)
        let encoded = request.encode()
        XCTAssertEqual(encoded["no"] as? String, trackingNumber)
    }
    
    func test_Sagawa_initialization() {
        let trackingInfo = Sagawa.TrackingInfo(
            trackingNumber: "1234567890",
            statusList: [
                .init(status: "集荷完了", date: "12/25", time: "14:30", location: "東京営業所"),
                .init(status: "配送中", date: "12/26", time: "09:15", location: "大阪営業所")
            ]
        )
        let sagawa = Sagawa(trackingList: [trackingInfo])
        XCTAssertEqual(sagawa.trackingList.count, 1)
        XCTAssertEqual(sagawa.trackingList[0].trackingNumber, "1234567890")
        XCTAssertEqual(sagawa.trackingList[0].statusList.count, 2)
    }
    
    func test_Sagawa_DeliveryStatus_initialization() {
        let status = Sagawa.TrackingInfo.DeliveryStatus(
            status: "配達完了",
            date: "12/27",
            time: "16:45",
            location: "神奈川営業所"
        )
        XCTAssertEqual(status.status, "配達完了")
        XCTAssertEqual(status.date, "12/27")
        XCTAssertEqual(status.time, "16:45")
        XCTAssertEqual(status.location, "神奈川営業所")
    }
    
    func test_Sagawa_parsing_mock_response() {
        let mockHTML = """
        <html>
        <body>
        <div>配達状況 集荷完了 12月25日 14:30 東京営業所</div>
        <div>輸送状況 配送中 12月26日 09:15 大阪営業所</div>
        </body>
        </html>
        """
        
        let sagawa = Sagawa(trackingNumber: "1234567890", response: mockHTML)
        XCTAssertEqual(sagawa.trackingList.count, 1)
        XCTAssertEqual(sagawa.trackingList[0].trackingNumber, "1234567890")
    }
    
    func test_Sagawa_empty_response() {
        let emptyHTML = "<html><body></body></html>"
        let sagawa = Sagawa(trackingNumber: "1234567890", response: emptyHTML)
        XCTAssertEqual(sagawa.trackingList.count, 1)
        XCTAssertEqual(sagawa.trackingList[0].trackingNumber, "1234567890")
        XCTAssertEqual(sagawa.trackingList[0].statusList.count, 0)
    }
}