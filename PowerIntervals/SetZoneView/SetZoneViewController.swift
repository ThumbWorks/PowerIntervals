//
//  SetZoneViewController.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 12/30/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import RealmSwift

class SetZoneViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableYConstraint: NSLayoutConstraint!
    var completion: ((PowerZone) -> Void)?
    
    var panBegin: CGPoint?
    var panningCell: SetZoneCell?
    
    var values: [UInt] = [0,0,0,0,0,0]
    var originalZones: PowerZone? {
        didSet {
            if let originalZones = originalZones {
                values = [UInt(originalZones.neuromuscular), UInt(originalZones.anaerobicCapacity), UInt(originalZones.VO2Max), UInt(originalZones.lactateThreshold), UInt(originalZones.tempo), UInt(originalZones.endurance)]
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Logger.track(event: "SetZoneViewController appeared")
        NotificationCenter.default.addObserver(self, selector: #selector(SetZoneViewController.keyboardNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetZoneViewController.keyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardNotification(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
        let rawAnimationCurve = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value << 16
        let animationCurve = UIViewAnimationOptions(rawValue: UInt(rawAnimationCurve))
        
        // When the keyboard comes up, determine how far to offset the centerY constraint for the tableView
        // We base this off of the actual location of the cell in the context of the overall view, then
        // adjust accordingly.
        var cellOffset: CGFloat = 0
        for cell in tableView.visibleCells {
            for view in cell.contentView.subviews {
                if view.isFirstResponder {
                    // At this point we are dealing with the appropriate textView
                    let textField = view
                    let frame = cell.convert(textField.frame, to: self.view)
                    cellOffset = frame.origin.y - tableYConstraint.constant

                    // If the keyboard is above the cell's offset, then adjust the tableview up
                    if convertedKeyboardEndFrame.minY < cellOffset {
                        let const =  convertedKeyboardEndFrame.minY - cellOffset - 44
                        tableYConstraint.constant = const
                    } else {
                        // otherwise set it back to centered vertically
                        tableYConstraint.constant = 0
                    }
                }
            }
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    func decorateCell(cell: SetZoneCell, zoneName: String, color: UIColor, zoneValue: Int, hasNextButton: Bool) {
        guard originalZones != nil else {return}
        
        cell.zoneNameLabel.text = zoneName
        cell.zoneValueTextField.backgroundColor = color.withAlphaComponent(0.5)
        cell.zoneValueTextField.text = String(zoneValue)
        attachToolBar(textField: cell.zoneValueTextField, hasNext:hasNextButton)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ZoneCellID") as! SetZoneCell
        if let originalZones = originalZones {
            
            switch indexPath.row {
            case 0:
                decorateCell(cell: cell,
                             zoneName: PowerZoneAttributes.NeuroMuscular.name,
                             color: PowerZoneAttributes.NeuroMuscular.color,
                             zoneValue: originalZones.neuromuscular,
                             hasNextButton: true)
            case 1:
                decorateCell(cell: cell,
                             zoneName: PowerZoneAttributes.AnaerobicCapacity.name,
                             color: PowerZoneAttributes.AnaerobicCapacity.color,
                             zoneValue: originalZones.anaerobicCapacity,
                             hasNextButton: true)
            case 2:
                decorateCell(cell: cell,
                             zoneName: PowerZoneAttributes.VO2Max.name,
                             color: PowerZoneAttributes.VO2Max.color,
                             zoneValue: originalZones.VO2Max,
                             hasNextButton: true)
            case 3:
                decorateCell(cell: cell,
                             zoneName: PowerZoneAttributes.LactateThreshold.name,
                             color: PowerZoneAttributes.LactateThreshold.color,
                             zoneValue: originalZones.lactateThreshold,
                             hasNextButton: true)
            case 4:
                decorateCell(cell: cell,
                             zoneName: PowerZoneAttributes.Tempo.name,
                             color: PowerZoneAttributes.Tempo.color,
                             zoneValue: originalZones.tempo,
                             hasNextButton: true)
            case 5:
                decorateCell(cell: cell,
                             zoneName: PowerZoneAttributes.Endurance.name,
                             color: PowerZoneAttributes.Endurance.color,
                             zoneValue: originalZones.endurance,
                             hasNextButton: false)
           
                
            default:
                //no op
                print("unknown row number when setting zones")
            }
        }
        return cell
    }
    
    // Attache a toolbar to the keyboard of the textField.
    // Sometimes we need a "Next" button, otherwise, don't include it
    func attachToolBar(textField: UITextField, hasNext: Bool)  {
        let barFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50)
        let numberToolbar = UIToolbar(frame: barFrame)
        numberToolbar.barStyle = UIBarStyle.default
        if hasNext {
            numberToolbar.items = [
                UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.plain, target: self, action: #selector(goToNext)),
                UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: textField, action: #selector(UIResponder.resignFirstResponder))]
        } else {
            numberToolbar.items = [
                UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: textField, action: #selector(UIResponder.resignFirstResponder))]
        }
        numberToolbar.sizeToFit()
        textField.inputAccessoryView = numberToolbar
    }
    
    // Find the next responder by
    // a) finding the current responder
    // b) incrementing the index path, then telling that guy to be the first responder
    func goToNext() {
        print("go to next")
        
        var indexPath: IndexPath?
        for cell in tableView.visibleCells {
            for view in cell.contentView.subviews {
                if view.isFirstResponder {
                    indexPath = tableView.indexPath(for: cell)
                }
            }
        }
        
        // if we got an indexPath and the NEXT index path is a SetZoneCell
        if let indexPath = indexPath, let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row + 1, section: indexPath.section)) as? SetZoneCell {
            cell.zoneValueTextField.becomeFirstResponder()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       
        let badCharacters = NSCharacterSet.decimalDigits.inverted
        if (string.rangeOfCharacter(from: badCharacters) == nil) {
           // This is a number, so far we're good
            // TODO real time error checking at some point

            for cell in tableView.visibleCells {
                if (cell.contentView.subviews.contains(textField)) {
                    if let index = tableView.indexPath(for: cell)?.row {
                        let newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
                        if let i = UInt(newString) {
                            values[index] = i
                        }
                    }
                }
            }
        } else {
            return false
        }
        return true
    }
    
    @IBAction func visitThumbworks(_ sender: Any) {
        Logger.track(event: "Visit Thumbworks")
        if let url = URL(string: "http://thumbworks.io") {
            UIApplication.shared.open(url, options:[:] )
        }
    }
    
    @IBAction func startAChat(_ sender: Any) {
        Logger.track(event: "Start chat")
        Smooch.initWith(SKTSettings(appToken: Constants.SMOOCH_TOKEN.rawValue))
        Smooch.show()
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        // do some error checking
        print("vals = \(values)")
        var current = values[0]
        for i in 1...values.count - 1 {
            let newValue = values[i]
            if newValue >= current || newValue <= 0 {
                print("invalid")
                Logger.track(event: "Invalid zones")
                let alert = UIAlertController(title: "Invalid Zones", message: "Zone Thresholds must be decreasing", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(alert, animated: true)
                return
            }
            current = newValue
        }
        
        Logger.track(event: "Valid zones")

        // set the zones object
        guard completion != nil else {
            return
        }
        
        let realm = try! Realm()
        
        let zonesArray = realm.objects(PowerZone.self)
        
        // there should only be one
        if zonesArray.count > 1 {
            print("We've got more devices than we should have. This could be problematic")
        }
        
        var userZones: PowerZone
        if let zones = zonesArray.first {
            userZones = zones
        } else {
            userZones = PowerZone()
        }
        
        // now save the zones object
        try! realm.write {
            // update the object if it exists, otherwise create it
            userZones.neuromuscular = Int(values[0])
            userZones.anaerobicCapacity = Int(values[1])
            userZones.VO2Max = Int(values[2])
            userZones.lactateThreshold = Int(values[3])
            userZones.tempo = Int(values[4])
            userZones.endurance = Int(values[5])
            
            realm.add(userZones, update: true)
        }
        
        // pass it back through the closure
        if let completion = completion {
            completion(userZones)
        }
    }
    @IBAction func pan(_ sender: UIPanGestureRecognizer) {
        // We mark the place where this pan has begun. 
        // We also mark the cell where the pan started
        if sender.state == .began {
            panBegin = sender.location(in: tableView)
            if let panBegin = panBegin, let indexPath = tableView.indexPathForRow(at: panBegin) {
                panningCell = tableView.cellForRow(at: indexPath) as! SetZoneCell?
            }
        }
        
        // Now that the pan has changed:
        // 1. get the stop location
        // 2. determine if it was a vertical or negative y delta
        // 3) Adjust the textField accordingly
        // 4) adjust the values array accordingly
        if sender.state == .changed {
            guard let oldPan = panBegin else {return}
            let stopLocation = sender.location(in: tableView)
            let dy = (oldPan.y - stopLocation.y) > 0 ? 1 : -1;
            if let text = panningCell?.zoneValueTextField.text, let num = Int(text) {
                panningCell?.zoneValueTextField.text = String(num + dy)
                if let cell = panningCell, let row = tableView.indexPath(for: cell)?.row {
                    values[row] = UInt(num)
                }
            }
            panBegin = stopLocation
        }
        
        // We're done with panning, clear the stored state
        if sender.state == .ended {
            panBegin = nil
            panningCell = nil
        }
    }
}
