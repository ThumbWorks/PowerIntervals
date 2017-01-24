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
    var deviceUpdateToken: NotificationToken?
    var token: NotificationToken?

    var workoutManager: WorkoutManager?
    var workout: GroupWorkout?
    var zones: PowerZone?

    // Store the query results so we can get the change notifications
    var realmDataPoints: Results<WorkoutDataPoint>?
    var selectedDevice: PowerSensorDevice?
    @IBOutlet var dataSource: DeviceListDataSource?
    let chartDataProvider = ChartDataProvider()
    
    // Power Zone Labels
    @IBOutlet weak var neuromuscularLabel: UILabel!
    @IBOutlet weak var anaerobicLabel: UILabel!
    @IBOutlet weak var vo2MaxLabel: UILabel!
    @IBOutlet weak var lactateLabel: UILabel!
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var enduranceLabel: UILabel!
    @IBOutlet weak var recoveryLabel: UILabel!
    
    // Lap related components
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var lapButton: UIButton!
    var countdownTimer: Timer?
    var duration: UInt = 0

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
    
    // convencience collections
    @IBOutlet var zoneConstraintsCollection: [NSLayoutConstraint]!
    @IBOutlet var zoneLabelCollection: [UILabel]!
    
    @IBOutlet weak var chartTopConstraint: NSLayoutConstraint!
    
    // some debug things
    var fakePowerMeters = [FakePowerMeter]()
    var panBegin: CGPoint?
    
    override func viewWillAppear(_ animated: Bool) {
        #if !DEBUG
            for button in debugButtons {
                button.isHidden = true
            }
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Logger.track(event: "DeviceListViewController appeared")

        startWorkout()
        
        let realm = try! Realm()
        let zonesArray = realm.objects(PowerZone.self)
        
        if zonesArray.count == 0 {
            chartDataProvider.showDefaultData()
            zones = chartDataProvider.zones
            chartView.reloadData()
            performSegue(withIdentifier: "SetZonesSegueID", sender: nil)
        } else if zonesArray.count == 1 {
            zones = zonesArray.first
            chartDataProvider.zones = zones
            if self.dataSource?.devices.count == 0 {
                showSearching()
            }
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
        hideLabels()
        
        chartTopConstraint.constant = 0
        for constraint in zoneConstraintsCollection {
            constraint.constant = 0
        }
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "StartLapSegueID" {
            let dest = segue.destination as! StartLapViewController
            dest.tappedZone = { (duration) in
                self.dismiss(animated: true)
                
                if duration == 0 {
                    return
                }
                
                self.showCountdown()
                self.duration = duration
                self.startTimer()
                
                self.chartDataProvider.beginLap()
                self.lapButton.backgroundColor = .white
                self.lapButton.setTitleColor(.powerBlue, for: .normal)
            }
        } else if segue.identifier == "SearchingSegueID" {
            let dest = segue.destination as! SearchingViewController
            dest.createFakePMFromSearch = {
                print("tapped")
                self.startFakePM(self)
            }
        } else if segue.identifier == "SetZonesSegueID" {
            let dest = segue.destination as! SetZoneViewController
            dest.originalZones = zones
            dest.completion =  { (zones) in
                self.zones = zones
                self.chartDataProvider.zones = zones
                print("dismiss set zones")
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
        chartDataProvider.endLap()
        
        // hide all of the labels
        hideLabels()
        
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
    
    @IBAction func beginLap(_ sender: UIButton) {
        // set the 0 offset for the data provider
        if chartDataProvider.isInLap() {
            chartDataProvider.endLap()
            sender.backgroundColor = .clear
            sender.setTitleColor(.white, for: .normal)
            hideCountdown()
            countdownTimer?.invalidate()
            countdownTimer = nil
        } else {
            performSegue(withIdentifier: "StartLapSegueID", sender: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        // if there are intersections, hide the labels        
        enduranceLabel.isHidden = self.enduranceLabel.frame.intersects(self.tempoLabel.frame)
        tempoLabel.isHidden = self.tempoLabel.frame.intersects(self.lactateLabel.frame)
        lactateLabel.isHidden = self.lactateLabel.frame.intersects(self.vo2MaxLabel.frame)
        vo2MaxLabel.isHidden = self.vo2MaxLabel.frame.intersects(self.anaerobicLabel.frame)
        anaerobicLabel.isHidden = self.anaerobicLabel.frame.intersects(self.neuromuscularLabel.frame)

        guard let zones = zones else {return}
        if let max = self.chartDataProvider.max?.watts {
            neuromuscularLabel.isHidden = max.intValue < zones.neuromuscular
        }
        
        self.recoveryLabel.isHidden = self.recoveryLabel.frame.intersects(self.enduranceLabel.frame)
        // and if the chart min is greater than 0, hide the recovery label
        if let min = self.chartDataProvider.min?.watts {
            self.recoveryLabel.isHidden = min.intValue > zones.endurance
        }
    }
}

// Debug things
extension DeviceListViewController {
    // Debug code for starting a fake PM
    @IBAction func startFakePM(_ sender: AnyObject) {
        let newPowerMeter = FakePowerMeter()
        newPowerMeter.startButton()
        fakePowerMeters.append(newPowerMeter)
    }
    
    @IBAction func swipe(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
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
}

// notification extension
extension DeviceListViewController {
    
    func updateZoneLabels() {
        guard let max = chartDataProvider.max?.watts else { return }
        guard let min = chartDataProvider.min?.watts else { return }
        guard let zones = zones else {
            print("No zones set when we attempted to update the labels")
            hideLabels()
            return
        }
        if max == 0 {
            return
        }
        
        minLabel.text = String(format: "%@", min)
        maxLabel.text = String(format: "%@", max)
        
        // attach each of these to the power zone below
        updateZoneLabel(constraint: neuromuscularVerticalConstraint, attachToWattage: zones.neuromuscular)
        updateZoneLabel(constraint: anaerobicVerticalConstraint, attachToWattage: zones.anaerobicCapacity)
        updateZoneLabel(constraint: vo2MaxVerticalConstraint, attachToWattage: zones.VO2Max)
        updateZoneLabel(constraint: lactateThresholdVerticalConstraint, attachToWattage: zones.lactateThreshold)
        updateZoneLabel(constraint: tempoVerticalConstraint, attachToWattage: zones.tempo)
        updateZoneLabel(constraint: enduranceVerticalConstraint, attachToWattage: zones.endurance)
        
        view.setNeedsLayout()
    }
    
    func updateZoneLabel(constraint: NSLayoutConstraint, attachToWattage: Int) {
        let range = chartView.maximumValue - chartView.minimumValue
        if range == 0 {
            return
        }
        
        guard let minDataValue = chartDataProvider.min?.watts.intValue else {return}
        guard let maxDataValue = chartDataProvider.max?.watts.intValue else {return}
        
        if maxDataValue < attachToWattage {
            constraint.constant = CGFloat(maxDataValue)
            return
        } else if  minDataValue > attachToWattage {
            constraint.constant = -50
            return
        }
        
        // Formula is ((zone - min) * height) / (max - min)
        let chartHeight = chartView.frame.height
        
        let pixelsPerWatt = chartHeight / range
        let constant = pixelsPerWatt * CGFloat(attachToWattage - minDataValue)
        constraint.constant = constant + 5
    }
    
    func startTimer() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.countdownLabel.text = self.duration.stringForTime()
            if self.duration == 0 {
                timer.invalidate()
                self.lapButton.backgroundColor = .clear
                self.lapButton.setTitleColor(.white, for: .normal)
                self.countdownTimer = nil
                self.hideCountdown()
                self.chartDataProvider.endLap()
            } else {
                self.duration = self.duration - 1
            }
        }
    }
    
    func hideLabels() {
        for zone in zoneLabelCollection {
            zone.isHidden = true
        }
    }
    
    func hideCountdown() {
        self.chartTopConstraint.constant = 0
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutSubviews()
        })
    }
    
    func showCountdown() {
        self.chartTopConstraint.constant = 85
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseInOut, animations: {
            self.view.layoutSubviews()
        })
    }
    
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
                let string = String(format: "%@", min.watts)
                self?.minLabel.text = string
                self?.maxLabel.text = String(format: "%@", max.watts)
            }

            self?.updateZoneLabels()
        }
    }
    
    func hideSearching() {
        if self.presentedViewController?.isKind(of: SearchingViewController.self) == true {
            dismiss(animated: true)
        }
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
                        self?.zones = self?.chartDataProvider.zones
                        self?.hideSearching()
                        if let dataSource = self?.dataSource {
                            let aDevice = dataSource.devices[0]
                            self?.selectDevice(device: aDevice)
                        }
                    }

                    collectionView.reloadData()

                    if deletions.count > 0 && collectionView.numberOfItems(inSection: 0) == 0 {
                        print("last one gone")
                        self?.hideLabels()
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
        Logger.track(event: "SearchingView appeared")
    }
    
    var createFakePMFromSearch: (() -> ())?
    @IBAction func tapped() {
        createFakePMFromSearch!()
    }

}
