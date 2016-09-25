//
//  FakePowerMeter.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import RealmSwift

class FakePowerMeter: PowerMeter {
    let powerSensorDelegate : PowerSensorDelegate
    var powerValueToSend = 145
    var range = 20
    var timer : Timer?
    var deviceInstance: PowerSensorDevice?
    let realm = try! Realm()

    init(delegate : PowerSensorDelegate) {
        powerSensorDelegate = delegate
    }
    func name() -> (String) {
        return "Fake Power Meter"
    }
    func start() {
        createFakeDevice()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            let random = Int(arc4random_uniform(UInt32(self.range))) + self.powerValueToSend
            self.powerSensorDelegate.receivedPowerReading(sensor: self, powerReading: random.toIntMax())
            try! self.realm.write {
                self.deviceInstance?.currentData?.instantPower = NSNumber(integerLiteral: random)
            }
        }
        timer = newTimer
    }
    
    func createFakeDevice() {
        let queryResults = realm.objects(PowerSensorDevice.self).filter("deviceID = 'FakeDeviceID'")
        if let persistedDevice = queryResults.first {
            deviceInstance = persistedDevice
        } else {
            deviceInstance = PowerSensorDevice()
            deviceInstance?.currentData = PowerSensorData()
            deviceInstance?.deviceID = "FakeDeviceID"
            try! realm.write {
                realm.add(deviceInstance!)
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    deinit {
        PowerSensorDevice.deleteDevice(identifierString: "FakeDeviceID")
    }
}
