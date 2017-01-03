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
    var sensorConnection : WFSensorConnection?

    func start(hardwareConnection: WFHardwareConnector) {

        if sensorConnection != nil {
            return
        }
        
        let params = WFConnectionParams()
        params.sensorType = WF_SENSORTYPE_BIKE_POWER
        
        if let connection = hardwareConnection.requestSensorConnection(params) {
            sensorConnection = connection
        }
        else {
        }
    }
    
    func connection(_ connectionInfo: WFSensorConnection!, rejectedByDeviceNamed deviceName: String!, appAlreadyConnected appName: String!) {
    }
    
    func connectionDidTimeout(_ connectionInfo: WFSensorConnection!) {
    }
    
    internal func connection(_ connectionInfo: WFSensorConnection!, stateChanged connState: WFSensorConnectionStatus_t) {
    }
}

class WahooHardware : NSObject, WFHardwareConnectorDelegate {
    var sensorConnectionDelegate: SensorDelegate?
    var connectedWahooDevices = Set<WFBikePowerConnection>()
    
    func name() -> (String) {
        return "Wahoo Hardware"
    }
    
    func startHardware() {
        let connector = WFHardwareConnector.shared()
        connector?.delegate = self
        let connectionParams = WFConnectionParams()
        connectionParams.sensorType = WF_SENSORTYPE_BIKE_POWER
        if let unwrappedSensorConnection = connector?.requestSensorConnection(connectionParams) as! WFBikePowerConnection? {
            unwrappedSensorConnection.delegate = sensorConnectionDelegate
        }
        sensorConnectionDelegate = SensorDelegate()
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, hasFirmwareUpdateAvailableFor connectionInfo: WFSensorConnection!, required: Bool, withWahooUtilityAppURL wahooUtilityAppURL: URL!) {
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, antBridgeStateChanged eState: WFAntBridgeState_t, onDevice deviceUUIDString: String!) {
        var msg = "Hardwareconnector " + hwConnector.description
        msg = msg + " ant bridge state changed to:" + eState.rawValue.description
        msg = msg + " on device " + deviceUUIDString
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, disconnectedSensor connectionInfo: WFSensorConnection!) {

        if let disconnectingSensor = connectionInfo as? WFBikePowerConnection{
            connectedWahooDevices.remove(disconnectingSensor)
        }
        // we need to delete this
        PowerSensorDevice.deleteDevice(identifierString: connectionInfo.deviceIDString)
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, stateChanged currentState: WFHardwareConnectorState_t) {
        // CONNECTED and ACTIVE
        if currentState.rawValue == 3 {
            // tell the sensorDelegate to start searching
            sensorConnectionDelegate?.start(hardwareConnection: hwConnector)
        }
    }

    // This comes back on a background thread
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, connectedSensor sensor: WFSensorConnection) {
        sensor.delegate = sensorConnectionDelegate
        
        if let unwrappedSensor = sensor as? WFBikePowerConnection {
            connectedWahooDevices.insert(unwrappedSensor)
            PowerSensorDevice.deviceWithBikePowerConnection(pm: unwrappedSensor)
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
        //TODO was causing a crash. Let's see what we can do without this https://fabric.io/thumbworks/ios/apps/io.thumbworks.powerintervals/issues/57f1a8890aeb16625b10020c
//        switch(pm.networkType) {
//        case WF_NETWORKTYPE_UNSPECIFIED:
//            networkType = .unspecified
//        case WF_NETWORKTYPE_ANTPLUS:
//            networkType = .ant
//        case WF_NETWORKTYPE_BTLE:
//            networkType = .btle
//        case WF_NETWORKTYPE_SUUNTO:
//            networkType = .suunto
//        case WF_NETWORKTYPE_ANY:
//            networkType = .wildcard
//        default:
//            networkType = .unspecified
//        }
        timeSinceLastMessage = pm.timeSinceLastMessage
        valid = pm.isValid;
        validParameters = pm.hasValidParams
        wildcardParams = pm.hasWildcardParams
    }
    
    class func deviceWithBikePowerConnection(pm: WFBikePowerConnection) {
        
        // query first
        let realm = try! Realm()

        let predicate = NSPredicate(format: "deviceID == %@", pm.deviceIDString)

        var powerSensorDevice = realm.objects(PowerSensorDevice.self).filter(predicate).first
        
        // create a new one if we don't have it
        if powerSensorDevice == nil {
            powerSensorDevice = PowerSensorDevice()
            // set the deviceIDString only when we create it
            powerSensorDevice?.deviceID = pm.deviceIDString
        }
        
        if let powerSensorDevice = powerSensorDevice {
            try! realm.write {
                powerSensorDevice.update(pm: pm)
                powerSensorDevice.currentData = PowerSensorData()
                powerSensorDevice.currentData?.update(powerData: pm.getBikePowerData())
                realm.add(powerSensorDevice)
            }
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
