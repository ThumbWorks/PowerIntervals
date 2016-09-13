//
//  FakePowerMeter.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

class FakePowerMeter {
    let powerSensorDelegate : PowerSensorDelegate
    var powerValueToSend = 145
    var range = 20
    var timer : Timer?
    init(delegate : PowerSensorDelegate) {
        powerSensorDelegate = delegate
    }
    
    func start() {
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            print("Hey the timer fired")
            
            let random = Int(arc4random_uniform(UInt32(self.range))) + self.powerValueToSend
            
            self.powerSensorDelegate.receivedPowerReading(powerReading: random)
        }
        //newTimer.fire()
        timer = newTimer
    }
    
}
