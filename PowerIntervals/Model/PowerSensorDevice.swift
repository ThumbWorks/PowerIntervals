//
//  PowerSensorDevice.swift
//  PowerIntervals
//
//  Created by Roderic on 9/23/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import RealmSwift

enum PowerMeterType {
    case unknown
    case powerOnly
    case crankTorque
    case wheelTorque
    case crankTorqueFrequency
    case blueTooth
}
enum NetworkType {
    case ant
    case btle
    case suunto
    case unspecified
    case wildcard
}

enum SensorSubType {
    case unspecified
    case kickr
    case kickrSnap
    case stageOne
    case kurtInRide
    case rflkt
    case echo
    case casioType1
    case timexRunX50
    case echoFit
    case tickr
    case tickrX
    case tickrRun
}

class PowerSensorDevice: Object {
    override static func primaryKey() -> String? {
        return "deviceID"
    }
    dynamic var deviceID: String = ""
    dynamic var deviceNumber: NSNumber = 0
    dynamic var deviceBTLEUUID: String?
    dynamic var didTimeout = false
    // var error: WFSensorConnectionError_t
    dynamic var hasError = false
    dynamic var antBridgeSupport = false
    dynamic var validParameters = false
    dynamic var wildcardParams = false
    dynamic var antConnection = false
    dynamic var connected = false
    dynamic var valid = false
    var networkType: NetworkType = .unspecified
    var sensorSubType: SensorSubType = .unspecified
    dynamic var timeSinceLastMessage: TimeInterval = 0
    dynamic var currentData: PowerSensorData?
//    var transmissionType: Character = Character("")
    
}

class PowerSensorData: Object {
    dynamic var formattedCadence = ""
    dynamic var formattedDistance = ""
    dynamic var formattedPower = ""
    dynamic var formattedSpeed = ""
    dynamic var isCoasting = true
    dynamic var accumulatedEventCount: Int = 0
    dynamic var accumulatedPower: Double = 0
    dynamic var accumulatedTime: TimeInterval = 0
    dynamic var accumulatedTimestamp: TimeInterval = 0
    dynamic var accumulatedTimestampOverflow = false
    dynamic var accumulatedTorque: Double = 0
    dynamic var cadenceSupported = false
    dynamic var crankRevolutions: Double = 0
    dynamic var crankRevolutionSupported: Bool = false
    dynamic var crankTime: TimeInterval = 0
    dynamic var crankTimestamp: TimeInterval = 0
    dynamic var crankTimestampOverflow = false
    dynamic var instantPower: NSNumber = 0
    dynamic var instantSpeed: NSNumber = 0
    dynamic var instantWheelRPM: NSNumber = 0
    dynamic var isDataStale: Bool = true
    var sensorType: PowerMeterType = .unknown
    dynamic var wheelRevolutions: Double = 0
    dynamic var wheelRevolutionSupported = false
    dynamic var wheelTime: TimeInterval = 0
    dynamic var wheelTimestamp: TimeInterval = 0
    dynamic var wheelTimestampOverflow = false
}
