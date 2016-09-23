//
//  PowerSensorDevice.swift
//  PowerIntervals
//
//  Created by Roderic on 9/23/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

enum PowerMeterType {
    case Unknown
    case PowerOnly
    case CrankTorque
    case WheelTorque
    case CrankTorqueFrequency
    case BlueTooth
}

class PowerSensorDevice: NSObject {
    var formattedCadence = ""
    var formattedDistance = ""
    var formattedPower = ""
    var formattedSpeed = ""
    var isCoasting = true
    var accumulatedEventCount: Int = 0
    var accumulatedPower: Double = 0
    var accumulatedTime: TimeInterval = 0
    var accumulatedTimestamp: TimeInterval = 0
    var accumulatedTimestampOverflow = false
    var accumulatedTorque: Double = 0
    var cadenceSupported = false
    var crankRevolutions: Double = 0
    var crankRevolutionSupported: Double = 0.0
    var crankTime: TimeInterval = 0
    var crankTimestamp: TimeInterval = 0
    var crankTimestampOverflow = false
    var instantPower: CShort = 0
    var instantSpeed: NSNumber = 0
    var instantWheelRPM: CShort = 0
    var isDataStale: Bool = true
    var sensorType: PowerMeterType = .Unknown
    var wheelRevolutions: Double = 0
    var wheelRevolutionSupported = false
    var wheelTime: TimeInterval = 0
    var wheelTimestamp: TimeInterval = 0
    var wheelTimestampOverflow = false
    //TODO add the left/right torque
}
