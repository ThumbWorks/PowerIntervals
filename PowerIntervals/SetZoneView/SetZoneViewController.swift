//
//  SetZoneViewController.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 12/30/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import RealmSwift
import StravaKit
import SafariServices
import Mixpanel

class SetZoneViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    let queue = OperationQueue()
    
    @IBOutlet weak var connectWithStravaButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableYConstraint: NSLayoutConstraint!
    var completion: ((PowerZone) -> Void)?
    
    var panBegin: CGPoint?
    var panningCell: SetZoneCell?
    var safariViewController: SFSafariViewController? = nil

    var values: [UInt] = [0,0,0,0,0,0]
    var originalZones: PowerZone? {
        didSet {
            if let originalZones = originalZones {
                values = [UInt(originalZones.neuromuscular), UInt(originalZones.anaerobicCapacity), UInt(originalZones.VO2Max), UInt(originalZones.lactateThreshold), UInt(originalZones.tempo), UInt(originalZones.endurance)]
            }
        }
    }
    
    override func viewDidLoad() {
        if Strava.isAuthorized {
            connectWithStravaButton.isHidden = true
            startViewDidLoadInitializationChain()
        } else {
            connectWithStravaButton.isHidden = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(stravaAuthorizationCompleted(_:)), name: NSNotification.Name(rawValue: StravaAuthorizationCompletedNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: StravaAuthorizationCompletedNotification), object: nil)
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
    
    @IBAction func deAuthenticateStrava(_ sender: Any) {
        if Strava.isAuthorized {
            Strava.deauthorize({ (success, error) in
                if let error = error {
                    print("Error de-authorizing Strava \(error.localizedDescription)")
                }
                if success == true {
                    print("success")
                    self.connectWithStravaButton.isHidden = false
                }
            })
        }
    }
    
    @IBAction func visitThumbworks(_ sender: Any) {
        Logger.track(event: "Visit Thumbworks")
        if let url = URL(string: "http://thumbworks.io") {
            UIApplication.shared.open(url, options:[:] )
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        // do some error checking
        var current = values[0]
        for i in 1...values.count - 1 {
            let newValue = values[i]
            if newValue >= current || newValue <= 0 {
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

// Strava things
extension SetZoneViewController {
 
    func startFirstStravaInitializationChain() {
        let athlete = FetchAthlete()
        let zone = FetchZones()
        zone.completionBlock = {
            let realm = try! Realm()
            if let zonesArray = realm.objects(PowerZone.self).first {
                self.values = [UInt(zonesArray.neuromuscular), UInt(zonesArray.anaerobicCapacity), UInt(zonesArray.VO2Max), UInt(zonesArray.lactateThreshold), UInt(zonesArray.tempo), UInt(zonesArray.endurance)]
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
        zone.addDependency(athlete)
        queue.addOperation(athlete)
        queue.addOperation(zone)
    }
    
    func startViewDidLoadInitializationChain() {
        let zone = FetchZones()
        zone.completionBlock = {
            let realm = try! Realm()
            if let zonesArray = realm.objects(PowerZone.self).first {
                // TODO handle the case where there is no power zones. NBD probably
                
                let newValues = [UInt(zonesArray.neuromuscular), UInt(zonesArray.anaerobicCapacity), UInt(zonesArray.VO2Max), UInt(zonesArray.lactateThreshold), UInt(zonesArray.tempo), UInt(zonesArray.endurance)]
                if newValues != self.values {
                    print("they are different, show the update button/badge")
                } else {
                    print("The zones seem to be the same locally and on the strava server")
                }
            }
        }

        queue.addOperation(zone)
    }
    internal func stravaAuthorizationCompleted(_ notification: Notification?) {
        print("Authorization through strava happened")
        safariViewController?.dismiss(animated: true)
        guard let userInfo = notification?.userInfo,
            let status = userInfo[StravaStatusKey] as? String else {
                return
        }
        
        if status == StravaStatusSuccessValue {
           print("Authorization successful!")
           Logger.track(event: "Strava Authorization Success")
            
            DispatchQueue.main.async {
                self.connectWithStravaButton.isHidden = true
            }
            
            self.startFirstStravaInitializationChain()
           
          
        } else if let error = userInfo[StravaErrorKey] as? NSError {
            let properties: Properties = ["error": error.localizedDescription]
            Logger.track(event: "Strava Authorization error", properties: properties)
            debugPrint("Error: \(error.localizedDescription)")
        }
    }

    @IBAction func loginWithStravaButtonPressed(_ sender: Any) {
        let redirectURI = "powerintervals://localhost/oauth/signin"
        let clientSecret = Constants.STRAVA_SECRET.rawValue
        let clientID = Constants.STRAVA_CLIENTID.rawValue
        
        Strava.set(clientId: clientID, clientSecret: clientSecret, redirectURI: redirectURI)
        
        if let URL = Strava.userLogin(scope: .Public) {
            let vc = SFSafariViewController(url: URL, entersReaderIfAvailable: false)
            vc.delegate = self
            safariViewController = vc
            present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func deauthStrava(_ sender: Any) {
        
    }
}

extension SetZoneViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        print("safariViewController did finish")
    }
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        print("safariViewControllerDidFinish did complete initial load: success \(didLoadSuccessfully)")
        UIAlertController(title: "fail", message: "failed to load", preferredStyle: .alert)
    }
}

extension SetZoneViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    func decorateCell(cell: SetZoneCell, zoneName: String, color: UIColor, zoneValue: UInt, hasNextButton: Bool) {
        guard originalZones != nil else {return}
        
        cell.zoneNameLabel.text = zoneName
        cell.zoneValueTextField.backgroundColor = color.withAlphaComponent(0.5)
        cell.zoneValueTextField.text = String(zoneValue)
        
        // in iOS we attach a done button, in tvOS we do not
        attachToolBar(textField: cell.zoneValueTextField, hasNext:hasNextButton)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZoneCellID") as! SetZoneCell
        
        if values.reduce(0, +) == 0 {
            return cell
        }
        
        switch indexPath.row {
        case 0:
            decorateCell(cell: cell,
                         zoneName: PowerZoneAttributes.NeuroMuscular.name,
                         color: PowerZoneAttributes.NeuroMuscular.color,
                         zoneValue: values[0],
                         hasNextButton: true)
        case 1:
            decorateCell(cell: cell,
                         zoneName: PowerZoneAttributes.AnaerobicCapacity.name,
                         color: PowerZoneAttributes.AnaerobicCapacity.color,
                         zoneValue: values[1],
                         hasNextButton: true)
        case 2:
            decorateCell(cell: cell,
                         zoneName: PowerZoneAttributes.VO2Max.name,
                         color: PowerZoneAttributes.VO2Max.color,
                         zoneValue: values[2],
                         hasNextButton: true)
        case 3:
            decorateCell(cell: cell,
                         zoneName: PowerZoneAttributes.LactateThreshold.name,
                         color: PowerZoneAttributes.LactateThreshold.color,
                         zoneValue: values[3],
                         hasNextButton: true)
        case 4:
            decorateCell(cell: cell,
                         zoneName: PowerZoneAttributes.Tempo.name,
                         color: PowerZoneAttributes.Tempo.color,
                         zoneValue: values[4],
                         hasNextButton: true)
        case 5:
            decorateCell(cell: cell,
                         zoneName: PowerZoneAttributes.Endurance.name,
                         color: PowerZoneAttributes.Endurance.color,
                         zoneValue: values[5],
                         hasNextButton: false)
            
            
        default:
            //no op
            print("unknown row number when setting zones")
        }
        
        return cell
    }
}
