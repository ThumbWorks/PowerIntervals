//
//  PowerSensorDelegate.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

protocol PowerMeter {
    func name() -> (String)
}

protocol PowerSensorDelegate {
// Realm somewhat eliminates the need for this delegate callback
    func receivedPowerReading(sensor: PowerMeter, powerReading: IntMax)
    func hardwareConnectedState(sensor: PowerMeter, connected: Bool)
    func hardwareDebug(sensor: PowerMeter, message: String)
}

