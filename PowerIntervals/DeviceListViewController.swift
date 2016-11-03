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
    
    var selectedDevice: PowerSensorDevice?
    
    @IBOutlet var dataSource: DeviceListDataSource?
    
    // UIViews
    @IBOutlet weak var chartView: JBLineChartView!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet var debugButtons: [UIButton]!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // zone label constraints
    @IBOutlet weak var vo2MaxVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var activeRecoveryVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var anaerobicVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var neromuscularVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var tempoVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var enduranceVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var lactateThresholdVerticalConstraint: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        #if !DEBUG
            for button in debugButtons {
                button.isHidden = true
            }
        #endif
        chartView.reloadData(animated: true)
    }
        
    override func viewDidLoad() {
        // Set up the data source for the collection view
        dataSource = DeviceListDataSource()
        
        // Chart setup
        chartView.dataSource = self
        chartView.delegate = self
        chartView.showsLineSelection = false
        chartView.showsVerticalSelection = false
        chartView.minimumValue = PowerZone.ActiveRecovery.watts - 40

        setupNotificationTokens()
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let selectedPath = collectionView.indexPathsForSelectedItems?.first, let powerMeterViewController = segue.destination as? PowerMeterDetailViewController {
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
        
        if collectionView.indexPathsForSelectedItems?.count == 0 {
            selectedDevice = dataSource?.devices.first
        }
        
        workout = workoutManager.startWorkout()
    }
    
    @IBAction func startFakePM(_ sender: AnyObject) {
        let newPowerMeter = FakePowerMeter()
        newPowerMeter.startButton()
        fakePowerMeters.append(newPowerMeter)
    }
    
    var panBegin: CGPoint?
    
    @IBAction func swipe(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            print("started swipe")
            panBegin = sender.location(in: view)
        }
        if sender.state == .ended {
            if let panBegin = panBegin {
                let stopLocation = sender.location(in: view)
                let dy = panBegin.y - stopLocation.y;
                print("dy is \(dy)")
                
                for fake in fakePowerMeters {
                    if fake.deviceInstance == selectedDevice {
                        print("We have a selected device")
                        fake.powerValueToSend += Int(dy)
                    }
                }
            }
        }
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
                for powerMeter in fakePowerMeters {
                    if powerMeter.deviceInstance == device {
                        powerMeter.stop()
                    }
                }
                realm.delete(device)
            }
        }
    }
    
    func updateZoneLabels() {
        let max = chartView.maximumValue
        if max == 0 {
            return
        }
        let min = chartView.minimumValue
        minLabel.text = String(format: "%.0f", min)
        maxLabel.text = String(format: "%.0f", max)
        let chartHeight = chartView.frame.height
       
        let vo2Max = PowerZone.VO2Max.watts
        let activeRecover = PowerZone.ActiveRecovery.watts
        let anaerobic = PowerZone.AnaerobicCapacity.watts
        let endurance = PowerZone.Endurance.watts
        let tempo = PowerZone.Tempo.watts
        let neromuscular = PowerZone.NeroMuscular.watts
        let lactateThreshold = PowerZone.LactateThreshold.watts
        
        // Formula is ((zone - min) * height) / (max - min)
        let chartHeightOverMaxMinusMin = chartHeight / (max - min)
        
        vo2MaxVerticalConstraint.constant = chartHeightOverMaxMinusMin * (vo2Max - min)
        activeRecoveryVerticalConstraint.constant = chartHeightOverMaxMinusMin * (activeRecover - min)
        anaerobicVerticalConstraint.constant = chartHeightOverMaxMinusMin * (anaerobic - min)
        enduranceVerticalConstraint.constant = chartHeightOverMaxMinusMin * (endurance - min)
        tempoVerticalConstraint.constant = chartHeightOverMaxMinusMin * (tempo - min)
        neromuscularVerticalConstraint.constant = chartHeightOverMaxMinusMin * (neromuscular - min)
        lactateThresholdVerticalConstraint.constant = chartHeightOverMaxMinusMin * (lactateThreshold - min)

        UIView.animate(withDuration: 1) {
            self.view.setNeedsLayout()
        }
    }
}

extension DeviceListViewController {
    func setupNotificationTokens() {
        let realm = try! Realm()
        
        generalToken = realm.addNotificationBlock { notification, realm in
            self.chartView.reloadData(animated: true)
            self.minLabel.text = String(format: "%.0f", self.chartView.minimumValue)
            self.maxLabel.text = String(format: "%.0f", self.chartView.maximumValue)
            self.updateZoneLabels()
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
        return 8
    }

    func lineChartView(_ lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        
        if let workout = workout, let device = selectedDevice, device.isInvalidated == false {
            let predicate = NSPredicate(format: "deviceID = %@ and watts > 0", device.deviceID)
            return UInt(workout.dataPoints.filter(predicate).count)
        }
        return 0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        // zone lines
        if let zone = PowerZone(rawValue: lineIndex) {
            return zone.watts
        }
        
        // device data
        if let workout = workout, let device = selectedDevice  {
            let predicate = NSPredicate(format: "time == %d and deviceID == %@ and watts > 0", horizontalIndex, device.deviceID)
            guard let dataPoint = workout.dataPoints.filter(predicate).first else {
                return nan("no data")
            }
            let watts = CGFloat(dataPoint.watts)
            return watts
        }
        return 0

    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 1.0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        
        if let zone = PowerZone(rawValue: lineIndex) {
            return zone.color
        }
        return .black
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, smoothLineAtLineIndex lineIndex: UInt) -> Bool {
        return true
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, fillColorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        if let zone = PowerZone(rawValue: lineIndex) {
            return zone.fill
        }
        return nil
    }
}
//NOTE: BELOW THIS IS THE ALL ON THE SAME CHART IMPLEMENTATION
//extension DeviceListViewController: JBLineChartViewDataSource, JBLineChartViewDelegate {
//    func numberOfLines(in lineChartView: JBLineChartView!) -> UInt {
//        let realm = try! Realm()
//        let connectedDevices = realm.objects(PowerSensorDevice.self).filter("connected = true")
//        return UInt(connectedDevices.count)
//    }
//    
//    func lineChartView(_ lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
//        if let workout = workout, let device = dataSource?.devices[Int(lineIndex)] {
//            let predicate = NSPredicate(format: "deviceID = %@ and watts > 0", device.deviceID)
//            return UInt(workout.dataPoints.filter(predicate).count)
//        }
//        return 0
//    }
//    
//    func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
//        
//        if let workout = workout, let device = dataSource?.devices[Int(lineIndex)]  {
//            let predicate = NSPredicate(format: "time == %d and deviceID == %@ and watts > 0", horizontalIndex, device.deviceID)
//            guard let dataPoint = workout.dataPoints.filter(predicate).first else {
//                return nan("no data")
//            }
//            let watts = CGFloat(dataPoint.watts)
//            return watts
//        }
//        return 0
//    }
//    
//    func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
//        return UIColor.theme(offset: Int(lineIndex))
//    }
//    
//    func lineChartView(_ lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
//        return 1.0
//    }
//}

extension DeviceListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let dataSource = dataSource {
            let aDevice = dataSource.devices[indexPath.row]
            selectedDevice = aDevice
            chartView.reloadData(animated: true)
            updateZoneLabels()
        }
    }
}

extension DeviceListViewController {
    @IBAction func unwindToDeviceListView(sender: UIStoryboardSegue){
    }
}
