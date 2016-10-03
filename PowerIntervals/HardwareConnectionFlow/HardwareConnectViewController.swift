//
//  HardwareConnectViewController.swift
//  PowerIntervals
//
//  Created by Roderic on 10/2/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit

class HardwareConnectViewController: UIViewController, WahooHardwareDelegate {
    
    var wahooHardware : WahooHardware?
    
    @IBOutlet weak var debugTextField: UITextView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    override func viewDidAppear(_ animated: Bool) {
        if wahooHardware == nil {
            let hardware = WahooHardware(hardwareDelegate: self)
            hardware.startHardware()
            wahooHardware = hardware
        }
    }

    func hardwareConnectedState(sensor: PowerMeter, connected: Bool) {
        self.debugTextField?.text.append("connection state \(connected)\n")

        if connected {
            spinner.stopAnimating()
            performSegue(withIdentifier: "HardwareConnectedSegueID", sender: self)
        } else {
            // display some text stating that we need to connect hardware
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction func debugConnectHardware(_ sender: AnyObject) {
        performSegue(withIdentifier: "HardwareConnectedSegueID", sender: self)
    }
    
    func hardwareDebug(sensor: PowerMeter, message: String) {
        print("hardware connection flow \(message)")
        self.debugTextField?.text.append(message+"\n")

    }
}
