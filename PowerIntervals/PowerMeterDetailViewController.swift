//
//  PowerMeterDetailViewController.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import UIKit
import RealmSwift

class PowerMeterDetailViewController: UIViewController {
    
    var currentReading = 0
    var startupTimer : Timer?
    var workoutTimer : Timer?
    var intervalHistory = [IntMax]()
    var wahooDelegate : WahooHardware?
    var token: NotificationToken?
    var powerMeter: PowerSensorDevice?
    //MARK: IBOutlets
    
    @IBOutlet weak var avgWattsLabel: UILabel?
    @IBOutlet weak var wattsLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var startupTimerLabel: UILabel?
    
    //MARK: IBActions
    
    @IBAction func viewTapped(recognizer : UITapGestureRecognizer) {
        print("tapped")
        let sheet = UIAlertController.init(title: "Select Interval", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction.init(title: "5 min", style: .default, handler: { (action) in
            self.startInterval(duration: 5*60)
        }))
        
        sheet.addAction(UIAlertAction.init(title: "1 min", style: .default, handler: { (action) in
            self.startInterval(duration: 60)
        }))
        
        sheet.addAction(UIAlertAction.init(title: "30 sec", style: .default, handler: { (action) in
            self.startInterval(duration: 30)
        }))
        
        sheet.addAction(UIAlertAction.init(title: "5 sec", style: .default, handler: { (action) in
            self.startInterval(duration: 5)
        }))
        
        sheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
            print("Cancel")
        }))
       self.present(sheet, animated: true, completion: nil)
    }
    
    // MARK: Private methods
    // MARK: Timers
    
    func startInterval(duration: Int) {
        // a few cleanup things
        workoutTimer?.invalidate()
        startupTimer?.invalidate()
        timeLabel?.text = duration.stringForTime()
        intervalHistory.removeAll()
        
        // start the startupTimer
        var count = 3
        startupTimerLabel?.text = String(count)
        count -= 1
        startupTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if count == 0 {
                timer.invalidate()
                self.beginWorkout(duration: duration)
                self.startupTimerLabel?.text = "GO GO GO"
            } else {
                print("startup timer fired")
                self.startupTimerLabel?.text = String(count)
                count -= 1
            }
        }
    }
    
    func beginWorkout(duration: Int) {
        var currentTime = duration
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            currentTime -= 1
            self.timeLabel?.text = currentTime.stringForTime()
            if (currentTime <= 0) {
                timer.invalidate()
                print("THE INTERVAL IS DONE")
                self.startupTimerLabel?.text = "Done"
            }
        })
    }
    
    //MARK: ViewController lifecycle
    override func viewDidAppear(_ animated: Bool) {
        // set the default text for the labels
        timeLabel?.text = 0.stringForTime()
        startupTimerLabel?.text = ""
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        timeLabel?.text = 0.stringForTime()
        startupTimerLabel?.text = ""
        
        let realm = try! Realm()
        token = realm.addNotificationBlock { notification, realm in
            self.currentReading = 0
            guard let instantPower = self.powerMeter?.currentData?.instantPower.intValue.toIntMax() else {
                return
            }
            self.wattsLabel?.text = instantPower.description
            guard let workoutTimer = self.workoutTimer, workoutTimer.isValid else {
                return
            }
            if workoutTimer.isValid {
                print("adding something to the history")
                self.intervalHistory.append(instantPower)
            }
            let average = self.intervalHistory.reduce(0, +) / self.intervalHistory.count.toIntMax()
            self.avgWattsLabel?.text = average.description
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        token?.stop()
    }
}
