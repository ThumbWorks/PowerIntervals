//
//  BluetoothDelegate.swift
//  PowerIntervals
//
//  Created by Roderic on 10/7/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import CoreBluetooth
import RealmSwift
import Mixpanel

class BluetoothDelegate: NSObject {
    let queue = DispatchQueue(label: "bluetoothDelegateQueue")
    var manager: CBCentralManager?
    var peripherals: NSMutableArray?
    let peripheralDelegate = PeripheralDelegate()
    
    func start() {
        //TODO maybe we can do this lazily
        manager = CBCentralManager(delegate: self, queue: queue)
        peripherals = NSMutableArray()
        
        let realm = try! Realm()
        let devices = realm.objects(PowerSensorDevice.self)
        try! realm.write {
            for device in devices {
                device.connected = false
            }
        }
    }
    
    func stop() {
        manager?.stopScan()
        peripherals = nil
    }
}

extension BluetoothDelegate: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        let properties: Properties = ["state": central.state.rawValue]
        Logger.track(event: "centralManagerDidUpdateState", properties:properties)

        switch central.state {
            
        case .poweredOff:
            print("powerOff")
            
        case .poweredOn:
            print("PoweredOn: start scanning")
            central.scanForPeripherals(withServices: [CBUUID.powerMeter()], options: nil)
            
        case .resetting:
            print("resetting")
            
        case .unauthorized:
            print("unauth")
            
        case .unknown:
            print("unknown")
            
        case .unsupported:
            print("unsupported")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let name = peripheral.name {
            print("Did discover peripheral \(name)")
            let properties: Properties = ["RSSI": RSSI.floatValue, "name": name, "state": peripheral.state.rawValue]
            Logger.track(event: "centralManagerDidDiscoverPeripheral", properties:properties)
        } else {
            let properties: Properties = ["RSSI": RSSI.floatValue]
            Logger.track(event: "centralManagerDidDiscoverPeripheral", properties:properties)
        }
        
        guard let peripherals = peripherals, let manager = manager else {
            print("We can't connect to a peripheral until we have a manager and set of peripherals")
            return
        }
        
        print("start connection:")
        peripherals.add(peripheral)
        manager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("did connect to peripheral")
        if let name = peripheral.name {
            print("Did connect to peripheral \(name)")
        }
        
        let services = CBUUID.powerMeter()
        peripheral.delegate = peripheralDelegate
        
        //TODO: Fetch or create a PowerSensorDevice
        // query first
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "deviceID == %@", peripheral.identifier.uuidString)
        var device = realm.objects(PowerSensorDevice.self).filter(predicate).first
        // create a new one if we don't have it
        if device == nil {
            device = PowerSensorDevice()
            // set the deviceIDString only when we create it
            device?.deviceID = peripheral.identifier.uuidString
            if let name = peripheral.name {
                device?.userDefinedName = name
            }
        }
        
        try! realm.write {
            device?.deviceBTLEUUID = peripheral.identifier.uuidString
            device?.connected = true
            if let device = device {
                device.currentData = PowerSensorData()
                realm.add(device)
            }
        }
        
        peripheral.discoverServices([services])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Swift.Error?) {
        print("Did fail to connect to peripheral \(peripheral.name)")
        if let error = error {
            let properties: Properties = ["error": error.localizedDescription]
            Logger.track(event: "centralManagerDidFailWithError", properties:properties)
        }
        else {
            Logger.track(event: "centralManagerDidFailWithError")
        }
        

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        if let error = error {
            print("Disconnect peripheral with error: \(error.localizedDescription)")
            let properties: Properties = ["error": error.localizedDescription]
            Logger.track(event: "centralManagerDidDisconnectWithError", properties:properties)
        }
        if let index = peripherals?.index(of: peripheral) {
            Logger.track(event: "centralManagerDidDisconnectWithoutError")
            _ = peripherals?.remove(at: index)
            
            // disconnect the device in realm
            let predicate = NSPredicate(format: "deviceID == %@", peripheral.identifier.uuidString)
            let realm = try! Realm()
            if let device = realm.objects(PowerSensorDevice.self).filter(predicate).first {
                try! realm.write {
                    device.connected = false
                }
            }
        }
    }
}

class PeripheralDelegate: NSObject {
}

