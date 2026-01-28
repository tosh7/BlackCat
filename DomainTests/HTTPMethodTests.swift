//
//  HTTPMethodTests.swift
//  DomainTests
//
//  Created by Code Review on 2026/01/29.
//

import XCTest
@testable import Domain

class HTTPMethodTests: XCTestCase {

    func test_post_rawValue() {
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
    }

    func test_get_rawValue() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
    }

    func test_post_notEqualToGet() {
        XCTAssertNotEqual(HTTPMethod.post, HTTPMethod.get)
    }
}
