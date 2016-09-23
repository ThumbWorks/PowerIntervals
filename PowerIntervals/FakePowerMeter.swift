//
//  FakePowerMeter.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

class FakePowerMeter: PowerMeter {
    let powerSensorDelegate : PowerSensorDelegate
    var powerValueToSend = 145
    var range = 20
    var timer : Timer?
    init(delegate : PowerSensorDelegate) {
        powerSensorDelegate = delegate
    }
    func name() -> (String) {
        return "Fake Power Meter"
    }
    func start() {
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            let random = Int(arc4random_uniform(UInt32(self.range))) + self.powerValueToSend
            self.powerSensorDelegate.receivedPowerReading(sensor: self, powerReading: random.toIntMax())
        }
        timer = newTimer
    }
    
    func stop() {
        timer?.invalidate()
    }
}
