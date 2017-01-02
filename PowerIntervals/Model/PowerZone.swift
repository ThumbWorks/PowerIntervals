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
    case NeuroMuscular = 0, AnaerobicCapacity, VO2Max, LactateThreshold, Tempo, Endurance, ActiveRecovery

    var fill: UIColor {
        switch self {
        case .ActiveRecovery: return self.color
        case .Endurance: return self.color.withAlphaComponent(0.5)
        case .Tempo: return self.color.withAlphaComponent(0.5)
        case .LactateThreshold: return self.color.withAlphaComponent(0.3)
        case .VO2Max: return self.color.withAlphaComponent(0.4)
        case .AnaerobicCapacity: return self.color.withAlphaComponent(0.3)
        case .NeuroMuscular: return self.color.withAlphaComponent(0.3)
        }
    }
    
    var color: UIColor {
        switch self {
        case .ActiveRecovery: return .lightGray
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
    
}
