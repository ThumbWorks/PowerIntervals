
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
import StravaKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var btDelegate: BluetoothDelegate?
    var workoutManager: WorkoutManager?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        if isRunningTests {
            return true
        }

        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().barTintColor = .powerBlue
        UINavigationBar.appearance().titleTextAttributes = [ NSForegroundColorAttributeName : UIColor.white]
        
        Logger.start()
        Logger.track(event: "App Launch")
    
        // Create the Bluetooth Delegate
        btDelegate = BluetoothDelegate()
        btDelegate?.start()
        
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
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return Strava.openURL(url, sourceApplication: sourceApplication)
    }
}

