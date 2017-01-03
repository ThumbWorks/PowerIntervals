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
import Mixpanel

class DeviceListViewController: UIViewController {
    var deviceUpdateToken: NotificationToken?
    var token: NotificationToken?

    var workoutManager: WorkoutManager?
    var workout: GroupWorkout?
    
    // Store the query results so we can get the change notifications
    var realmDataPoints: Results<WorkoutDataPoint>?
    
    var selectedDevice: PowerSensorDevice?
    
    @IBOutlet var dataSource: DeviceListDataSource?
    
    let chartDataProvider = ChartDataProvider()
    
    @IBOutlet weak var neuromuscularLabel: UILabel!
    @IBOutlet weak var anaerobicLabel: UILabel!
    @IBOutlet weak var vo2MaxLabel: UILabel!
    @IBOutlet weak var lactateLabel: UILabel!
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var enduranceLabel: UILabel!
    @IBOutlet weak var recoveryLabel: UILabel!
    
    // UIViews
    @IBOutlet weak var chartView: JBLineChartView!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet var debugButtons: [UIButton]!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // zone label constraints
    @IBOutlet weak var neuromuscularVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var anaerobicVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var vo2MaxVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var lactateThresholdVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var tempoVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var enduranceVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var activeRecoveryVerticalConstraint: NSLayoutConstraint!
    
    // some debug things
    var fakePowerMeters = [FakePowerMeter]()
    var panBegin: CGPoint?
    var zones: PowerZone?
    
    override func viewWillAppear(_ animated: Bool) {
        #if !DEBUG
            for button in debugButtons {
                button.isHidden = true
            }
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Mixpanel.mainInstance().track(event: "DeviceListViewController appeared")

        startWorkout()
        
        let realm = try! Realm()
        
        let zonesArray = realm.objects(PowerZone.self)
        
        if zonesArray.count == 0 {
            performSegue(withIdentifier: "SetZonesSegueID", sender: nil)
        } else if zonesArray.count == 1 {
            zones = zonesArray.first
            chartDataProvider.zones = zones
        } else {
            print("for some reason we have more than 1 zones object")
        }
    }
    
    override func viewDidLoad() {
        // Set up the data source for the collection view
        dataSource = DeviceListDataSource()
        
        // Chart setup
        chartView.dataSource = chartDataProvider
        chartView.delegate = chartDataProvider

        chartView.showsLineSelection = false
        chartView.showsVerticalSelection = false

        setupNotificationTokens()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SearchingSegueID" {
            let dest = segue.destination as! SearchingViewController
            dest.createFakePMFromSearch = {
                print("tapped")
                self.startFakePM(self)
            }
        }
        
        if segue.identifier == "SetZonesSegueID" {
            let dest = segue.destination as! SetZoneViewController
            dest.completion =  { (zones) in
                print("cool \(zones)")
                self.zones = zones
                self.chartDataProvider.zones = zones
                self.dismiss(animated: true, completion: { 
                    if self.collectionView.numberOfItems(inSection: 0) == 0 {
                        self.showSearching()
                    }
                })
            }
        }
    }
    
    deinit {
        deviceUpdateToken?.stop()
        token?.stop()
    }
    
    func startWorkout() {
        guard let workoutManager = workoutManager else {
            print("Need a workout manager")
            return
        }
        
        if workoutManager.isActive() {
            return
        }
        
        if collectionView.indexPathsForSelectedItems?.count == 0 {
            selectedDevice = dataSource?.devices.first
            setupSelectedDeviceToken()
        }
        
        workoutManager.startWorkout()
    }
    
    @IBAction func clear(_ sender: Any) {
        print("clear")
        
        // An out of bounds occurs when we attempt to clear mid lap
        endLap(self)
        
        // get the selected device
        if let device = selectedDevice {
            let realm = try! Realm()
            try! realm.write {
                let predicate = NSPredicate(format: "deviceID = %@", device.deviceID)
                let dataPoints = realm.objects(WorkoutDataPoint.self).filter(predicate)
                realm.delete(dataPoints)
            }
        }
    }
    
    @IBAction func beginLap(_ sender: Any) {
        // set the 0 offset for the data provider
        chartDataProvider.beginLap()
    }
    
    @IBAction func endLap(_ sender: Any) {
        chartDataProvider.endLap()
    }
    
    @IBAction func startFakePM(_ sender: AnyObject) {
        let newPowerMeter = FakePowerMeter()
        newPowerMeter.startButton()
        fakePowerMeters.append(newPowerMeter)
    }
    
    @IBAction func swipe(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            print("started swipe")
            panBegin = sender.location(in: view)
        }
        if sender.state == .ended {
            if let panBegin = panBegin {
                let stopLocation = sender.location(in: view)
                let dy = panBegin.y - stopLocation.y;
                
                for fake in fakePowerMeters {
                    if fake.deviceInstance == selectedDevice {
                        fake.powerValueToSend += Int(dy)
                    }
                }
            }
        }
    }
    
    // Debug only code for removing fake power meters
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
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
        if let min = chartDataProvider.min?.watts {
            minLabel.text = String(format: "%@", min)
        }
        maxLabel.text = String(format: "%.0f", max)
        
        if let zones = zones {
            // attach each of these to the power zone below
            updateZoneLabel(constraint: neuromuscularVerticalConstraint, attachToWattage: zones.anaerobicCapacity)
            updateZoneLabel(constraint: anaerobicVerticalConstraint, attachToWattage: zones.VO2Max)
            updateZoneLabel(constraint: vo2MaxVerticalConstraint, attachToWattage: zones.lactateThreshold)
            updateZoneLabel(constraint: lactateThresholdVerticalConstraint, attachToWattage: zones.tempo)
            updateZoneLabel(constraint: tempoVerticalConstraint, attachToWattage: zones.endurance)
            updateZoneLabel(constraint: enduranceVerticalConstraint, attachToWattage: zones.activeRecovery)
        }
        UIView.animate(withDuration: 0.8, animations: {
            self.view.setNeedsLayout()
        }, completion: {
            (value: Bool) in
            
            // if there are intersections, hide the labels
            self.recoveryLabel.isHidden = self.recoveryLabel.frame.intersects(self.enduranceLabel.frame)
            self.enduranceLabel.isHidden = self.enduranceLabel.frame.intersects(self.tempoLabel.frame)
            self.tempoLabel.isHidden = self.tempoLabel.frame.intersects(self.lactateLabel.frame)
            self.lactateLabel.isHidden = self.lactateLabel.frame.intersects(self.vo2MaxLabel.frame)
            self.vo2MaxLabel.isHidden = self.vo2MaxLabel.frame.intersects(self.anaerobicLabel.frame)
            self.anaerobicLabel.isHidden = self.anaerobicLabel.frame.intersects(self.neuromuscularLabel.frame)
        })
    }
    
    func updateZoneLabel(constraint: NSLayoutConstraint, attachToWattage: Int) {
        let min = chartView.minimumValue
        let max = chartView.maximumValue
        // Formula is ((zone - min) * height) / (max - min)
        let chartHeight = chartView.frame.height

        let chartHeightOverMaxMinusMin = chartHeight / (max - min)
        let constant = chartHeightOverMaxMinusMin * (CGFloat(attachToWattage) - min)
        constraint.constant = constant
    }
}

