//
//  StartLapViewController.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 1/17/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation

class StartLapViewController: UIViewController {
    var tappedZone: ((_: UInt) -> ())?

    @IBOutlet weak var datePicker: UIDatePicker!
    
}

extension StartLapViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            print("custom")
            performSegue(withIdentifier: "CustomDurationPickerSegueID", sender: nil)
            return
        }
        
        if let tappedZone = tappedZone {
            switch indexPath.row {
            case 1:
                tappedZone(10)
            case 2:
                tappedZone(90)
            case 3:
                tappedZone(600)
            case 4:
                tappedZone(1200)
            case 5:
                tappedZone(3600)
            default:
                tappedZone(0)
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let dest = segue.destination as! CustomDurationPickerViewController
        dest.doneSelectingDuration = { (duration) in
            self.dismiss(animated: false, completion: {
                if let tappedZone = self.tappedZone {
                    tappedZone(duration)
                }
            })
        }
    }
}

extension StartLapViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 2, height: collectionView.frame.size.height / 3)
    }
}

extension StartLapViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func decorateCell(cell: LapDurationCell, withZone zone: PowerZoneAttributes) {
        cell.coloredBackgroundView.backgroundColor = zone.fill
        cell.zoneLabel.text = zone.name
        cell.durationLabel.text = zone.duration
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LapDurationCellID", for: indexPath) as! LapDurationCell
        
        if let zone = PowerZoneAttributes(rawValue: UInt(indexPath.row)) {
            decorateCell(cell: cell, withZone: zone)
        } else if indexPath.row == 0 {
            cell.durationLabel.text = "Custom Interval"
            cell.zoneLabel.text = ""
        }
        
        return cell
    }
}
