//
//  MatchMateUITests.swift
//  MatchMateUITests
//
//  Created by Sahana N B on 18/08/26.
//

import XCTest

final class MatchMateUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
