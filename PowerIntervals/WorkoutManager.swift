//
//  WorkoutManager.swift
//  PowerIntervals
//
//  Created by Roderic on 10/15/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import RealmSwift

class WorkoutDataPoint: Object {
    dynamic var time: Int = 0
    dynamic var watts: NSNumber = NSNumber(integerLiteral: 0)
    dynamic var deviceID: String = ""
}

class GroupWorkout: Object {
    dynamic var workoutID = UUID().uuidString
    let dataPoints = List<WorkoutDataPoint>()
    
    override static func primaryKey() -> String? {
        return "workoutID"
    }
    
    func addDataPoint(time: Int, deviceID: String, value: NSNumber) {
        let dataPoint = WorkoutDataPoint()
        dataPoint.time = time
        dataPoint.watts = value
        dataPoint.deviceID = deviceID
        dataPoints.append(dataPoint)
    }
}

class WorkoutManager: NSObject {
    var time = 0
    var timer: Timer?

    func startWorkout() -> GroupWorkout {
        let groupWorkout = GroupWorkout()
        let realm = try! Realm()
        try! realm.write {
            realm.add(groupWorkout)
        }
        time = 0
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            // fetch all power meter objects
            let realm = try! Realm()
            try! realm.write {
                
                let connectedPowerMeters = realm.objects(PowerSensorDevice.self).filter("connected = true")
                for powerMeter in connectedPowerMeters {
                    guard let power = powerMeter.currentData?.instantPower else {
                        break
                    }
                    if power.intValue > 0 {
                        groupWorkout.addDataPoint(time: self.time, deviceID: powerMeter.deviceID, value: power)
                    } else {
                        print("ditch the 0")
                    }
                }
            }
            self.time += 1
        }
        timer = newTimer
        return groupWorkout
    }
}
