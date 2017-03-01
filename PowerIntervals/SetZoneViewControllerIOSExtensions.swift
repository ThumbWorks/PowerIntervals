//
//  ZoneKeyboardExtension.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 2/28/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation

extension SetZoneViewController {
    @IBAction func startAChat(_ sender: Any) {
        Logger.track(event: "Start chat")
        Smooch.initWith(SKTSettings(appToken: Constants.SMOOCH_TOKEN.rawValue))
        Smooch.show()
    }
}

extension SetZoneViewController {
    
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
}
