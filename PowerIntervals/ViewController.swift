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
    var fakePowerMeter : FakePowerMeter?
    var startupTimer : Timer?
    var workoutTimer : Timer?
    var intervalHistory = [IntMax]()
    var wahooDelegate : WahooHardware?
    
    //MARK: IBOutlets
    
    @IBOutlet weak var avgWattsLabel: UILabel?
    @IBOutlet weak var wattsLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var startupTimerLabel: UILabel?
    @IBOutlet weak var debugTextView: UITextView?
    @IBOutlet weak var slider: UISlider!
    
    //MARK: PowerSensorDelegate methods
    
    internal func receivedPowerReading(sensor: PowerMeter, powerReading: IntMax) {
        currentReading = 0
        wattsLabel?.text = powerReading.description
        alertText(message: powerReading.description + " " + sensor.name())
        guard let workoutTimer = workoutTimer, workoutTimer.isValid else {
            return
        }
        if workoutTimer.isValid {
            print("adding something to the history")
            intervalHistory.append(powerReading)
        }
        let average = intervalHistory.reduce(0, +) / intervalHistory.count.toIntMax()
        avgWattsLabel?.text = average.description
    }
    
    internal func hardwareConnectedState(sensor: PowerMeter, connected: Bool) {
        if connected {
            alertText(message: "hardware is connected")
        } else {
            alertText(message: "hardware is NOT connected")
        }
    }
    
    internal func hardwareDebug(sensor: PowerMeter, message: String) {
        alertText(message: message)
    }
    
    //MARK: IBActions
    
    @IBAction func viewTapped(recognizer : UITapGestureRecognizer) {
        print("tapped")
        let sheet = UIAlertController.init(title: "Select Interval", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction.init(title: "5 min", style: .default, handler: { (action) in
            self.startInterval(duration: 5*60)
            // update the test powerMeter
            self.fakePowerMeter?.powerValueToSend = 280
            self.fakePowerMeter?.range = 20
        }))
        
        sheet.addAction(UIAlertAction.init(title: "1 min", style: .default, handler: { (action) in
            self.startInterval(duration: 60)
            self.fakePowerMeter?.powerValueToSend = 340
            self.fakePowerMeter?.range = 30
        }))
        
        sheet.addAction(UIAlertAction.init(title: "30 sec", style: .default, handler: { (action) in
            self.startInterval(duration: 30)
            self.fakePowerMeter?.powerValueToSend = 450
            self.fakePowerMeter?.range = 50
        }))
        
        sheet.addAction(UIAlertAction.init(title: "5 sec", style: .default, handler: { (action) in
            self.startInterval(duration: 5)
            self.fakePowerMeter?.powerValueToSend = 685
            self.fakePowerMeter?.range = 50
        }))
        
        sheet.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
            print("Cancel")
        }))
       self.present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func debugButtonPressed(_ sender: AnyObject) {
        debugTextView?.isHidden = !(debugTextView?.isHidden)!
        slider.isHidden = !slider.isHidden
        if slider.isHidden {
            fakePowerMeter?.stop()
        } else {
            fakePowerMeter?.start()
        }
        
    }
    
    @IBAction func changeSlider(slider : UISlider) {
        fakePowerMeter?.powerValueToSend = Int(slider.value)
        fakePowerMeter?.range = Int(slider.value) / 10
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
                self.fakePowerMeter?.powerValueToSend = 100
                self.fakePowerMeter?.range = 20
                self.startupTimerLabel?.text = "Done"
            }
        })
    }
    
    //MARK: ViewController lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        
        // setup a dummy power meter
        let newPowerMeter = FakePowerMeter(delegate: self)
        fakePowerMeter = newPowerMeter
        
        // setup the real hardware
        let hardware = WahooHardware(powerSensorDelegate: self)
        hardware.startHardware()
        wahooDelegate = hardware
        
        // set the default text for the labels
        timeLabel?.text = 0.stringForTime()
        startupTimerLabel?.text = ""
        super.viewDidAppear(animated)
    }
    
    // just a helper method
    func alertText(message: String) {
        if(Thread.isMainThread) {
            debugTextView?.text.append(message+"\n")
        } else {
            DispatchQueue.main.async {
                self.debugTextView?.text.append("FROM A BACKGROUND QUEUE "+message+"\n")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UIViewController {
    @IBAction func unwindToWorkoutView(sender: UIStoryboardSegue){
    }
}

