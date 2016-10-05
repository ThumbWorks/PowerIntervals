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
   
    var picker: IntervalPicker?
    var pickerButton: UIButton?
    
    //MARK: IBOutlets
    
    @IBOutlet weak var deviceNameLabel: UIButton!
    @IBOutlet weak var avgWattsLabel: UILabel?
    @IBOutlet weak var wattsLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var startupTimerLabel: UILabel?
    
    
    //MARK: IBActions
    
    @IBAction func changeName(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Change device name", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            print("Change the name")
            let realm = try! Realm()
            try! realm.write {
                if let text = alert.textFields?[0].text {
                    self.powerMeter?.userDefinedName = text
                    self.deviceNameLabel.setTitle(text, for: .normal)
                    self.deviceNameLabel.setTitleColor(.white, for: .normal)
                }
            }
        }))
        alert.addTextField { (textField) in
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            print("Cancel")
        }))

        present(alert, animated: true, completion: nil)
    }

    //TODO: Could stand to refactor this into it's own class
    func buttonTapped() {
        picker?.removeFromSuperview()
        // need to get the value from the picker
        if let duration = picker?.intervalLength() {
            startInterval(duration: duration)
        }

        picker = nil
        pickerButton?.removeFromSuperview()
        pickerButton = nil
    }
    
    func customInterval() {
        var buttonFrame = CGRect()
        buttonFrame.size.width = self.view.frame.width
        buttonFrame.size.height = 40
        buttonFrame.origin.y = self.view.frame.maxY - buttonFrame.height
        let button = UIButton(frame: buttonFrame)
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        button.addTarget(self, action: "buttonTapped", for: .touchUpInside)
        pickerButton = button
        
        view.addSubview(button)

        var pickerFrame = self.view.frame
        pickerFrame.size.height = 200
        pickerFrame.origin.y = buttonFrame.origin.y - pickerFrame.size.height
        let intervalPicker = IntervalPicker(frame: pickerFrame)
        picker = intervalPicker
        view.addSubview(intervalPicker)
    }
    
    @IBAction func viewTapped(recognizer : UITapGestureRecognizer) {
        print("tapped")
        let sheet = UIAlertController.init(title: "Select Interval", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction.init(title: "Custom time", style: .default, handler: { (action) in
            self.customInterval()
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
        if let userDefinedName = powerMeter?.userDefinedName {
            deviceNameLabel.setTitle(userDefinedName, for: .normal)
            deviceNameLabel.setTitleColor(.white, for: .normal)
        } else {
            deviceNameLabel.setTitle(powerMeter?.name(), for: .normal)
            deviceNameLabel.setTitleColor(.gray, for: .normal)
        }
        
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

class IntervalPicker: UIPickerView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func intervalLength() -> Int {
        let seconds = selectedRow(inComponent: 1)
        let minutes = selectedRow(inComponent: 0)
        return minutes * 60 + seconds
    }
    
    func setup() {
        delegate = self
        dataSource = self
        backgroundColor = .white
        var labelFrame = CGRect()
        labelFrame.origin.x = 110
        
        labelFrame.size.width = 60
        labelFrame.size.height = 20
        labelFrame.origin.y = self.frame.size.height / 2 - labelFrame.size.height / 2
        let minLabel = UILabel(frame: labelFrame)
        minLabel.textColor = .black
        minLabel.text = "min"
        addSubview(minLabel)
        
        labelFrame.origin.x = 265
        let secLabel = UILabel(frame: labelFrame)
        secLabel.textColor = .black
        secLabel.text = "sec"
        addSubview(secLabel)
    }
}

extension IntervalPicker: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }
}

extension IntervalPicker: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 60
    }
}