extension PeripheralDelegate: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Swift.Error?) {
        if let name = peripheral.name {
            print("did discover services on \(name)")
        } else {
            print("did discover services on unknown")
        }
        if let error = error {
            print("We got an error \(error.localizedDescription)")
            return
        }
        for service in peripheral.services! {
            // so this should be 1818 which is CBUUID.powerMeter()
            print("Service discovered \(service.uuid)")
//            peripheral.discoverCharacteristics(nil, for: service)
            peripheral.discoverCharacteristics([CBUUID.powerMeterData()], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
        if let name = peripheral.name {
            print("did discover characteristic on \(name)")
        }
        if let error = error {
            print("We got an error \(error.localizedDescription)")
            return
        }
        for characteristic in service.characteristics! as [CBCharacteristic] {
            print("characteristic \(characteristic.uuid). Let's get notified of changes")
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error = error {
            print("error when getting an update \(error.localizedDescription)")
        }
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "deviceID == %@", peripheral.identifier.uuidString)
        
        if let device = realm.objects(PowerSensorDevice.self).filter(predicate).first {
            try! realm.write {
                device.currentData?.instantPower = NSNumber(value: characteristic.toPowerData())
                device.currentData?.formattedPower = String(format: "%d w", characteristic.toPowerData())
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error = error {
            print("We got an error \(error.localizedDescription)")
            return
        }
        let value = characteristic.value?.getInt()
        
        print("The value was updated through a notification for the \(peripheral.name). The value is \(value)")
    }
}

extension CBUUID {
    
    // The power meter bluetooth type
    // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.service.cycling_power.xml
    static func powerMeter() -> CBUUID {
        return CBUUID(string: "1818")
    }
    
    // Is torque supported, is pedal balance supported etc
    static func powerMeterFeatures() -> CBUUID {
        return CBUUID(string: "0x2A65")
    }
    
    static func powerVector() -> CBUUID {
        return CBUUID(string: "0x2A64")
    }
    
    // top of shoe, front wheel, read wheel, left crank, rear hub etc
    // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.sensor_location.xml
    static func sensorLocation() -> CBUUID {
        return CBUUID(string: "0x2A5D")
    }
    
    // this is really the only thing we want at this point
    // instantaneous power: org.bluetooth.unit.power.watt
    static func powerMeterData() -> CBUUID {
        return CBUUID(string: "0x2A63")
    }
    
    static func wattService() -> CBUUID {
        return CBUUID(string: "0x2726")
    }
    
    // The services we care about
    static func powerMeterServices() -> [CBUUID]? {
        var ret = [CBUUID]()
        ret.append(powerMeterData())
        ret.append(powerVector())
        ret.append(powerMeterFeatures())
        ret.append(wattService())
        return ret
    }
}

extension CBCharacteristic {
    func toPowerData() -> UInt16 {
        var watts: UInt16 = 0
        if let data = value {
            var bytes = Array(repeating: 0 as UInt8, count:data.count/MemoryLayout<UInt8>.size)
            
            data.copyBytes(to: &bytes, count:data.count)
            let data16 = bytes.map { UInt16($0) }
            // Per https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.cycling_power_measurement.xml
            
            //  Print the debug bytes. Could change based on power meter capabilities
//            var string = ""
//            for i in data {
//                string = string + " \(i) - "
//            }
//            print(string)
            
            // Settings debug
//            let settings = data[0] // mandatory
            
//            let pedalPowerPresent = (settings & 0)
//            let balanceReferenceIsLeft = (settings & 1)
//            let accumulatedTorque = (settings & 2)
//            let accumulatedTorqueSourceCrank = (settings & 4) // wheel otherwise probably
//            let wheelRevolutionDataPresent = (settings & 8)
//            let crankRevolutionDataPresent = (settings & 16)
//            let extremeForceMagintudePresent = (settings & 32)
//            let extremeTorqueMagnitudePresent = (settings & 64)
//            let extremeAnglesPresent = (settings & 128)
            
            // bits 9 - 12
//            let topDeadSpotAnglePresent = (settings & 256)
//            let bottomDeadSpotAnglePresent = (settings & 512)
//            let accumulatedEnergyPresent = (settings & 1024)
//            let offsetCompensationIndicator = (settings & 2048)
            
//            print("\(pedalPowerPresent>0 ? "pedal power" : "not pedal power")\n\(balanceReferenceIsLeft>0 ? "Balance is left" : "Balance is not left")\n\(accumulatedTorque>0 ? "Has accumulated torque" : "Does not have accumulated Torque")")
//            print("\(accumulatedTorqueSourceCrank>0 ? "acc torque on crank" : "acc torque not on crank")\n\(wheelRevolutionDataPresent>0 ? "Wheel data present" : "Wheel data not present")\n\(crankRevolutionDataPresent>0 ? "Crank data present" : "Crank data not present")")
//            print("\(extremeForceMagintudePresent>0 ? "Extreme force magnitude present" : "Extreme force magnitude not present")\n\(extremeTorqueMagnitudePresent>0 ? "Extreme torque magnitude present" : "Extreme torque magnitude not present")\n\(extremeAnglesPresent>0 ? "Extreme angles present" : "Extreme angles not present")")
            
            
//            let wattage = data[1] + data[2] // mandatory
//            let pedalPowerBalance = data[3] // optional
//            let accumulatedTorque1 = data[4] + data[5] // optional (tacx has it)
//            let wheelRevolutionData = data[6] + data[7] + data[8] + data[9] // c1
//            let lastWheelEventTime = data[10] + data[11] // c1
//            let cumulativeCrankRevolutions = data[12] + data[13] // c2
//            let lastCrankEventTime = data[14] + data[15] // c2
//            let maxForce = data[16] + data[17]
//            let minForce = data[18] + data[19]
            
            // We are looking for the bits that represent the instantaneous power
            // Testing showed that this is element 2 of 13
            if data16.count == 1 {
                watts = data16[0]
            } else {
                watts = (data16[3]) << 8 + data16[2]
            }
        }
        return watts
    }
}
extension Data {

    func getInt() -> Int16 {
        let intBits = withUnsafeBytes({(bytePointer: UnsafePointer<UInt8>) -> Int16 in
            bytePointer.advanced(by: 0).withMemoryRebound(to: Int16.self, capacity: 4) { pointer in
                return pointer.pointee
            }
        })
        return Int16(bigEndian: intBits)
    }
}
