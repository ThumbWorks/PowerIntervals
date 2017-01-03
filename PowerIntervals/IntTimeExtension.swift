//
//  IntTimeExtension.swift
//  PowerIntervals
//
//  Created by Roderic on 9/16/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

extension Int {
    func stringForTime() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}

extension Double {
    func stringForTime() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}
