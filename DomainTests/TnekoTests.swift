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
    let item327754459830 = Tneko.DeliveryList(deliveryID: 327754459830, statusList: [
        .init(status: "荷物受付", date: "10/09", time: "17:36", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "発送済み", date: "10/09", time: "17:36", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "配達担当店保管中", date: "10/10", time: "02:24", shopName: "墨田ＥＣデリバリーセンター"),
        .init(status: "配達完了（宅配ボックス）", date: "10/10", time: "13:10", shopName: "墨田ＥＣデリバリーセンター")
    ])
    let item292125879511 = Tneko.DeliveryList(deliveryID: 292125879511, statusList: [
        .init(status: "荷物受付", date: "09/19", time: "20:45", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "発送済み", date: "09/19", time: "20:45", shopName: "ＺＯＺＯつくば支店"),
        .init(status: "輸送中", date: "09/20", time: "02:35", shopName: "厚木ゲートウェイベース"),
        .init(status: "配達日・時間帯指定（保管中）", date: "09/20", time: "06:02", shopName: "茅ヶ崎赤羽根営業所（茅ヶ崎平和町）"),
        .init(status: "配達完了", date: "09/20", time: "16:10", shopName: "茅ヶ崎赤羽根営業所（茅ヶ崎平和町）")
    ])

    func test_Tneko_request_success_case() async {
        let result = await apiClient.tneko(.init(numbers: [327754459830, 292125879511]))
        XCTAssertEqual(Tneko(deriveryList: [item327754459830, item292125879511]), result.value)
    }

    func test_Tneko_request_single_success_case() async {
        let result = await apiClient.tneko(.init(numbers: [327754459830]))
        XCTAssertEqual(Tneko(deriveryList: [item327754459830]), result.value)
    }

    func test_Tneko_request_failure_case() async {
        let invalidId = 122
        let result = await apiClient.tneko(.init(numbers: [invalidId]))
        XCTAssertEqual(result.value, Tneko(deriveryList: [.init(deliveryID: invalidId, statusList: [])]))
    }

    func test_Tneko_request_empty_case() async {
        let result = await apiClient.tneko(.init(numbers: []))
        XCTAssertEqual(result.value, Tneko(deriveryList: []))
    }

}
