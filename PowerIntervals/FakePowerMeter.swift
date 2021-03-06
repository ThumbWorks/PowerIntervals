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
    var name: String?
    var powerValueToSend = 10
    var timer : Timer?
    var time = 0.0
    var deviceInstance: PowerSensorDevice?
    let realm = try! Realm()
    
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
            let power = max(self.powerValueToSend, 0)
            let random = Int(arc4random_uniform(UInt32(power / 2))) + power
            try! self.realm.write {
                // this is all of the data we currently show in the device list
                guard let data = self.deviceInstance?.currentData else {
                    return
                }
                
                data.instantPower = NSNumber(integerLiteral: random)
                data.formattedPower = data.instantPower.description + " w"
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
        var powerMeterName = "PM \(arc4random() % 2000)"
        if let name = name {
            powerMeterName = name
        }
        let predicate = NSPredicate(format: "deviceID = %@", powerMeterName)
        let queryResults = realm.objects(PowerSensorDevice.self).filter(predicate)
        if let persistedDevice = queryResults.first {
            deviceInstance = persistedDevice
        } else {
            let newDeviceInstance = PowerSensorDevice()
            newDeviceInstance.currentData = PowerSensorData()
            newDeviceInstance.currentData?.instantPower = NSNumber(integerLiteral: powerValueToSend)
            newDeviceInstance.deviceID = powerMeterName
            newDeviceInstance.connected = true
            try! realm.write {
                realm.add(newDeviceInstance)
            }
            deviceInstance = newDeviceInstance
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
}
