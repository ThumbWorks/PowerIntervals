//
//  WahooHardware.swift
//  PowerIntervals
//
//  Created by Roderic on 9/13/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit //for now
import RealmSwift

class SensorDelegate : NSObject, WFSensorConnectionDelegate {
    let debugObject : PowerSensorDelegate
    var powerMeterForDebugging: PowerMeter
    var sensorConnection : WFSensorConnection?
    
    init(debugger: PowerSensorDelegate, powerMeter: PowerMeter) {
        debugObject = debugger
        powerMeterForDebugging = powerMeter
        debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "Set up sensor delegate")
        super.init()
    }

    func start(hardwareConnection: WFHardwareConnector) {
        debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "We are starting the SensorDelegate")

        if sensorConnection != nil {
            debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "we have a sensor connection. No need to get another one maybe?")
            return
        }
        
        let params = WFConnectionParams()
        params.sensorType = WF_SENSORTYPE_BIKE_POWER
        debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "after setting the type")
        
        if let connection = hardwareConnection.requestSensorConnection(params) {
            sensorConnection = connection
            debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "after requestSensorConnection. It unwrapped")
        }
        else {
            debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "after requestSensorConnection. It did not unwrap")
        }
    }
    
    func connection(_ connectionInfo: WFSensorConnection!, rejectedByDeviceNamed deviceName: String!, appAlreadyConnected appName: String!) {
        debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "rejectedByDeviceNamed")

    }
    
    func connectionDidTimeout(_ connectionInfo: WFSensorConnection!) {
        debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "connectionDidTimeout")
    }
    
    internal func connection(_ connectionInfo: WFSensorConnection!, stateChanged connState: WFSensorConnectionStatus_t) {
        debugObject.hardwareDebug(sensor: powerMeterForDebugging, message: "sensorDelegate stateChanged")

    }
}

class WahooHardware : NSObject, WFHardwareConnectorDelegate, PowerMeter {
    var powerDelegate: PowerSensorDelegate
    var sensorConnectionDelegate: SensorDelegate?
    var connectedWahooDevices = Set<WFBikePowerConnection>()
    
    init(powerSensorDelegate: PowerSensorDelegate) {
        powerDelegate = powerSensorDelegate
        super.init()
    }
    
    func name() -> (String) {
        return "Wahoo Hardware"
    }
    
    func startHardware() {
        let connector = WFHardwareConnector.shared()
        connector?.delegate = self
        
        powerDelegate.hardwareDebug(sensor: self, message: "start hardware")
        let connectionParams = WFConnectionParams()
        connectionParams.sensorType = WF_SENSORTYPE_BIKE_POWER
        if let unwrappedSensorConnection = connector?.requestSensorConnection(connectionParams) as! WFBikePowerConnection? {
            unwrappedSensorConnection.delegate = sensorConnectionDelegate
        }
    
        powerDelegate.hardwareDebug(sensor: self, message: "setup sensorConnectionDelegate object")
        sensorConnectionDelegate = SensorDelegate(debugger: powerDelegate, powerMeter: self)
        
        powerDelegate.hardwareDebug(sensor: self, message: "set the sensorConnectionDelegate to the delegate of sensorConnection")
        
        switch Int((connector?.currentState().rawValue)!) {
        case 0: // not connected
            powerDelegate.hardwareDebug(sensor: self, message: "not connected")
        default:
            powerDelegate.hardwareDebug(sensor: self, message: "case not handled for current state of connector")
        }
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, hasFirmwareUpdateAvailableFor connectionInfo: WFSensorConnection!, required: Bool, withWahooUtilityAppURL wahooUtilityAppURL: URL!) {
        powerDelegate.hardwareDebug(sensor: self, message: "hasFirmwareUpdateAvailableFor")
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, antBridgeStateChanged eState: WFAntBridgeState_t, onDevice deviceUUIDString: String!) {
        var msg = "Hardwareconnector " + hwConnector.description
        msg = msg + " ant bridge state changed to:" + eState.rawValue.description
        msg = msg + " on device " + deviceUUIDString
        powerDelegate.hardwareDebug(sensor: self, message: "ant bridge state changed")
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, disconnectedSensor connectionInfo: WFSensorConnection!) {
        powerDelegate.hardwareDebug(sensor: self, message: "disconnectedSensor")
        // we need to delete this
        PowerSensorDevice.deleteDevice(identifierString: connectionInfo.deviceIDString)
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, stateChanged currentState: WFHardwareConnectorState_t) {
        if (hwConnector) != nil {
            let string = "The state for the hardware connector changed to \(currentState.rawValue)"
            powerDelegate.hardwareDebug(sensor: self, message: string)
        }
        // CONNECTED and ACTIVE
        if currentState.rawValue == 3 {
            // tell the sensorDelegate to start searching
            powerDelegate.hardwareDebug(sensor: self, message: "We got a 3, start up the sensorConnectionDelegate")
            sensorConnectionDelegate?.start(hardwareConnection: hwConnector)
        }
    }

