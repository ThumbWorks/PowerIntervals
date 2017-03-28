//
//  FetchAthleteOperation.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 3/10/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation
import StravaKit
import RealmSwift

class ConcurrentOperation: Operation {
    override var isAsynchronous: Bool {
        return true
    }
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    override func start() {
        _executing = true
        execute()
    }
    func execute() {
        // Execute your async task here.
    }
    
    func finish() {
        // Notify the completion of async task and hence the completion of the operation
        
        _executing = false
        _finished = true
    }
}

class FetchAthlete: ConcurrentOperation {
    override func execute() {
        Strava.getAthlete({ (athlete, error) in
            if let athlete = athlete {
                print("athlete is \(athlete.firstName), \(athlete.lastName), \(athlete.email)")
                Logger.updatePerson(name: athlete.fullName, email: athlete.email)
            }
            if let error = error {
                print("no athlete \(error)")
                Logger.track(event: "fetch athlete failed")
            }
            self.finish()
        })
    }
}

class FetchZones: ConcurrentOperation {
    override func execute() {
        Strava.getAthleteZones(completionHandler: { (zones, error) in
            if let error = error {
                print("no zone \(error)")
                Logger.track(event: "fetch zone failed")
            }

            //TODO swap heartRate for power
            if let zones = zones?.power?.zones {
                // update the zone object
                
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
                
                let endurance = zones[1].min
                let tempo = zones[2].min
                let lactate = zones[3].min
                let vo2max = zones[4].min
                let anaerobic = zones[5].min
                let neuromuscular = zones[6].min
                
                print("updating realm \(endurance) \(tempo) \(lactate) \(vo2max)")
                try! realm.write {
                    if (userZones.activeRecovery == 0) {
                        realm.add(userZones)
                    }
                    // update the object if it exists, otherwise create it
                    userZones.neuromuscular = neuromuscular
                    userZones.anaerobicCapacity = anaerobic
                    userZones.VO2Max = vo2max
                    userZones.lactateThreshold = lactate
                    userZones.tempo = tempo
                    userZones.endurance = endurance
                    print("done updating realm")
                }
                print("telling the thing we are finished")
                self.finish()
            } else {
                print("no zones")
                self.finish()
            }
        })
    }
}
