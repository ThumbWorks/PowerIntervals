//
//  DeviceListDataSource.swift
//  PowerIntervals
//
//  Created by Roderic on 9/23/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit

class DeviceListDataSource: NSObject {
    var devices : [PowerSensorDevice] = Array<PowerSensorDevice>()
}

extension DeviceListDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView .dequeueReusableCell(withIdentifier: "SensorCellID", for: indexPath) as! SensorCell
        cell.sensorID?.text = "SensorID: ABC"
        cell.sensorData?.text = "Data: 100w"
        return cell
    }
}

class SensorCell: UITableViewCell {
    @IBOutlet weak var sensorID: UILabel!
    @IBOutlet weak var sensorData: UILabel!
    
}
