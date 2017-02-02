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
    var realm: Realm?
    
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
    
    @IBOutlet weak var intervalAverageLabel: UILabel!
    
    // Interval related components
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var intervalButton: UIButton!
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
    @IBOutlet weak var averageValueVerticalConstraing: NSLayoutConstraint!
    
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
        guard let realm = realm else {
            return
        }
        let zonesArray = realm.objects(PowerZone.self)
        
        if zonesArray.count == 0 {
            chartDataProvider.showDefaultData()
            zones = chartDataProvider.zones
            chartView.reloadData()
            showZones()
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
        
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") || isRunningTests {
            let path = Bundle.main.path(forResource: "PowerIntervalsTestingData", ofType: "realm")
            guard let urlPath = path else {
                print("The test data was not found")
                return
            }
            let url = URL(fileURLWithPath: urlPath)
            var config = Realm.Configuration()
            config.fileURL = url
            realm = try! Realm.init(configuration: config)
        } else {
            realm = try! Realm()
        }
        // Set up the data source for the collection view
        dataSource = DeviceListDataSource(realm: realm!)
        collectionView.dataSource = dataSource
        
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
        
        if segue.identifier == "StartIntervalSegueID" {
            let dest = segue.destination as! StartIntervalViewController
            dest.tappedZone = { (duration) in
                self.dismiss(animated: true, completion: { 
                    self.showCountdown()
                })

                if duration == 0 {
                    return
                }
                
                self.duration = duration
                self.startTimer()
                
                self.chartDataProvider.beginInterval()
                self.intervalButton.backgroundColor = .white
                self.intervalButton.setTitleColor(.powerBlue, for: .normal)
                self.intervalAverageLabel.isHidden = false
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
        Logger.track(event: "Clear button tapped")
        // An out of bounds occurs when we attempt to clear mid interval
        chartDataProvider.endInterval()
        
        // hide all of the labels
        hideLabels()
        
        // get the selected device
        if let device = selectedDevice, let realm = realm {
            try! realm.write {
                let predicate = NSPredicate(format: "deviceID = %@", device.deviceID)
                let dataPoints = realm.objects(WorkoutDataPoint.self).filter(predicate)
                realm.delete(dataPoints)
            }
        }
    }
    
    @IBAction func beginInterval(_ sender: UIButton) {
        Logger.track(event: "Interval button tapped")
        // set the 0 offset for the data provider
        if chartDataProvider.isInInterval() {
            chartDataProvider.endInterval()
            sender.backgroundColor = .clear
            sender.setTitleColor(.white, for: .normal)
            hideCountdown()
            countdownTimer?.invalidate()
            countdownTimer = nil
            intervalAverageLabel.isHidden = true
        } else {
            performSegue(withIdentifier: "StartIntervalSegueID", sender: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {

        // if there are intersections, hide the labels
        let delta = CGFloat(20.0)
        enduranceLabel.isHidden =  (tempoVerticalConstraint.constant - enduranceVerticalConstraint.constant < delta)
        tempoLabel.isHidden = (lactateThresholdVerticalConstraint.constant - tempoVerticalConstraint.constant < delta)
        lactateLabel.isHidden = (vo2MaxVerticalConstraint.constant - lactateThresholdVerticalConstraint.constant < delta)
        vo2MaxLabel.isHidden = (anaerobicVerticalConstraint.constant - vo2MaxVerticalConstraint.constant < delta)
        anaerobicLabel.isHidden = (neuromuscularVerticalConstraint.constant - anaerobicVerticalConstraint.constant < delta)
        
        guard let zones = zones else {return}
        if let max = self.chartDataProvider.max?.watts {
            neuromuscularLabel.isHidden = max.intValue < zones.neuromuscular
        }
        
        recoveryLabel.isHidden = (enduranceVerticalConstraint.constant - activeRecoveryVerticalConstraint.constant < delta)

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
//        let numberExisting = dataSource!.collectionView(collectionView, numberOfItemsInSection: 0)
//        switch numberExisting {
//        case 0:
//            newPowerMeter.name = "Stages Crank"
//        case 1:
//            newPowerMeter.name = "Tacx Stationary"
//        case 2:
//            newPowerMeter.name = "PowerTap Hub"
//        default:
//            print("No name for this PM")
//        }
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
            guard let realm = realm else {return}
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
        
        if chartDataProvider.isInInterval() {
            let average = chartDataProvider.intervalAverage()
            updateZoneLabel(constraint: averageValueVerticalConstraing, attachToWattage: Int(average))
        }
        
        view.setNeedsLayout()
    }
    
    func updateZoneLabel(constraint: NSLayoutConstraint, attachToWattage: Int) {
        let range = chartView.maximumValue - chartView.minimumValue
        if range == 0 {
            return
        }
        
        guard let minDataValue = chartDataProvider.min?.watts.intValue else {
            print("the min data value was nil")
            return
        }
        guard let maxDataValue = chartDataProvider.max?.watts.intValue else {
            print("the min data value was nil")
            return
        }
        
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
            // so that we can update the labels for the screenshot
            self.countdownLabel.text = self.duration.stringForTime()
            if self.duration == 0 {
                timer.invalidate()
                self.intervalButton.backgroundColor = .clear
                self.intervalButton.setTitleColor(.white, for: .normal)
                self.countdownTimer = nil
                self.hideCountdown()
                self.chartDataProvider.endInterval()
                self.intervalAverageLabel.text = ""
            } else {
                self.duration = self.duration - 1
                let provider = self.chartDataProvider
                self.intervalAverageLabel.text = String(provider.intervalAverage())
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
        }, completion: { (_) in
            self.updateZoneLabels()
        })
    }
    
    func showCountdown() {
        self.chartTopConstraint.constant = 85
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutSubviews()
        }, completion: { (_) in
            self.updateZoneLabels()
        })
    }
    
    func setupSelectedDeviceToken() {
        if let token = deviceUpdateToken {
            token.stop()
        }
        
        guard let device = selectedDevice else {
            return
        }
        guard let realm = realm else {return}
        // use selected device id as the predicate
        let predicate = NSPredicate(format: "deviceID = %@", device.deviceID)
        
        let fetchedDataPoints = realm.objects(WorkoutDataPoint.self).filter(predicate)
        
        var dataPoints = [WorkoutDataPoint]()
        for dataPoint in fetchedDataPoints {
            dataPoints.append(dataPoint)
        }
        realmDataPoints = fetchedDataPoints
        
        // reset the interval
        chartDataProvider.endInterval()
        
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
    
    func showZones() {
        performSegue(withIdentifier: "SetZonesSegueID", sender: nil)
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
            print("Bundle.main.bundlePath \(Bundle.main.bundlePath)")
            selectDevice(device: aDevice)
        }
    }
}

extension DeviceListViewController {
    @IBAction func unwindToDeviceListView(sender: UIStoryboardSegue){
    }
}
