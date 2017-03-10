//
//  DeviceListViewControlleriOSExtension.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 3/9/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation
import Mixpanel
extension DeviceListViewController {
    @IBAction func startAChat(_ sender: Any) {
        let properties: Properties = ["view": "DeviceListViewController"]
        Logger.track(event: "Start chat", properties: properties)
        Smooch.initWith(SKTSettings(appToken: Constants.SMOOCH_TOKEN.rawValue))
        Smooch.show()
    }
}
