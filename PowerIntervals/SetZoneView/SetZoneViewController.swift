//
//  SetZoneViewController.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 12/30/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

class SetZoneViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var completion: ((PowerZone) -> Void)?
    
    var values: [Int] = [0,0,0,0,0,0,0]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZoneCellID") as! SetZoneCell
        
        
        switch indexPath.row {
        case 0:
            cell.zoneNameLabel.text = PowerZoneAttributes.NeuroMuscular.name
        case 1:
            cell.zoneNameLabel.text = PowerZoneAttributes.AnaerobicCapacity.name
        case 2:
            cell.zoneNameLabel.text = PowerZoneAttributes.VO2Max.name
        case 3:
            cell.zoneNameLabel.text = PowerZoneAttributes.LactateThreshold.name
        case 4:
            cell.zoneNameLabel.text = PowerZoneAttributes.Tempo.name
        case 5:
            cell.zoneNameLabel.text = PowerZoneAttributes.Endurance.name
        case 6:
            cell.zoneNameLabel.text = PowerZoneAttributes.ActiveRecovery.name
        default:
            //no op
            print("unknown row number when setting zones")
        }
        
        return cell
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
                        if let i = Int(newString) {
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

    func textFieldDidEndEditing(_ textField: UITextField) {
        print("val \(textField.text)")
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        // do some error checking
        print("vals = \(values)")
        var current = values[0]
        for i in 1...6 {
            let newValue = values[i]
            if newValue > current && newValue > 0 {
                print("invalid")
                return
            }
            current = newValue
        }
        // set the zones object
        print("all checks out, set the object")
        guard completion != nil else {
            return
        }
        
        let zone = PowerZone(neuromuscular: values[0], anaerobicCapacity: values[1], VO2Max: values[2], lactateThreshold: values[3], tempo: values[4],endurance: values[5], activeRecovery: values[6])
        
        print("zone \(zone)")
        
        // pass it back through the closure
        if let completion = completion {
            completion(zone)
        }
    }
}

class SetZoneCell: UITableViewCell {
    @IBOutlet weak var zoneNameLabel: UILabel!
    
    @IBOutlet weak var zoneValueTextField: UITextField!
    
    
}
