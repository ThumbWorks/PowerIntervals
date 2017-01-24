//
//  CustomDurationPickerViewController.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 1/18/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation

class CustomDurationPickerViewController: UIViewController {
    var doneSelectingDuration: ((_: UInt) -> ())?
    
    @IBOutlet weak var zoneColor: UIView!
    @IBOutlet weak var zoneLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!

    var isSeconds: Bool = true
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        // if we have a closure and a picker, send the selected one through the block
        if let doneSelectingDuration = doneSelectingDuration, let pickerView = pickerView {
            let multiplier = isSeconds ? 1 : 60
            let row = pickerView.selectedRow(inComponent: 0) * multiplier
            doneSelectingDuration(UInt(row))
        }
    }
}

extension CustomDurationPickerViewController: UIPickerViewDelegate {
    
    func color(for duration: Int) -> UIColor {
        switch duration {
        case PowerZoneAttributes.NeuroMuscular.range:
            return PowerZoneAttributes.NeuroMuscular.fill
        case PowerZoneAttributes.AnaerobicCapacity.range:
            return PowerZoneAttributes.AnaerobicCapacity.fill
        case PowerZoneAttributes.VO2Max.range:
            return PowerZoneAttributes.VO2Max.fill
        case PowerZoneAttributes.LactateThreshold.range:
            return PowerZoneAttributes.LactateThreshold.fill
        case PowerZoneAttributes.Tempo.range:
            return PowerZoneAttributes.Tempo.fill
        default:
            return PowerZoneAttributes.Endurance.fill
        }
    }
    
    func zoneName(for duration: Int) -> String {
        switch duration {
        case PowerZoneAttributes.NeuroMuscular.range:
            return PowerZoneAttributes.NeuroMuscular.name
        case PowerZoneAttributes.AnaerobicCapacity.range:
            return PowerZoneAttributes.AnaerobicCapacity.name
        case PowerZoneAttributes.VO2Max.range:
            return PowerZoneAttributes.VO2Max.name
        case PowerZoneAttributes.LactateThreshold.range:
            return PowerZoneAttributes.LactateThreshold.name
        case PowerZoneAttributes.Tempo.range:
            return PowerZoneAttributes.Tempo.name
        default:
            return PowerZoneAttributes.Endurance.name
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 1 {
            isSeconds = row == 0
        }
        
        let selectedNumberRow = pickerView.selectedRow(inComponent: 0)
        let multiplier = isSeconds ? 1 : 60
        let secondsValue = selectedNumberRow * multiplier
        zoneLabel.text = zoneName(for: secondsValue)
        zoneColor.backgroundColor = color(for: secondsValue)

        // hide the niceties if we are at 0 in the numbers component
        zoneLabel.isHidden = selectedNumberRow == 0
        zoneColor.isHidden = selectedNumberRow == 0
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "DejaVuSans", size: 30)
        label.textColor = .white
        
        // minute/second switch
        if component == 1 {
            if row == 0 {
                label.text = "sec"
            }
            if row == 1 {
                label.text = "min"
            }
        } else {
            // the actual row numbers
            label.text = String(row)
        }
        
        return label
    }
}

extension CustomDurationPickerViewController: UIPickerViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 1 {
            return 2
        }
        return 100000
    }
}