    // This comes back on a background thread
    // TODO need to store each one of these that comes back in some sort of array
    //    That way I'll be able to check all of them when some data comes back and I 
    //    can update the persistently stored object
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, connectedSensor sensor: WFSensorConnection) {
        sensor.delegate = sensorConnectionDelegate
        
        if let unwrappedSensor = sensor as? WFBikePowerConnection {
            connectedWahooDevices.insert(unwrappedSensor)
            PowerSensorDevice.deviceWithBikePowerConection(pm: unwrappedSensor)
        }
    }

     func hardwareConnectorHasData() {
        
        let devicesWithData = connectedWahooDevices.filter { (connection) -> Bool in
            return connection.hasData()
        }

        let realm = try! Realm()

        // Get those realm objects
        for device in devicesWithData {
            // get the realm object
            let predicate = NSPredicate(format: "deviceID == %@", device.deviceIDString)
            let object = realm.objects(PowerSensorDevice.self).filter(predicate)
            if let realmDevice = object.first {
                try! realm.write {
                    // update the latest state of the device
                    realmDevice.update(pm: device)
                    
                    if let data = realmDevice.currentData {
                        // put the new data in it
                        data.update(powerData: device.getBikePowerData())
                        
                        let accumulatedPower = data.accumulatedPower
                        let instantPower = data.instantPower
                        let powerString = "Accumulated: " + accumulatedPower.description + "instant: " + instantPower.description
                        powerDelegate.hardwareDebug(sensor: realmDevice, message: "Hardware Connector has data " + powerString)
                        powerDelegate.receivedPowerReading(sensor: realmDevice, powerReading: IntMax(instantPower.intValue))
                    }
                }
            }
        }
    }
}

extension PowerSensorData {
    func update(powerData: WFBikePowerData) {
        formattedCadence = powerData.formattedCadence(true)
        formattedDistance = powerData.formattedDistance(true)
        formattedPower = powerData.formattedPower(true)
        formattedSpeed = powerData.formattedSpeed(true)
        isCoasting = powerData.isCoasting()
        accumulatedEventCount = Int(powerData.accumulatedEventCount)
        accumulatedPower = powerData.accumulatedPower
        accumulatedTime = powerData.accumulatedTime
        accumulatedTimestamp = powerData.accumulatedTimestamp
        accumulatedTimestampOverflow = powerData.accumulatedTimestampOverflow
        accumulatedTorque = powerData.accumulatedTorque
        cadenceSupported = powerData.cadenceSupported
        crankRevolutions = powerData.crankRevolutions
        crankRevolutionSupported = powerData.isCrankRevolutionSupported
        crankTime = powerData.crankTime
        crankTimestamp = powerData.crankTimestamp
        crankTimestampOverflow = powerData.crankTimestampOverflow
        instantPower = NSNumber(value: powerData.instantPower)
        if let speed = powerData.instantSpeed {
            instantSpeed = speed
        }
        instantWheelRPM = NSNumber(value: powerData.instantWheelRPM)
        isDataStale = powerData.isDataStale
        //        var sensorType: PowerMeterType = .unknown
        wheelRevolutions = powerData.wheelRevolutions
        wheelRevolutionSupported = powerData.isWheelRevolutionSupported
        wheelTime = powerData.wheelTime
        wheelTimestamp = powerData.wheelTimestamp
        wheelTimestampOverflow = powerData.wheelTimestampOverflow
    }
}

extension PowerSensorDevice {
    // this could be renamed
    func update(pm: WFBikePowerConnection) {
        antBridgeSupport = pm.hasAntBridgeSupport
        antConnection = pm.isANTConnection
        connected = pm.isConnected
        deviceBTLEUUID = pm.deviceUUIDString
        deviceNumber = NSNumber(integerLiteral: Int(pm.deviceNumber))
        didTimeout = pm.didTimeout
        hasError = pm.hasError
        switch(pm.networkType) {
        case WF_NETWORKTYPE_UNSPECIFIED:
            networkType = .unspecified
        case WF_NETWORKTYPE_ANTPLUS:
            networkType = .ant
        case WF_NETWORKTYPE_BTLE:
            networkType = .btle
        case WF_NETWORKTYPE_SUUNTO:
            networkType = .suunto
        case WF_NETWORKTYPE_ANY:
            networkType = .wildcard
        default:
            networkType = .unspecified
        }
        timeSinceLastMessage = pm.timeSinceLastMessage
        valid = pm.isValid;
        validParameters = pm.hasValidParams
        wildcardParams = pm.hasWildcardParams
    }
    
    class func deviceWithBikePowerConection(pm: WFBikePowerConnection) {
        let powerSensorDevice = PowerSensorDevice()
        powerSensorDevice.deviceID = pm.deviceIDString
        powerSensorDevice.update(pm: pm)
        powerSensorDevice.currentData = PowerSensorData()
        powerSensorDevice.currentData?.update(powerData: pm.getBikePowerData())
        let realm = try! Realm()
        try! realm.write {
            realm.add(powerSensorDevice)
        }
    }
    
    class func deleteDevice(identifierString: String) {
        // do a query here
        let realm = try! Realm()
        guard  let matchingDevice = realm.objects(PowerSensorDevice.self).filter("deviceID = '\(identifierString)'").first else {
            // we didn't get a match on this string, bail
            return
        }
        // Delete an object with a transaction
        try! realm.write {
            realm.delete(matchingDevice)
        }
    }
}
