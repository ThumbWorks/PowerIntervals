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
    
    class func updatePerson(name: String, email: String?) {
        let instance = Mixpanel.mainInstance()
        if let email = email {
            instance.identify(distinctId: email)
        }
        Mixpanel.mainInstance().people.set(property: "name", to: name)
    }
    
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
