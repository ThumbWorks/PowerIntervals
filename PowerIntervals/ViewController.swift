//
//  ViewController.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PowerSensorDelegate {
    
    var currentReading = 0
    var powerMeter : FakePowerMeter?
    var startupTimer : Timer?
    var workoutTimer : Timer?
    var intervalHistory = [Int]()
    
    //MARK: IBOutlets
    
    @IBOutlet weak var avgWattsLabel: UILabel?
    @IBOutlet weak var wattsLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var startupTimerLabel: UILabel?

    
    //MARK: PowerSensorDelegate methods
    
    internal func receivedPowerReading(powerReading: Int) {
        print("We got a new power reading", powerReading)
        currentReading = 0
        wattsLabel?.text = powerReading.description
        
        guard let workoutTimer = workoutTimer, workoutTimer.isValid else {
            return
        }
        if workoutTimer.isValid {
            print("adding something to the history")
            intervalHistory.append(powerReading)
        }
        let average = intervalHistory.reduce(0, +) / intervalHistory.count
        avgWattsLabel?.text = average.description
    }
    
    //MARK: IBActions
    
    @IBAction func viewTapped(recognizer : UITapGestureRecognizer) {
        print("tapped")
        let sheet = UIAlertController.init(title: "Select Interval", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction.init(title: "5 min", style: .default, handler: { (action) in
            self.startInterval(duration: 5*60)
            // update the test powerMeter
            self.powerMeter?.powerValueToSend = 280
            self.powerMeter?.range = 20
        }))
        
        sheet.addAction(UIAlertAction.init(title: "1 min", style: .default, handler: { (action) in
            self.startInterval(duration: 60)
            self.powerMeter?.powerValueToSend = 340
            self.powerMeter?.range = 30
        }))
        
        sheet.addAction(UIAlertAction.init(title: "30 sec", style: .default, handler: { (action) in
            self.startInterval(duration: 30)
            self.powerMeter?.powerValueToSend = 450
            self.powerMeter?.range = 50
        }))
        
        sheet.addAction(UIAlertAction.init(title: "5 sec", style: .default, handler: { (action) in
            self.startInterval(duration: 5)
            self.powerMeter?.powerValueToSend = 685
            self.powerMeter?.range = 50
        }))
        
        sheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
            print("Cancel")
        }))
       self.present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func changeSlider(slider : UISlider) {
        powerMeter?.powerValueToSend = Int(slider.value)
        powerMeter?.range = Int(slider.value) / 10
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
                self.powerMeter?.powerValueToSend = 100
                self.powerMeter?.range = 20
                self.startupTimerLabel?.text = "Done"
            }
        })
    }
    
    //MARK: ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup a dumb power meter
        let newPowerMeter = FakePowerMeter(delegate: self)
        newPowerMeter.start()
        powerMeter = newPowerMeter
        
        // set the default text for the labels
        timeLabel?.text = 0.stringForTime()
        startupTimerLabel?.text = ""
        avgWattsLabel?.text = "0 w"
        wattsLabel?.text = "0 w"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension Int {
    func stringForTime() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}

