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
        //TODO may need to only check connected devices
        devices = realm.objects(PowerSensorDevice.self)
    }
}

extension DeviceListDataSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return devices.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FormattedCollectionViewSensorCellID", for: indexPath) as! FormattedCollectionViewSensorCell
        let device = devices[indexPath.row]
        if let name = device.userDefinedName {
            cell.sensorID.text = name
        } else {
            cell.sensorID.text = device.deviceID
        }
        if let data = device.currentData {
            cell.power.text = data.formattedPower
            cell.averagePower.text = data.formattedSpeed
        }
        return cell
    }
}

class FormattedCollectionViewSensorCell: UICollectionViewCell {
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var sensorID: UILabel!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var averagePower: UILabel!
    
    override func prepareForReuse() {
        sensorID.text = nil
        power.text = "0"
        averagePower.text = "0"
    }
    
    override func awakeFromNib() {
        layer.cornerRadius = 8.0
        clipsToBounds = true
    }
}

class FormattedSensorCell: UITableViewCell {
    @IBOutlet weak var sensorID: UILabel!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var speed: UILabel!
    
    override func prepareForReuse() {
        sensorID.text = nil
        power.text = "0"
        speed.text = "0"
    }
}
