//
//  PowerIntervalsUITests.swift
//  PowerIntervalsUITests
//
//  Created by Roderic Campbell on 1/25/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import XCTest

class PowerIntervalsUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRunTheApp() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        // The first power meter's chart
        snapshot("Workout")
        
        // Tap on the 2nd power meter and get a picture
        app.collectionViews.staticTexts["1101 w"].tap()
        snapshot("Beautiful")

        // Start the interval flow
        app.buttons["Interval"].tap()
        snapshot("IntervalSetup")

        // Begin an actual Interval
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).tap()

        // Go to the settings/zone selection
        XCUIApplication().buttons["Settings"].tap()
        snapshot("Zones")

    }
    
}
