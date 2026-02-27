//
//  BlackCatTests.swift
//  BlackCatTests
//
//  Created by Satoshi Komatsu on 2023/04/08.
//

import XCTest
@testable import BlackCat

final class BlackCatTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    // MARK: - DeliveryItem Tests

    func test_deliveryItem_hasUniqueId() throws {
        let item1 = makeDeliveryItem(deliveryID: 123456789012, statusList: [])
        let item2 = makeDeliveryItem(deliveryID: 123456789012, statusList: [])
        XCTAssertNotEqual(item1.id, item2.id)
    }

    func test_deliveryItem_storesDeliveryID() throws {
        let deliveryID = 123456789012
        let item = makeDeliveryItem(deliveryID: deliveryID, statusList: [])
        XCTAssertEqual(item.deliveryID, deliveryID)
    }

    func test_deliveryItem_storesStatusList() throws {
        let status = DeliveryStatus(status: "delivered", date: "01/01", time: "10:00", shopName: "TestShop")
        let item = makeDeliveryItem(deliveryID: 123456789012, statusList: [status])
        XCTAssertEqual(item.statusList.count, 1)
        XCTAssertEqual(item.statusList[0].status, "delivered")
    }

    // MARK: - DeliveryStatus Tests

    func test_deliveryStatus_storesAllProperties() throws {
        let status = DeliveryStatus(status: "delivered", date: "01/15", time: "14:30", shopName: "Tokyo Center")
        XCTAssertEqual(status.status, "delivered")
        XCTAssertEqual(status.date, "01/15")
        XCTAssertEqual(status.time, "14:30")
        XCTAssertEqual(status.shopName, "Tokyo Center")
    }

    func test_deliveryStatus_hasUniqueId() throws {
        let status1 = DeliveryStatus(status: "delivered", date: "01/01", time: "10:00", shopName: "Shop1")
        let status2 = DeliveryStatus(status: "delivered", date: "01/01", time: "10:00", shopName: "Shop1")
        XCTAssertNotEqual(status1.id, status2.id)
    }

    // MARK: - TnekoClient Tests

    func test_tnekoClient_hasUniqueId() throws {
        let client1 = makeTnekoClient(deliveryList: [])
        let client2 = makeTnekoClient(deliveryList: [])
        XCTAssertNotEqual(client1.id, client2.id)
    }

    func test_tnekoClient_storesDeliveryList() throws {
        let item = makeDeliveryItem(deliveryID: 123456789012, statusList: [])
        let client = makeTnekoClient(deliveryList: [item])
        XCTAssertEqual(client.deliveryList.count, 1)
    }

    // MARK: - TnekoMock Tests

    func test_tnekoMock_loadsJsonSuccessfully() throws {
        let tnekoClient = TnekoMock.tnekoClient
        XCTAssertFalse(tnekoClient.deliveryList.isEmpty)
    }

    func test_tnekoMock_hasCorrectNumberOfItems() throws {
        let tnekoClient = TnekoMock.tnekoClient
        XCTAssertEqual(tnekoClient.deliveryList.count, 6)
    }

    func test_tnekoMock_firstItemHasCorrectDeliveryID() throws {
        let tnekoClient = TnekoMock.tnekoClient
        XCTAssertEqual(tnekoClient.deliveryList[0].deliveryID, 429636181995)
    }

    func test_tnekoMock_firstItemHasCorrectStatusCount() throws {
        let tnekoClient = TnekoMock.tnekoClient
        XCTAssertEqual(tnekoClient.deliveryList[0].statusList.count, 5)
    }

    // MARK: - LocalDeliveryItems Tests

    func test_localDeliveryItems_sharedInstanceExists() throws {
        XCTAssertNotNil(LocalDeliveryItems.shared)
    }
}

// MARK: - Test Helpers

private func makeDeliveryItem(deliveryID: Int, statusList: [DeliveryStatus]) -> DeliveryItem {
    DeliveryItem(
        deliveryID: deliveryID,
        statusList: statusList,
        carrier: .yamato,
        registeredDate: Date()
    )
}

private func makeTnekoClient(deliveryList: [DeliveryItem]) -> TnekoClient {
    TnekoClient(deliveryList: deliveryList)
}
