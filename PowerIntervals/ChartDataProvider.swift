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
    
    func numberOfLines(in _: JBLineChartView!) -> UInt {
        if isInInterval() {
            return 9
        }
        return 8
    }
    
    func lineChartView(_ _: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        return UInt(displayDataPoints().count)
    }
    
    // If a given zone is above or below the range we are showing, it may throw off our display
    // This method aims to hide the zones that are out of the range of the actual data. If the
    // zone is above the current max, then we return max. If it is below min, we return min,
    // otherwise we return the zone - min. Subtracting min keeps the data in the window.
    func regulate(zoneValue: Int, min: UInt, max: UInt) -> CGFloat {
        var ret: UInt
        if max < UInt(zoneValue) {
            ret = max
        } else if min > UInt(zoneValue) {
            ret = min
        } else {
            ret = UInt(zoneValue)
        }
        return CGFloat(ret - min)
    }
    
    func lineChartView(_ _: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        // zone lines
        if let max = max?.watts.uintValue, let min = min?.watts.uintValue, let zones = zones {
            if min == max {
                return CGFloat(0)
            }
            
            switch lineIndex {
                // The top line should equal the max. Essentially the one before Neuro
            case PowerZoneAttributes.NeuroMuscular.rawValue - 1:
                return CGFloat(max - min)
                
            case PowerZoneAttributes.NeuroMuscular.rawValue:
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
                
                // 7 is the actual power that the meter recorded since we don't show active recovery threshold (0)
            case 7:
                return CGFloat(displayDataPoints()[Int(horizontalIndex)].watts.uintValue - min)

            default:
                let average = Int(intervalAverage())
                return regulate(zoneValue: average, min: min, max: max)
            }
        }
        return 0
    }
    
    func lineChartView(_ _: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 2.0
    }
    
    func lineChartView(_ _: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
     
        if lineIndex == 0 {
            return PowerZoneAttributes.NeuroMuscular.color
        }
        
        if let zone = PowerZoneAttributes(rawValue: lineIndex + 1) {
            return zone.color
        }
        
        if lineIndex == 8 {
            return .white
        }
        return .black
    }
    
    func lineChartView(_ _: JBLineChartView!, smoothLineAtLineIndex lineIndex: UInt) -> Bool {
        return true
    }
    
    func lineChartView(_ _: JBLineChartView!, fillColorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        if lineIndex == 0 {
            return PowerZoneAttributes.NeuroMuscular.fill
        }
        if let zone = PowerZoneAttributes(rawValue: lineIndex + 1) {
            return zone.fill
        }
        return .clear
    }
}

extension ChartDataProvider {
    func intervalAverage() -> UInt {
        var sum:UInt = 0
        let points = displayDataPoints()
        for point in points {
            sum = sum + point.watts.uintValue
        }
        if points.count == 0 {
            return 0
        }
        return sum / UInt(points.count)
    }
    
    func isInInterval() -> Bool {
        return offset != 0
    }
    
    func beginInterval() {
        if dataPoints.count > 0 {
            offset = dataPoints.count - 1
        }
    }
    
    func endInterval() {
        offset = 0
    }
    
    func showDefaultData() {
        endInterval()
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
        zones = newPowerZone
    }
}
