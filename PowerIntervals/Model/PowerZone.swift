//
//  PowerZone.swift
//  PowerIntervals
//
//  Created by Roderic on 10/29/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//
import RealmSwift

class PowerZone: Object {
    
    override static func primaryKey() -> String? {
        return "uniqueID"
    }
    
    dynamic var uniqueID = "uniqueID"
    
    dynamic var neuromuscular: Int = 0
    dynamic var anaerobicCapacity: Int = 0
    dynamic var VO2Max: Int = 0
    dynamic var lactateThreshold: Int = 0
    dynamic var tempo: Int = 0
    dynamic var endurance: Int = 0
    dynamic var activeRecovery: Int = 0
}

enum PowerZoneAttributes: UInt {
    case NeuroMuscular = 1, AnaerobicCapacity, VO2Max, LactateThreshold, Tempo, Endurance, ActiveRecovery

    // The range of a zone is the number of seconds an athlete should be able to maintain said zone
    var range: CountableClosedRange<Int> {
        switch self {
        case .ActiveRecovery: return 1080...Int(INT_MAX)
        case .Endurance: return 3601...1080
        case .Tempo: return 1201...3600
        case .LactateThreshold: return 201...1200
        case .VO2Max: return 91...300
        case .AnaerobicCapacity: return 11...90
        case .NeuroMuscular: return 1...10
        }
    }

    var fill: UIColor {
        switch self {
        case .ActiveRecovery: return self.color
        case .Endurance: return self.color.withAlphaComponent(0.5)
        case .Tempo: return self.color.withAlphaComponent(0.5)
        case .LactateThreshold: return self.color.withAlphaComponent(0.5)
        case .VO2Max: return self.color.withAlphaComponent(0.4)
        case .AnaerobicCapacity: return self.color.withAlphaComponent(0.3)
        case .NeuroMuscular: return self.color.withAlphaComponent(0.3)
        }
    }
    
    var color: UIColor {
        switch self {
        case .ActiveRecovery: return .white
        case .Endurance: return .blue
        case .Tempo: return .green
        case .LactateThreshold: return .yellow
        case .VO2Max: return .orange
        case .AnaerobicCapacity: return .red
        case .NeuroMuscular: return .purple
        }
    }
    
    var name: String {
        switch self {
        case .ActiveRecovery: return "Active Recovery"
        case .Endurance: return "Endurance"
        case .Tempo: return "Tempo"
        case .LactateThreshold: return "Lactate Threshold"
        case .VO2Max: return "VO2Max"
        case .AnaerobicCapacity: return "Anaerobic Capacity"
        case .NeuroMuscular: return "Neuromuscular"
        }
    }
    
    var duration: String {
        switch self {
        case .ActiveRecovery: return "Forever"
        case .Endurance: return "All day"
        case .Tempo: return "60 min"
        case .LactateThreshold: return "20 min"
        case .VO2Max: return "5 min"
        case .AnaerobicCapacity: return "90 sec"
        case .NeuroMuscular: return "10 sec"
        }
    }
    
}
