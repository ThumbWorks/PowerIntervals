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
    
    func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        // zone lines
        if let zone = PowerZone(rawValue: lineIndex), let max = max?.watts.intValue, let min = min?.watts.intValue {
            if min == max {
                return CGFloat(0)
            }
            // special case, neuromuscular
            if zone == .NeuroMuscular && Int(zone.watts) < max {
                return CGFloat(max)
            }

            if Int(zone.watts) < max {
                return CGFloat(zone.watts)
            } else {
                return CGFloat(max)
            }
        }

        return CGFloat(displayDataPoints()[Int(horizontalIndex)].watts)
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 1.0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        
        if let zone = PowerZone(rawValue: lineIndex) {
            return zone.color
        }
        return .black
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, smoothLineAtLineIndex lineIndex: UInt) -> Bool {
        return true
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, fillColorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        if let zone = PowerZone(rawValue: lineIndex) {
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
    func beginLap() {
        offset = dataPoints.count - 1
    }
    
    func endLap() {
        offset = 0
    }
    
    func showDefaultData() {

        let dataPoint1 = WorkoutDataPoint()
        dataPoint1.time = 0
        dataPoint1.watts = 1000
        dataPoint1.deviceID = "dummy"

        let dataPoint2 = WorkoutDataPoint()
        dataPoint2.time = 1
        dataPoint2.watts = 1001
        dataPoint2.deviceID = "dummy"
        dataPoints = [dataPoint1, dataPoint2]

    }
}
