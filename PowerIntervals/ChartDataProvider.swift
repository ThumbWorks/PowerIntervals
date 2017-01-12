//
//  ChartDataProvider.swift
//  PowerIntervals
//
//  Created by Roderic on 11/8/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

class ChartDataProvider: NSObject, JBLineChartViewDataSource, JBLineChartViewDelegate {
    var dataPoints = [WorkoutDataPoint]() {
        didSet {
            let displayPoints = displayDataPoints()
            max = displayPoints.max()
            min = displayPoints.min()
        }
    }

    var zones: PowerZone?
    
    var max: WorkoutDataPoint?
    var min: WorkoutDataPoint?
    
    var offset: Int = 0
    
    func displayDataPoints() -> [WorkoutDataPoint] {
        let count = Int(dataPoints.count)
        guard count > 0 else {
            return dataPoints
        }
        let slice = dataPoints[offset...count-1]

        return Array(slice)
    }
    
    func numberOfLines(in lineChartView: JBLineChartView!) -> UInt {
        return 8
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        return UInt(displayDataPoints().count)
    }
    
    // If a given zone is above or below the range we are showing, it may throw off our display
    // This method aims to hide the zones that are out of the range of the actual data. If the
    // zone is above the current max, then we return max. If it is below min, we return min,
    // otherwise we return the zone - min. Subtracting min keeps the data in the window.
    func regulate(zoneValue: Int, min: Int, max: Int) -> CGFloat {
        var ret: Int
        if max < zoneValue {
            ret = max
        } else if min > zoneValue {
            ret = min
        } else {
            ret = zoneValue
        }
        return CGFloat(ret - min)
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        // zone lines
        if let max = max?.watts.intValue, let min = min?.watts.intValue, let zones = zones {
            if min == max {
                return CGFloat(0)
            }
            
            switch lineIndex {
                // Neuromuscular is a special case, you can go over it
            case PowerZoneAttributes.NeuroMuscular.rawValue:
                let zoneValue = zones.neuromuscular
                if max > zoneValue {
                    return CGFloat(max - min)
                }
                return regulate(zoneValue: zones.neuromuscular, min: min, max: max)
            case PowerZoneAttributes.AnaerobicCapacity.rawValue:
                return regulate(zoneValue: zones.anaerobicCapacity, min: min, max: max)
            case PowerZoneAttributes.VO2Max.rawValue:
                return regulate(zoneValue: zones.VO2Max, min: min, max: max)
            case PowerZoneAttributes.LactateThreshold.rawValue:
                return regulate(zoneValue: zones.lactateThreshold, min: min, max: max)
            case PowerZoneAttributes.Tempo.rawValue:
                return regulate(zoneValue: zones.tempo, min: min, max: max)
            case PowerZoneAttributes.Endurance.rawValue:
                return regulate(zoneValue: zones.endurance, min: min, max: max)
            case PowerZoneAttributes.ActiveRecovery.rawValue:
                return regulate(zoneValue: zones.activeRecovery, min: min, max: max)
            default:
                return CGFloat(displayDataPoints()[Int(horizontalIndex)].watts.intValue - min)
            }
        }
        return 0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 1.0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        if let zone = PowerZoneAttributes(rawValue: lineIndex) {
            return zone.color
        }
        return .black
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, smoothLineAtLineIndex lineIndex: UInt) -> Bool {
        return true
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, fillColorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        if let zone = PowerZoneAttributes(rawValue: lineIndex) {
            return zone.fill
        }
        return nil
    }
}
//NOTE: BELOW THIS IS THE ALL ON THE SAME CHART IMPLEMENTATION
//extension DeviceListViewController: JBLineChartViewDataSource, JBLineChartViewDelegate {
//    func numberOfLines(in lineChartView: JBLineChartView!) -> UInt {
//        let realm = try! Realm()
//        let connectedDevices = realm.objects(PowerSensorDevice.self).filter("connected = true")
//        return UInt(connectedDevices.count)
//    }
//
//    func lineChartView(_ lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
//        if let workout = workout, let device = dataSource?.devices[Int(lineIndex)] {
//            let predicate = NSPredicate(format: "deviceID = %@ and watts > 0", device.deviceID)
//            return UInt(workout.dataPoints.filter(predicate).count)
//        }
//        return 0
//    }
//
//    func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
//
//        if let workout = workout, let device = dataSource?.devices[Int(lineIndex)]  {
//            let predicate = NSPredicate(format: "time == %d and deviceID == %@ and watts > 0", horizontalIndex, device.deviceID)
//            guard let dataPoint = workout.dataPoints.filter(predicate).first else {
//                return nan("no data")
//            }
//            let watts = CGFloat(dataPoint.watts)
//            return watts
//        }
//        return 0
//    }
//
//    func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
//        return UIColor.theme(offset: Int(lineIndex))
//    }
//
//    func lineChartView(_ lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
//        return 1.0
//    }
//}

extension ChartDataProvider {
    func isInLap() -> Bool {
        return offset != 0
    }
    
    func beginLap() {
        if dataPoints.count > 0 {
            offset = dataPoints.count - 1
        }
    }
    
    func endLap() {
        offset = 0
    }
    
    func showDefaultData() {
        endLap()
        let dataPoint1 = WorkoutDataPoint()
        dataPoint1.time = 0
        dataPoint1.watts = 0
        dataPoint1.deviceID = "dummy"

        let dataPoint2 = WorkoutDataPoint()
        dataPoint2.time = 100
        dataPoint2.watts = 1001
        dataPoint2.deviceID = "dummy"
        dataPoints = [dataPoint1, dataPoint2]

        let newPowerZone = PowerZone()
        newPowerZone.neuromuscular = 1000
        newPowerZone.anaerobicCapacity = 759
        newPowerZone.VO2Max = 600
        newPowerZone.lactateThreshold = 500
        newPowerZone.tempo = 350
        newPowerZone.endurance = 200
        newPowerZone.activeRecovery = 100
        zones = newPowerZone
    }
}
