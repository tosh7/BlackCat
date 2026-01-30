import XCTest
@testable import Domain

class JapanPostTests: XCTestCase {
    let apiClient = ApiClient.shared

    func test_JapanPostRequest_initialization() {
        let trackingNumber = "123456789012"
        let request = JapanPostRequest(trackingNumber: trackingNumber)
        XCTAssertEqual(request.trackingNumber, trackingNumber)
        XCTAssertEqual(JapanPostRequest.path, "services/srv/search/")
        XCTAssertEqual(JapanPostRequest.method, .post)
    }

    func test_JapanPostRequest_encode() {
        let trackingNumber = "123456789012"
        let request = JapanPostRequest(trackingNumber: trackingNumber)
        let encoded = request.encode()
        XCTAssertEqual(encoded["requestNo1"] as? String, trackingNumber)
        XCTAssertEqual(encoded["locale"] as? String, "ja")
    }

    func test_JapanPost_initialization() {
        let trackingInfo = JapanPost.TrackingInfo(
            trackingNumber: "123456789012",
            statusList: [
                .init(status: "引受", date: "1/15", time: "10:30", location: "東京中央郵便局"),
                .init(status: "到着", date: "1/16", time: "08:45", location: "大阪中央郵便局")
            ]
        )
        let japanPost = JapanPost(trackingList: [trackingInfo])
        XCTAssertEqual(japanPost.trackingList.count, 1)
        XCTAssertEqual(japanPost.trackingList[0].trackingNumber, "123456789012")
        XCTAssertEqual(japanPost.trackingList[0].statusList.count, 2)
    }

    func test_JapanPost_DeliveryStatus_initialization() {
        let status = JapanPost.TrackingInfo.DeliveryStatus(
            status: "お届け先にお届け済み",
            date: "1/17",
            time: "14:30",
            location: "新宿郵便局"
        )
        XCTAssertEqual(status.status, "お届け先にお届け済み")
        XCTAssertEqual(status.date, "1/17")
        XCTAssertEqual(status.time, "14:30")
        XCTAssertEqual(status.location, "新宿郵便局")
    }

    func test_JapanPost_parsing_mock_response() {
        let mockHTML = """
        <html>
        <body>
        <table>
        <tr><td>1月15日</td><td>10:30</td><td>引受</td><td>東京中央郵便局</td></tr>
        <tr><td>1月16日</td><td>08:45</td><td>到着</td><td>大阪中央郵便局</td></tr>
        </table>
        </body>
        </html>
        """

        let japanPost = JapanPost(trackingNumber: "123456789012", response: mockHTML)
        XCTAssertEqual(japanPost.trackingList.count, 1)
        XCTAssertEqual(japanPost.trackingList[0].trackingNumber, "123456789012")
    }

    func test_JapanPost_empty_response() {
        let emptyHTML = "<html><body></body></html>"
        let japanPost = JapanPost(trackingNumber: "123456789012", response: emptyHTML)
        XCTAssertEqual(japanPost.trackingList.count, 1)
        XCTAssertEqual(japanPost.trackingList[0].trackingNumber, "123456789012")
        XCTAssertEqual(japanPost.trackingList[0].statusList.count, 0)
    }

    func test_JapanPost_toUnifiedDeliveryInfo() {
        let trackingInfo = JapanPost.TrackingInfo(
            trackingNumber: "123456789012",
            statusList: [
                .init(status: "引受", date: "1/15", time: "10:30", location: "東京中央郵便局"),
                .init(status: "お届け先にお届け済み", date: "1/16", time: "14:00", location: "新宿郵便局")
            ]
        )
        let japanPost = JapanPost(trackingList: [trackingInfo])
        let unifiedInfos = japanPost.toUnifiedDeliveryInfo()

        XCTAssertEqual(unifiedInfos.count, 1)
        XCTAssertEqual(unifiedInfos[0].trackingNumber, "123456789012")
        XCTAssertEqual(unifiedInfos[0].carrier, .japanPost)
        XCTAssertEqual(unifiedInfos[0].statusList.count, 2)
        XCTAssertEqual(unifiedInfos[0].statusList[0].status, "引受")
        XCTAssertEqual(unifiedInfos[0].statusList[1].status, "お届け先にお届け済み")
    }

    func test_JapanPost_isDelivered() {
        let deliveredInfo = JapanPost.TrackingInfo(
            trackingNumber: "123456789012",
            statusList: [
                .init(status: "お届け先にお届け済み", date: "1/16", time: "14:00", location: "新宿郵便局")
            ]
        )
        let japanPost = JapanPost(trackingList: [deliveredInfo])
        let unifiedInfos = japanPost.toUnifiedDeliveryInfo()

        XCTAssertTrue(unifiedInfos[0].isDelivered)
    }

    func test_JapanPost_notDelivered() {
        let inTransitInfo = JapanPost.TrackingInfo(
            trackingNumber: "123456789012",
            statusList: [
                .init(status: "到着", date: "1/15", time: "08:45", location: "大阪中央郵便局")
            ]
        )
        let japanPost = JapanPost(trackingList: [inTransitInfo])
        let unifiedInfos = japanPost.toUnifiedDeliveryInfo()

        XCTAssertFalse(unifiedInfos[0].isDelivered)
    }

    func test_JapanPostRequest_DeliveryTrackingRequestProtocol() {
        let request = JapanPostRequest(trackingNumber: "123456789012")
        XCTAssertEqual(request.trackingNumbers, ["123456789012"])
        XCTAssertEqual(request.carrier, .japanPost)
    }

    func test_DeliveryCarrierType_japanPost() {
        let carrier = DeliveryCarrierType.japanPost
        XCTAssertEqual(carrier.rawValue, "japanPost")
        XCTAssertEqual(carrier.displayName, "日本郵便")
    }
}
