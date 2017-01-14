//
//  Logger.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 1/13/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation
import Mixpanel

class Logger {
    
    class func start() {
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        if isRunningTests {
            return
        }

        let token:Constants = .MIXPANEL_TOKEN

        Mixpanel.initialize(token: token.rawValue)
    }
    
    class func track(event: String, properties: Properties? = nil) {
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        if isRunningTests {
            return
        }
        Mixpanel.mainInstance().track(event: event, properties: properties)
    }

}
