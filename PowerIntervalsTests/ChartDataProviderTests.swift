//
//  ChartDataProvider.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 1/13/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import XCTest
@testable import PowerIntervals

class ChartDataProviderTests: XCTestCase {
    let powerZones = PowerZone()
    var dataPoints = [WorkoutDataPoint]()
    
    override func setUp() {
        super.setUp()
        
        let dataPoint1 = WorkoutDataPoint()
        dataPoint1.time = 0
        dataPoint1.watts = 0
        dataPoint1.deviceID = "dummy"
        
        let dataPoint2 = WorkoutDataPoint()
        dataPoint2.time = 100
        dataPoint2.watts = 1001
        dataPoint2.deviceID = "dummy"
        dataPoints = [dataPoint1, dataPoint2]
        
        powerZones.neuromuscular = 1000
        powerZones.anaerobicCapacity = 759
        powerZones.VO2Max = 600
        powerZones.lactateThreshold = 500
        powerZones.tempo = 350
        powerZones.endurance = 200
        powerZones.activeRecovery = 100

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testVerticalHeight() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let chartDataProvider = ChartDataProvider()
        chartDataProvider.dataPoints = dataPoints
        chartDataProvider.zones = powerZones
        
        let topLine1 = chartDataProvider.lineChartView(nil, verticalValueForHorizontalIndex: 0, atLineIndex: 0)
        XCTAssertTrue(topLine1 == 1001)
        
        let topLine2 = chartDataProvider.lineChartView(nil, verticalValueForHorizontalIndex: 1, atLineIndex: 0)
        XCTAssertTrue(topLine2 == 1001)
        
        let wattsValue0 = chartDataProvider.lineChartView(nil, verticalValueForHorizontalIndex: 0, atLineIndex: 7)
        XCTAssertTrue(wattsValue0 == 0)
        
        let wattsValue1 = chartDataProvider.lineChartView(nil, verticalValueForHorizontalIndex: 1, atLineIndex: 7)
        XCTAssertTrue(wattsValue1 == 1001)

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
