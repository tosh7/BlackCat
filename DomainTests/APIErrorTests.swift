//
//  APIErrorTests.swift
//  DomainTests
//
//  Created by Code Review on 2026/01/29.
//

import XCTest
@testable import Domain

class APIErrorTests: XCTestCase {

    // MARK: - Equatable Tests

    func test_invalidURL_equality() {
        XCTAssertEqual(APIError.invalidURL, APIError.invalidURL)
    }

    func test_timeout_equality() {
        XCTAssertEqual(APIError.timeout, APIError.timeout)
    }

    func test_noConnection_equality() {
        XCTAssertEqual(APIError.noConnection, APIError.noConnection)
    }

    func test_serverError_equalitySameCode() {
        XCTAssertEqual(APIError.serverError(statusCode: 500), APIError.serverError(statusCode: 500))
    }

    func test_serverError_equalityDifferentCode() {
        XCTAssertNotEqual(APIError.serverError(statusCode: 500), APIError.serverError(statusCode: 502))
    }

    func test_httpError_equality() {
        XCTAssertEqual(
            APIError.httpError(statusCode: 400, message: "Bad Request"),
            APIError.httpError(statusCode: 400, message: "Bad Request")
        )
    }

    func test_differentErrors_notEqual() {
        XCTAssertNotEqual(APIError.timeout, APIError.noConnection)
    }

    // MARK: - isRetryable Tests

    func test_timeout_isRetryable() {
        XCTAssertTrue(APIError.timeout.isRetryable)
    }

    func test_noConnection_isRetryable() {
        XCTAssertTrue(APIError.noConnection.isRetryable)
    }

    func test_serverError_isRetryable() {
        XCTAssertTrue(APIError.serverError(statusCode: 500).isRetryable)
        XCTAssertTrue(APIError.serverError(statusCode: 502).isRetryable)
        XCTAssertTrue(APIError.serverError(statusCode: 503).isRetryable)
    }

    func test_clientError_notRetryable() {
        XCTAssertFalse(APIError.badRequest("test").isRetryable)
        XCTAssertFalse(APIError.unauthorized.isRetryable)
        XCTAssertFalse(APIError.forbidden.isRetryable)
        XCTAssertFalse(APIError.notFound.isRetryable)
    }

    func test_invalidURL_notRetryable() {
        XCTAssertFalse(APIError.invalidURL.isRetryable)
    }

    func test_decodeError_notRetryable() {
        XCTAssertFalse(APIError.decodeError("test").isRetryable)
    }

    // MARK: - Error Description Tests

    func test_invalidURL_hasDescription() {
        XCTAssertNotNil(APIError.invalidURL.errorDescription)
        XCTAssertFalse(APIError.invalidURL.errorDescription!.isEmpty)
    }

    func test_timeout_hasDescription() {
        XCTAssertNotNil(APIError.timeout.errorDescription)
        XCTAssertFalse(APIError.timeout.errorDescription!.isEmpty)
    }

    func test_serverError_hasDescription() {
        let error = APIError.serverError(statusCode: 500)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("500"))
    }

    // MARK: - From StatusCode Tests

    func test_fromStatusCode_200_returnsNil() {
        XCTAssertNil(APIError.from(statusCode: 200))
    }

    func test_fromStatusCode_400_returnsBadRequest() {
        let error = APIError.from(statusCode: 400, data: nil)
        XCTAssertNotNil(error)
        if case .badRequest = error! {
            // Success
        } else {
            XCTFail("Expected badRequest error")
        }
    }

    func test_fromStatusCode_401_returnsUnauthorized() {
        let error = APIError.from(statusCode: 401)
        XCTAssertEqual(error, .unauthorized)
    }

    func test_fromStatusCode_403_returnsForbidden() {
        let error = APIError.from(statusCode: 403)
        XCTAssertEqual(error, .forbidden)
    }

    func test_fromStatusCode_404_returnsNotFound() {
        let error = APIError.from(statusCode: 404)
        XCTAssertEqual(error, .notFound)
    }

    func test_fromStatusCode_500_returnsServerError() {
        let error = APIError.from(statusCode: 500)
        XCTAssertEqual(error, .serverError(statusCode: 500))
    }

    func test_fromStatusCode_503_returnsServerError() {
        let error = APIError.from(statusCode: 503)
        XCTAssertEqual(error, .serverError(statusCode: 503))
    }
}
