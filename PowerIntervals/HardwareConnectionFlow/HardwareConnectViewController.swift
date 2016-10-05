//
//  HardwareConnectViewController.swift
//  PowerIntervals
//
//  Created by Roderic on 10/2/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class HardwareConnectViewController: UIViewController {
    
    var successSound: AVAudioPlayer!
    var wahooHardware : WahooHardware?
    
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var phoneDongleVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var adapterDongleVerticalConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var debugButton: UIButton!
    @IBOutlet weak var debugTextField: UITextView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        let path = Bundle.main.path(forResource: "beep-hightone.aif", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        do {
            let sound = try AVAudioPlayer(contentsOf: url)
            successSound = sound
        } catch {
            // couldn't load file :(
            print("Error loading the success sound file")
        }
        
        let foreground = NSNotification.Name.UIApplicationWillEnterForeground
        NotificationCenter.default.addObserver(forName: foreground, object: nil, queue: OperationQueue.main) { (notification) in
            print("foregrounded")
            self.startAnimation()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        #if !DEBUG
            debugButton.isHidden = true
            debugTextField.isHidden = true
        #endif
        
        if wahooHardware == nil {
            let hardware = WahooHardware(hardwareDelegate: self)
            hardware.startHardware()
            wahooHardware = hardware
        }
        startAnimation()
    }
    
    @IBAction func tap30PinConnector(_ sender: AnyObject) {
        if let url = URL(string: "http://amzn.to/2drBQeE") {
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                print("Opened the URL \(success)")
            })
        }
    }
    
    @IBAction func tapAntKey(_ sender: AnyObject) {
        if let url = URL(string: "http://amzn.to/2drHQUy") {
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                print("Opened the URL \(success)")
            })
        }
    }
    
    //TODO: Make the label here hidden in release builds
    @IBAction func debugConnectHardware(_ sender: AnyObject) {
        hardwareConnectedState(sensor: FakePowerMeter(), connected: true)
    }
}

extension HardwareConnectViewController: WahooHardwareDelegate {
    func hardwareDebug(sensor: PowerMeter, message: String) {
        print("hardware connection flow \(message)")
        self.debugTextField?.text.append(message+"\n")
    }
    
    func hardwareConnectedState(sensor: PowerMeter, connected: Bool) {
        debugTextField?.text.append("connection state \(connected)\n")
        
        // If we are connected, unhide the connected label ✅
        connectedLabel.isHidden = !connected
        
        if connected {
            spinner.stopAnimating()
            instructionsLabel?.text = "Wahoo Fitness Dongle Connected"
            successSound?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.performSegue(withIdentifier: "HardwareConnectedSegueID", sender: self)
            }
        } else {
            spinner.startAnimating()
            instructionsLabel?.text = "Connect a Wahoo Fitness Dongle and an Apple 30-pin to Lightning adapter to view Power Meter Data.\n\nYou can tap the on the hardware above to order."
            // display some text stating that we need to connect hardware
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

extension HardwareConnectViewController {
    // A complex animation showing the connection of the phone, adapter and dongle
    func startAnimation() {
        // Animate connecting the adapter to the dongle
        self.adapterDongleVerticalConstraint.constant = -16
        UIView.animate(withDuration: 1, delay: 1, options: [.curveEaseInOut], animations: {
            self.view.layoutSubviews()
        }) { (completed) in
            if (!completed) {
                return
            }
            // Animate connecting the phone to the adapter
            self.phoneDongleVerticalConstraint.constant = 50
            UIView.animate(withDuration: 1, delay: 1, options: [.curveEaseInOut], animations: {
                self.view.layoutSubviews()
                }, completion: { (completed) in
                    if (!completed) {
                        return
                    }
                    
                    // Animate back to the start
                    self.adapterDongleVerticalConstraint.constant = 10
                    self.phoneDongleVerticalConstraint.constant = 99
                    UIView.animate(withDuration: 1, delay: 1, options: [.curveEaseInOut], animations: {
                        self.view.layoutSubviews()
                        }, completion: { (completed) in
                            if (!completed) {
                                return
                            }
                            self.startAnimation()
                    })
            })
        }
    }
}
