//
//  WahooHardware.swift
//  PowerIntervals
//
//  Created by Roderic on 9/13/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit //for now

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
    var sensorConnection: WFBikePowerConnection?
    var sensorConnectionDelegate: SensorDelegate?
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
        sensorConnection = connector?.requestSensorConnection(connectionParams) as! WFBikePowerConnection?
    
        powerDelegate.hardwareDebug(sensor: self, message: "setup sensorConnectionDelegate object")
        sensorConnectionDelegate = SensorDelegate(debugger: powerDelegate, powerMeter: self)
        
        powerDelegate.hardwareDebug(sensor: self, message: "set the sensorConnectionDelegate to the delegate of sensorConnection")
        sensorConnection?.delegate = sensorConnectionDelegate
        
        switch Int((connector?.currentState().rawValue)!) {
        case 0: // not connected
            powerDelegate.hardwareDebug(sensor: self, message: "not connected")
        default:
            powerDelegate.hardwareDebug(sensor: self, message: "case not handled for current state of connector")
        }
    }

    // This comes back on a background thread
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, connectedSensor sensor: WFSensorConnection) {
        sensor.delegate = sensorConnectionDelegate
        sensorConnection = sensor as? WFBikePowerConnection
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
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, didCompleteCheckingAvailibleFirmwareFor connectionInfo: WFSensorConnection!, error: Error!) {
        powerDelegate.hardwareDebug(sensor: self, message: "didCompleteCheckingAvailibleFirmwareFor")
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, hasFirmwareUpdateAvailableFor connectionInfo: WFSensorConnection!, required: Bool, withWahooUtilityAppURL wahooUtilityAppURL: URL!) {
        powerDelegate.hardwareDebug(sensor: self, message: "hasFirmwareUpdateAvailableFor")
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, disconnectedSensor connectionInfo: WFSensorConnection!) {
        powerDelegate.hardwareDebug(sensor: self, message: "disconnectedSensor")
    }
    
    func hardwareConnector(_ hwConnector: WFHardwareConnector!, antBridgeStateChanged eState: WFAntBridgeState_t, onDevice deviceUUIDString: String!) {
        var msg = "Hardwareconnector " + hwConnector.description
        msg = msg + " ant bridge state changed to:" + eState.rawValue.description
        msg = msg + " on device " + deviceUUIDString
        powerDelegate.hardwareDebug(sensor: self, message: "ant bridge state changed")
    }
    
    override func attemptRecovery(fromError error: Error, optionIndex recoveryOptionIndex: Int, delegate: Any?, didRecoverSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        print("attempt recovery:", error, "option index:", recoveryOptionIndex)
        powerDelegate.hardwareDebug(sensor: self, message: "Got an error of some type. Need to attempt to recover")
    }
    
    func hardwareConnectorHasData() {
        //alertText(message: "Hardware connector has data")
        if let data = sensorConnection?.getBikePowerData() {
            let accumulatedPower = data.accumulatedPower
            let instantPower = data.instantPower
            let powerString = "Accumulated: " + accumulatedPower.description + "instant: " + instantPower.description
            powerDelegate.hardwareDebug(sensor: self, message: "Hardware Connector has data " + powerString)
            powerDelegate.receivedPowerReading(sensor: self, powerReading: instantPower.toIntMax())
        }
    }
    
}

