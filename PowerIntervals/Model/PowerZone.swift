//
//  PowerZone.swift
//  PowerIntervals
//
//  Created by Roderic on 10/29/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

enum PowerZone: UInt {
    case NeroMuscular = 0, AnaerobicCapacity, VO2Max, LactateThreshold, Tempo, Endurance, ActiveRecovery
    
    var watts: CGFloat {
        switch self {
        case .ActiveRecovery: return 165.0
        case .Endurance: return 225.0
        case .Tempo: return 270.0
        case .LactateThreshold: return 315.0
        case .VO2Max: return 360.0
        case .AnaerobicCapacity: return 661.0
        case .NeroMuscular: return 1000.0
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
        case .NeroMuscular: return self.color.withAlphaComponent(0.3)
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
        case .NeroMuscular: return .purple
        }
    }
    
}
