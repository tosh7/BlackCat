//
//  StateDetailViewModelTest.swift
//  BlackCatTests
//
//  Created by Code Review on 2026/01/29.
//

import XCTest
import Combine
@testable import BlackCat

final class StateDetailViewModelTest: XCTestCase {

    private var viewModel: StateDetailViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        viewModel = StateDetailViewModel()
        cancellables = []
    }

    override func tearDownWithError() throws {
        viewModel = nil
        cancellables = nil
    }

    // MARK: - Initial State Tests

    func test_initialState_showingAlertIsFalse() throws {
        XCTAssertFalse(viewModel.showingAlert)
    }

    // MARK: - Delete Item Tests

    func test_deleteDeliveryItem_setsShowingAlertToTrue() throws {
        let expectation = XCTestExpectation(description: "Alert is shown")

        viewModel.$showingAlert
            .dropFirst()
            .sink { showingAlert in
                if showingAlert {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.deleteDeliveryItem(id: 123456789012)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.showingAlert)
    }

    func test_deleteDeliveryItem_withDifferentIds_alwaysShowsAlert() throws {
        viewModel.deleteDeliveryItem(id: 111111111111)
        XCTAssertTrue(viewModel.showingAlert)

        viewModel.showingAlert = false

        viewModel.deleteDeliveryItem(id: 222222222222)
        XCTAssertTrue(viewModel.showingAlert)
    }
}