// notification extension
extension DeviceListViewController {
    func setupSelectedDeviceToken() {
        if let token = deviceUpdateToken {
            token.stop()
        }
        
        guard let device = selectedDevice else {
            return
        }
        let realm = try! Realm()
        // use selected device id as the predicate
        let predicate = NSPredicate(format: "deviceID = %@", device.deviceID)
        
        let fetchedDataPoints = realm.objects(WorkoutDataPoint.self).filter(predicate)
        
        var dataPoints = [WorkoutDataPoint]()
        for dataPoint in fetchedDataPoints {
            dataPoints.append(dataPoint)
        }
        realmDataPoints = fetchedDataPoints
        
        // reset the lap
        chartDataProvider.endLap()
        
        // update the data points
        chartDataProvider.dataPoints = dataPoints
        
        deviceUpdateToken = fetchedDataPoints.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            
            guard let chartView = self?.chartView else {
                return
            }
            var dataPoints = [WorkoutDataPoint]()
            for dataPoint in fetchedDataPoints {
                dataPoints.append(dataPoint)
            }
            self?.chartDataProvider.dataPoints = dataPoints
            chartView.reloadData(animated: true)
            
            if let provider = self?.chartDataProvider, let min = provider.min, let max = provider.max {
                self?.minLabel.text = String(format: "%@", min.watts)
                self?.maxLabel.text = String(format: "%@", max.watts)
            }
            
            self?.updateZoneLabels()
        }
    }
    
    func hideSearching() {
       dismiss(animated: true)
    }
    
    func showSearching() {
        performSegue(withIdentifier: "SearchingSegueID", sender: nil)

        // tell the chart to show dummy data
        chartDataProvider.showDefaultData()
        chartView.reloadData()
    }
    
    func setupNotificationTokens() {
        
        token = dataSource?.devices.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            
            if let collectionView = self?.collectionView {
                
                switch changes {
                case .initial:
                    // Results are now populated and can be accessed without blocking the UI
                    collectionView.reloadData()

                    if self?.dataSource?.devices.count == 0 {
                        if self?.zones != nil {
                            self?.showSearching()
                        }
                    } else {
                        self?.hideSearching()
                    }
                    break
                case .update(_, let deletions, let insertions, _):
                    // Query results have changed, so apply them to the TableView
                    
                    if insertions.count > 0 && collectionView.numberOfItems(inSection: 0) == 0 {
                        print("first one added")
                        self?.hideSearching()
                        if let dataSource = self?.dataSource {
                            let aDevice = dataSource.devices[0]
                            self?.selectDevice(device: aDevice)
                        }
                    }

                    collectionView.reloadData()

                    if deletions.count > 0 && collectionView.numberOfItems(inSection: 0) == 0 {
                        print("last one gone")
                        self?.showSearching()
                    }
                    break
                case .error(let err):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError("\(err)")
                    break
                }
            }
        }
    }
}

extension DeviceListViewController: UICollectionViewDelegate {
    func selectDevice(device: PowerSensorDevice) {
        selectedDevice = device
        setupSelectedDeviceToken()
        chartView.reloadData(animated: true)
        updateZoneLabels()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let dataSource = dataSource {
            
            let aDevice = dataSource.devices[indexPath.row]
            selectDevice(device: aDevice)
        }
    }
}

extension DeviceListViewController {
    @IBAction func unwindToDeviceListView(sender: UIStoryboardSegue){
    }
}

class SearchingViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        Mixpanel.mainInstance().track(event: "SearchingView appeared")
    }
    
    var createFakePMFromSearch: (() -> ())?
    @IBAction func tapped() {
        createFakePMFromSearch!()
    }

}
