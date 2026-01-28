//
//  AddListViewModelTest.swift
//  BlackCatTests
//
//  Created by Code Review on 2026/01/29.
//

import XCTest
import Combine
@testable import BlackCat

final class AddListViewModelTest: XCTestCase {

    private var viewModel: AddListViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        viewModel = AddListViewModel()
        cancellables = []
    }

    override func tearDownWithError() throws {
        viewModel = nil
        cancellables = nil
    }

    // MARK: - Initial State Tests

    func test_initialState_isButtonEnabledIsFalse() throws {
        XCTAssertFalse(viewModel.output.isButtonEnabled)
    }

    func test_initialState_errorMessageIsEmpty() throws {
        XCTAssertTrue(viewModel.output.errorMessage.isEmpty)
    }

    func test_initialState_cautionMessageIsEmpty() throws {
        XCTAssertTrue(viewModel.output.cautionMessage.isEmpty)
    }

    func test_initialState_showingAlertIsFalse() throws {
        XCTAssertFalse(viewModel.showingAlert)
    }

    func test_initialState_selectedCarrierIsYamato() throws {
        XCTAssertEqual(viewModel.output.selectedCarrier, .yamato)
    }

    // MARK: - Text Field Input Tests

    func test_textFieldDidChange_withValidInput_enablesButton() throws {
        let expectation = XCTestExpectation(description: "Button becomes enabled")

        viewModel.$isButtonEnabled
            .dropFirst()
            .sink { isEnabled in
                if isEnabled {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.input.textFieldDidChange(text: "123456789012")

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.output.isButtonEnabled)
    }

    func test_textFieldDidChange_withShortInput_disablesButton() throws {
        viewModel.input.textFieldDidChange(text: "12345")

        let expectation = XCTestExpectation(description: "Wait for processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertFalse(viewModel.output.isButtonEnabled)
    }

    func test_textFieldDidChange_withNonNumericInput_showsCautionMessage() throws {
        let expectation = XCTestExpectation(description: "Caution message appears")

        viewModel.$cautionMessage
            .dropFirst()
            .sink { message in
                if !message.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.input.textFieldDidChange(text: "abc")

        wait(for: [expectation], timeout: 1.0)
    }

    func test_textFieldDidChange_withEmptyInput_clearsCautionMessage() throws {
        viewModel.input.textFieldDidChange(text: "")

        let expectation = XCTestExpectation(description: "Wait for processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(viewModel.output.cautionMessage.isEmpty)
    }

    // MARK: - Protocol Conformance Tests

    func test_viewModel_conformsToAddListViewModelType() throws {
        XCTAssertNotNil(viewModel.input)
        XCTAssertNotNil(viewModel.output)
    }
}
