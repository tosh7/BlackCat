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

    // MARK: - Debug Test for 508382115290

    func test_Debug_508382115290_buttonTap_flow() throws {
        let trackingNumber = "508382115290"

        print("=== DEBUG: AddListViewModel Button Tap Flow ===")

        // Set up expectations
        let loadingStarted = XCTestExpectation(description: "Loading started")
        let loadingFinished = XCTestExpectation(description: "Loading finished")
        let alertShown = XCTestExpectation(description: "Alert shown")

        // Track isLoading changes
        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                print("isLoading changed to: \(isLoading)")
                if isLoading {
                    loadingStarted.fulfill()
                } else {
                    loadingFinished.fulfill()
                }
            }
            .store(in: &cancellables)

        // Track showingAlert changes
        viewModel.$showingAlert
            .dropFirst()
            .sink { showing in
                print("showingAlert changed to: \(showing)")
                if showing {
                    print("errorMessage: \(self.viewModel.output.errorMessage)")
                    alertShown.fulfill()
                }
            }
            .store(in: &cancellables)

        // Step 1: Enter tracking number
        print("Step 1: Entering tracking number: \(trackingNumber)")
        viewModel.input.textFieldDidChange(text: trackingNumber)

        // Wait for button to become enabled
        let buttonEnabled = XCTestExpectation(description: "Button enabled")
        viewModel.$isButtonEnabled
            .dropFirst()
            .filter { $0 }
            .sink { _ in
                print("Button is now enabled")
                buttonEnabled.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [buttonEnabled], timeout: 2.0)
        print("isButtonEnabled: \(viewModel.output.isButtonEnabled)")
        print("selectedCarrier: \(viewModel.output.selectedCarrier)")

        // Step 2: Tap button
        print("Step 2: Tapping button...")
        viewModel.input.buttonDidTap()

        // Wait for all async operations
        wait(for: [loadingStarted, loadingFinished, alertShown], timeout: 10.0)

        // Step 3: Check result
        print("=== RESULT ===")
        print("errorMessage: \(viewModel.output.errorMessage)")
        print("showingAlert: \(viewModel.showingAlert)")

        // Assert
        XCTAssertEqual(viewModel.output.errorMessage, "登録に成功しました", "Registration should succeed for valid Yamato tracking number")
    }
}
