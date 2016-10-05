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
    
    override init() {
        let realm = try! Realm()
        devices = realm.objects(PowerSensorDevice.self)
    }
}

extension DeviceListDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView .dequeueReusableCell(withIdentifier: "FormattedSensorCellID", for: indexPath) as! FormattedSensorCell
        let device = devices[indexPath.row]
        if let name = device.userDefinedName {
            cell.sensorID.text = name
        } else {
            cell.sensorID.text = device.deviceID
        }
        if let data = device.currentData {
            cell.power.text = data.formattedPower
            cell.time.text = data.accumulatedTime.stringForTime()
            cell.speed.text = data.formattedSpeed
        }
        return cell
    }
    
    // Delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(devices[indexPath.row])
        }
    }
}

class FormattedSensorCell: UITableViewCell {
    @IBOutlet weak var sensorID: UILabel!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var speed: UILabel!
    
    override func prepareForReuse() {
        sensorID.text = nil
        power.text = "0"
        time.text = 0.stringForTime()
        speed.text = "0"
    }
}
