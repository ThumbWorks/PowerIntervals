//
//  PowerZone.swift
//  PowerIntervals
//
//  Created by Roderic on 10/29/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

struct PowerZone2 {
    let neuromuscular: Int
    let anaerobicCapacity: Int
    let VO2Max: Int
    let lactateThreshold: Int
    let tempo: Int
    let endurance: Int
    let activeRecovery: Int
}

enum PowerZone: UInt {
    case NeuroMuscular = 0, AnaerobicCapacity, VO2Max, LactateThreshold, Tempo, Endurance, ActiveRecovery
    
    var watts: CGFloat {
        switch self {
        case .ActiveRecovery: return 165.0
        case .Endurance: return 225.0
        case .Tempo: return 270.0
        case .LactateThreshold: return 315.0
        case .VO2Max: return 360.0
        case .AnaerobicCapacity: return 661.0
        case .NeuroMuscular: return 1000.0
        }
    }
    
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
        case .NeuroMuscular: return "Neuro Muscular"
        }
    }
    
}
