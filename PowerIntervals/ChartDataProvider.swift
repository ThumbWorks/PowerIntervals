//
//  ChartDataProvider.swift
//  PowerIntervals
//
//  Created by Roderic on 11/8/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import RealmSwift

class ChartDataProvider: NSObject, JBLineChartViewDataSource, JBLineChartViewDelegate {
    var dataPoints: Results<WorkoutDataPoint>?

    func numberOfLines(in lineChartView: JBLineChartView!) -> UInt {
        return 8
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        
        if let dataPoints = dataPoints {
            return UInt(dataPoints.count)
        }
        return 0
    }
    
    func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        // zone lines
        if let zone = PowerZone(rawValue: lineIndex) {
            return zone.watts
        }
        
        if let dataPoints = dataPoints {
            return CGFloat(dataPoints[Int(horizontalIndex)].watts)
        }
        return 0
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
