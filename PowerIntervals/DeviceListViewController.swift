//
//  DeviceListViewController.swift
//  PowerIntervals
//
//  Created by Roderic on 9/23/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class DeviceListViewController: UIViewController {
    var token: NotificationToken?
    var realm: Realm?
    var fakePowerMeter : FakePowerMeter?

    @IBOutlet var tableDataSource: DeviceListDataSource?
    @IBOutlet var tableDelegate: UITableViewDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        let newPowerMeter = FakePowerMeter()
        fakePowerMeter = newPowerMeter

        realm = try! Realm()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140

        tableDataSource = DeviceListDataSource()
        tableView.delegate = self
        
        setupNotificationToken()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectedPath = tableView.indexPathForSelectedRow, let powerMeterViewController = segue.destination as? PowerMeterDetailViewController {
            powerMeterViewController.powerMeter = tableDataSource?.devices[selectedPath.row]
        }
    }
    
    deinit {
        token?.stop()
    }
    
    @IBAction func startFakePM(_ sender: AnyObject) {
        fakePowerMeter?.startButton()
    }
    
    // A PowerSensorDevice with a bunch of random data
    @IBAction func addAnObject(_ sender: AnyObject) {
        createObject()
    }
}

extension DeviceListViewController {
    
    
}
extension DeviceListViewController {
    func createObject() {
        let device = PowerSensorDevice()
        
        // The deviceID is the date plus a random seed so we don't have any collisions
        device.deviceID = "fake \(arc4random() % 5000)"
        let data = PowerSensorData()
        device.currentData = data
        data.accumulatedEventCount = Int(arc4random()) % 400
        data.accumulatedPower = Double(arc4random() % 1000)
        data.accumulatedTime = Double(arc4random() % 1000)
        data.accumulatedTimestamp = data.accumulatedTime.truncatingRemainder(dividingBy: 1000)
        data.accumulatedTorque = Double(arc4random() % 1000)
        data.crankRevolutions = Double(arc4random() % 10000)
        data.crankTime = Double(arc4random())
        data.crankTimestamp = Double(arc4random() % 10000)
        data.formattedCadence = "123 cadences"
        data.formattedPower = String(arc4random() % 1000) + " watts"
        data.formattedDistance = String(arc4random() % 1000) + " miles"
        data.formattedSpeed = String(arc4random() % 100) + " mph"
        
        try! realm?.write {
            realm!.add(device)
        }
    }
    
    func setupNotificationToken() {
        token = tableDataSource?.devices.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
                break
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                tableView.endUpdates()
                
                break
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
                break
            }
        }
    }
}

extension DeviceListViewController {
    @IBAction func unwindToDeviceListView(sender: UIStoryboardSegue){
    }
}

extension DeviceListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected ")
    }
}
