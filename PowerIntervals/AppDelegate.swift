
//
//  AppDelegate.swift
//  PowerIntervals
//
//  Created by Roderic on 9/11/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var btDelegate: BluetoothDelegate?
    var wahooHardware: WahooHardware?
    var workoutManager: WorkoutManager?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        if isRunningTests {
            return true
        }
        // Create the Bluetooth Delegate
        btDelegate = BluetoothDelegate()
        btDelegate?.start()
        
        // Create the Ant Hardware
        wahooHardware = WahooHardware()
        wahooHardware?.startHardware()
        
        // Workout Timer
        workoutManager = WorkoutManager()
        
        if let nav = application.delegate?.window??.rootViewController as! UINavigationController?  {
            if let deviceListViewController = nav.topViewController as! DeviceListViewController? {
                deviceListViewController.workoutManager = workoutManager
            }
        }
        
        Fabric.with([Crashlytics.self])
        return true
    }
}

