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
        let cell = tableView .dequeueReusableCell(withIdentifier: "SensorCellID", for: indexPath) as! SensorCell
        let device = devices[indexPath.row]
        cell.sensorID?.text = device.description
        return cell
    }
    
}

class SensorCell: UITableViewCell {
    @IBOutlet weak var sensorID: UILabel!
    @IBOutlet weak var sensorData: UILabel!
    
}
