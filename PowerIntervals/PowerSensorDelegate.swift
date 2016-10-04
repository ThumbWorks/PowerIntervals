//
//  WahooHardwareDelegate.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation

protocol PowerMeter {
}

protocol WahooHardwareDelegate {
    func hardwareConnectedState(sensor: PowerMeter, connected: Bool)
    func hardwareDebug(sensor: PowerMeter, message: String)
}

