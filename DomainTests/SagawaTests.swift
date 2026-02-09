import XCTest
@testable import Domain

class SagawaTests: XCTestCase {
    let apiClient = ApiClient.shared
    
    func test_SagawaRequest_initialization() {
        let trackingNumber = "1234567890"
        let request = SagawaRequest(trackingNumber: trackingNumber)
        XCTAssertEqual(request.trackingNumber, trackingNumber)
        XCTAssertEqual(SagawaRequest.path, "web/okurijosearch.do")
        XCTAssertEqual(SagawaRequest.method, .get)
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
        // NSAttributedString経由で変換された後のプレーンテキストを想定
        let mockText = """
        集荷 2/09 10:43 野田営業所
        輸送中 2/09 12:03 東関東中継センター
        """

        let sagawa = Sagawa(trackingNumber: "1234567890", response: mockText)
        XCTAssertEqual(sagawa.trackingList.count, 1)
        XCTAssertEqual(sagawa.trackingList[0].trackingNumber, "1234567890")
        XCTAssertEqual(sagawa.trackingList[0].statusList.count, 2)
        XCTAssertEqual(sagawa.trackingList[0].statusList[0].status, "集荷")
        XCTAssertEqual(sagawa.trackingList[0].statusList[0].date, "2/09")
        XCTAssertEqual(sagawa.trackingList[0].statusList[0].time, "10:43")
        XCTAssertEqual(sagawa.trackingList[0].statusList[0].location, "野田営業所")
        XCTAssertEqual(sagawa.trackingList[0].statusList[1].status, "輸送中")
        XCTAssertEqual(sagawa.trackingList[0].statusList[1].location, "東関東中継センター")
    }
    
    func test_Sagawa_empty_response() {
        let emptyHTML = "<html><body></body></html>"
        let sagawa = Sagawa(trackingNumber: "1234567890", response: emptyHTML)
        XCTAssertEqual(sagawa.trackingList.count, 1)
        XCTAssertEqual(sagawa.trackingList[0].trackingNumber, "1234567890")
        XCTAssertEqual(sagawa.trackingList[0].statusList.count, 0)
    }
}