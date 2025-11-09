//
//  SimpleTests.swift
//  LifeCompanionTests
//
//  Created on November 9, 2025.
//

import XCTest

final class SimpleTests: XCTestCase {

    func testBasicXCTest() throws {
        XCTAssertTrue(true)
        XCTAssertFalse(false)
        XCTAssertEqual(1, 1)
        XCTAssertNotEqual(1, 2)
    }

    func testStringOperations() throws {
        let str = "Hello World"
        XCTAssertEqual(str.count, 11)
        XCTAssertTrue(str.contains("World"))
        XCTAssertFalse(str.contains("xyz"))
    }

    func testArrayOperations() throws {
        let numbers = [1, 2, 3, 4, 5]
        XCTAssertEqual(numbers.count, 5)
        XCTAssertEqual(numbers.first, 1)
        XCTAssertEqual(numbers.last, 5)
    }

    func testPerformanceExample() throws {
        self.measure {
            let _ = (0...1000).map { $0 * 2 }
        }
    }
}