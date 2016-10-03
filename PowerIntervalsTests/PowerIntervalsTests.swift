//
//  PowerIntervalsTests.swift
//  PowerIntervalsTests
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import XCTest
import RealmSwift

@testable import PowerIntervals

class FakeDelegate: WahooHardwareDelegate {
    func hardwareConnectedState(sensor: PowerMeter, connected: Bool) {
        print("hardwareConnected")
    }
    func hardwareDebug(sensor: PowerMeter, message: String) {
        print("hardwareDebug")
    }
}

class WFBikePowerConnectionMock: WFBikePowerConnection {
    var deviceID: String
    override var deviceIDString: String! {
        return deviceID
    }
    
    init(deviceIDString: String) {
        deviceID = deviceIDString
    }
    
    override func getBikePowerData() -> WFBikePowerData! {
        let mockBikePowerData = WFBikePowerDataMock()
        return mockBikePowerData
    }
}

class WFHardwareConnectorMock: WFHardwareConnector {
    
}

class WFBikePowerDataMock: WFBikePowerData {
    
}

class PowerIntervalsTests: XCTestCase {
    var hardware: WahooHardware?
    var mockConnector: WFHardwareConnectorMock?
    var hardwareDelegate: FakeDelegate?
    
    override func setUp() {
        super.setUp()
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        mockConnector = WFHardwareConnectorMock()

        let hardwareDelegate = FakeDelegate()
        hardware = WahooHardware(hardwareDelegate: hardwareDelegate)
        hardware?.startHardware()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Create 1 new device, connect it to verify that the internal
    // data model retains 1 device
    func testNewDevice() {
        guard let hardware = hardware, let mockConnector = mockConnector else {
            return
        }
        let mockPowerMeter = WFBikePowerConnectionMock(deviceIDString: "TestID")
        hardware.hardwareConnector(mockConnector, connectedSensor: mockPowerMeter)
        XCTAssertEqual(hardware.connectedWahooDevices.count, 1)
    }
    
    // Create 2 devices, connect them both to verify that the 
    // internal data model retains these 2 devices
    func test2NewDevices() {
        guard let hardware = hardware, let mockConnector = mockConnector else {
            return
        }
        let mockPowerMeter = WFBikePowerConnectionMock(deviceIDString: "testID")
        let mockPowerMeter2 = WFBikePowerConnectionMock(deviceIDString: "testID2")
        hardware.hardwareConnector(mockConnector, connectedSensor: mockPowerMeter)
        hardware.hardwareConnector(mockConnector, connectedSensor: mockPowerMeter2)
        XCTAssertEqual(hardware.connectedWahooDevices.count, 2)
    }
    
    // Create a device, connect it, then disconnect it to verify that disconnecting
    // devices get removed from the internal datamodel
    func testDeleteDevice() {
        guard let hardware = hardware, let mockConnector = mockConnector else {
            return
        }
        
        let mockPowerMeter = WFBikePowerConnectionMock(deviceIDString: "testID")
        hardware.hardwareConnector(mockConnector, connectedSensor: mockPowerMeter)
        hardware.hardwareConnector(mockConnector, disconnectedSensor: mockPowerMeter)
        XCTAssertEqual(hardware.connectedWahooDevices.count, 0)
    }
    
}
