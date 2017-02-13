//
//  DeviceListDataSource.swift
//  PowerIntervals
//
//  Created by Roderic on 9/23/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class DeviceListDataSource: NSObject {
    var devices: Results<PowerSensorDevice>
    var selectedDevice: PowerSensorDevice?
    let devicesRealm: Realm
    init(realm: Realm) {
        devicesRealm = realm
        //TODO may need to only check connected devices
        devices = devicesRealm.objects(PowerSensorDevice.self).sorted(byKeyPath: "connected", ascending: false)
    }
}

extension DeviceListDataSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FormattedCollectionViewSensorCellID", for: indexPath) as! FormattedCollectionViewSensorCell
        let device = devices[indexPath.row]
        
        // make the selected device's cell a bit different than the rest
        let isSelected = device == selectedDevice
        cell.background.backgroundColor = isSelected ? UIColor.powerBlue.withAlphaComponent(0.6) : UIColor.powerBlue
        
        if let name = device.userDefinedName {
            cell.sensorID.text = name
        } else {
            cell.sensorID.text = device.deviceID
        }
        if let data = device.currentData {
            cell.power.text = data.formattedPower
        }
        
        if device.connected {
            cell.sensorID.textColor = .white
            cell.power.textColor = .white
        } else {
            cell.sensorID.textColor = UIColor.white.withAlphaComponent(0.5)
            cell.power.textColor = UIColor.white.withAlphaComponent(0.5)
        }
        
        return cell
    }
}
