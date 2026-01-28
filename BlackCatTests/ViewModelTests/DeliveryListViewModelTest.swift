//
//  DeliveryListViewModelTest.swift
//  BlackCatTests
//
//  Created by Satoshi Komatsu on 2023/04/08.
//

import XCTest
import Combine
@testable import BlackCat

final class DeliveryListViewModelTest: XCTestCase {

    private var viewModel: DeliveryListViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        viewModel = DeliveryListViewModel()
        cancellables = []
    }

    override func tearDownWithError() throws {
        viewModel = nil
        cancellables = nil
    }

    func test_initialState_deliveryListIsEmpty() throws {
        XCTAssertTrue(viewModel.output.deliveryList.isEmpty)
    }

    func test_initialState_isLoadingIsFalse() throws {
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_onAppear_setsLoadingState() throws {
        let expectation = XCTestExpectation(description: "Loading state changes")

        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.input.onAppear()

        wait(for: [expectation], timeout: 3.0)
    }

    func test_pullToRefresh_triggersReload() throws {
        let expectation = XCTestExpectation(description: "Pull to refresh triggers reload")

        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.input.pullToRefresh()

        wait(for: [expectation], timeout: 3.0)
    }

    func test_deliveryList_conformsToProtocol() throws {
        XCTAssertNotNil(viewModel.input)
        XCTAssertNotNil(viewModel.output)
    }
}
