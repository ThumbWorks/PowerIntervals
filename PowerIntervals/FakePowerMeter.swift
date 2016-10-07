//
//  FakePowerMeter.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import RealmSwift

class FakePowerMeter {
    var powerValueToSend = 145
    var timer : Timer?
    var time = 0.0
    var deviceInstance: PowerSensorDevice?
    let realm = try! Realm()
    
    func name() -> (String) {
        return "Fake Power Meter"
    }
    
    func startButton() {
        if let poweMeterTimer = timer {
            if poweMeterTimer.isValid {
                stop()
            } else {
                start()
            }
        }
        else {
            start()
        }
    }
    
    func start() {
        createFakeDevice()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.time += 1
            let random = Int(arc4random_uniform(UInt32(self.powerValueToSend / 10))) + self.powerValueToSend
            try! self.realm.write {
                // this is all of the data we currently show in the device list
                guard let data = self.deviceInstance?.currentData else {
                    return
                }
                data.instantPower = NSNumber(integerLiteral: random)
                data.formattedPower = data.instantPower.description + " watts"
                data.accumulatedTime = self.time
                data.accumulatedPower = Double(random)
                data.formattedDistance = "100 miles"
                data.accumulatedTorque = Double(random)
                data.formattedSpeed = (random / 10).description + " mph"
                data.wheelRevolutions = self.time
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
