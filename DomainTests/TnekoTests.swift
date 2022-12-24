//
//  DomainTests.swift
//  DomainTests
//
//  Created by tosh on 2021/08/09.
//

import XCTest
@testable import Domain

class TnekoTests: XCTestCase {
    let apiClient = ApiClient.shared
    let request = TnekoRequest(numbers: [327754459830])
    let tneko = Tneko(deriveryList: [
        .init(deliveryID: 327754459830, statusList: [
            .init(status: "荷物受付", date: "10/09", time: "17:36", shopName: "ＺＯＺＯつくば支店"),
            .init(status: "発送済み", date: "10/09", time: "17:36", shopName: "ＺＯＺＯつくば支店"),
            .init(status: "配達担当店保管中", date: "10/10", time: "02:24", shopName: "墨田ＥＣデリバリーセンター"),
            .init(status: "配達完了（宅配ボックス）", date: "10/10", time: "13:10", shopName: "墨田ＥＣデリバリーセンター")
        ])
    ])

    func test_Tneko_request_success_case() async {
        let result = await apiClient.tneko(request)
        XCTAssertEqual(tneko, result.value)
    }

    func test_Tneko_request_failure_case() async {
        let invalidId = 122
        let result = await apiClient.tneko(.init(numbers: [invalidId]))
        XCTAssertEqual(result.value, Tneko(deriveryList: [.init(deliveryID: invalidId, statusList: [])]))
    }

}
