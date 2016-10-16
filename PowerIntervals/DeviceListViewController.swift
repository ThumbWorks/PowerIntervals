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
    var generalToken: NotificationToken?
    var token: NotificationToken?
    
    var fakePowerMeters = [FakePowerMeter]()
    
    var workoutManager: WorkoutManager?
    var workout: GroupWorkout?
    
    @IBOutlet weak var chartView: JBLineChartView!
    @IBOutlet var debugButtons: [UIButton]!
    
    @IBOutlet var dataSource: DeviceListDataSource?
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    override func viewWillAppear(_ animated: Bool) {
        #if !DEBUG
            for button in debugButtons {
                button.isHidden = true
            }
        #endif
        chartView.reloadData()

    }
        
    override func viewDidLoad() {

        dataSource = DeviceListDataSource()

        chartView.dataSource = self
        chartView.delegate = self
        
        setupNotificationToken()
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let selectedPath = collectionView.indexPathsForSelectedItems?.first, let powerMeterViewController = segue.destination as? PowerMeterDetailViewController {
            powerMeterViewController.color = UIColor.theme(offset: selectedPath.row)
            powerMeterViewController.powerMeter = dataSource?.devices[selectedPath.row]
        }
    }
    
    deinit {
        generalToken?.stop()
        token?.stop()
    }
    
    @IBAction func startWorkout(_ sender: AnyObject) {
        guard let workoutManager = workoutManager else {
            print("Need a workout manager")
            return
        }
        workout = workoutManager.startWorkout()
    }
    
    @IBAction func startFakePM(_ sender: AnyObject) {
        let newPowerMeter = FakePowerMeter()
        newPowerMeter.startButton()
        fakePowerMeters.append(newPowerMeter)
    }
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        print("long press")
        if sender.state == .began {
            let location = sender.location(in: collectionView)
            guard let indexPath = collectionView.indexPathForItem(at: location) else {
                print("Long press not on a cell")
                return
            }
            let realm = try! Realm()
            try! realm.write {
                guard let device = dataSource?.devices[indexPath.row] else {
                    print("The device doesn't exist at this index path")
                    return
                }
                realm.delete(device)
            }
        }
    }
}

extension DeviceListViewController {
    func setupNotificationToken() {
        let realm = try! Realm()
        generalToken = realm.addNotificationBlock { notification, realm in
            self.chartView.reloadData()
        }
        token = dataSource?.devices.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            if let collectionView = self?.collectionView {
                collectionView.reloadData()
            }
        }

    }
}

extension DeviceListViewController: JBLineChartViewDataSource, JBLineChartViewDelegate {
    func numberOfLines(in lineChartView: JBLineChartView!) -> UInt {
        let realm = try! Realm()
        let connectedDevices = realm.objects(PowerSensorDevice.self).filter("connected = true")
        return UInt(connectedDevices.count)
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        
        if let workout = workout, let device = dataSource?.devices[Int(lineIndex)] {
            let predicate = NSPredicate(format: "deviceID = %@ and watts > 0", device.deviceID)
            return UInt(workout.dataPoints.filter(predicate).count)
        }
        return 0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        
        if let workout = workout, let device = dataSource?.devices[Int(lineIndex)]  {
            let predicate = NSPredicate(format: "time == %d and deviceID == %@ and watts > 0", horizontalIndex, device.deviceID)
            guard let dataPoint = workout.dataPoints.filter(predicate).first else {
                return nan("no data")
            }
            let watts = CGFloat(dataPoint.watts)
            return watts
        }
        return 0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        return UIColor.theme(offset: Int(lineIndex))
    }
}

extension DeviceListViewController {
    @IBAction func unwindToDeviceListView(sender: UIStoryboardSegue){
    }
}

extension UIColor {
    class func theme(offset: Int) -> UIColor {
        // Colors derived from this
        // https://color.adobe.com/create/color-wheel/?base=4&rule=Analogous&selected=4&name=My%20Color%20Theme&mode=rgb&rgbvalues=0.04498904441069794,0.4317081288788194,0.899780888213958,0.046989044410697935,0.6858450512468613,0.9397808882139579,0.046989044410697935,0.9397808882139579,0.7075278201582945,0.04498904441069794,0.899780888213958,0.43549101375918065,0,0.8317051612442924,0.8497808882139579&swatchOrder=0,1,2,3,4
        let colors = [UIColor(netHex:0x0B6EE5),
                      UIColor(netHex:0x0CAFF0),
                      UIColor(netHex:0x0CF0B4),
                      UIColor(netHex:0x0BE56F),
                      UIColor(netHex:0x00D4D9)]
        return colors[offset % colors.count]
    }
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

