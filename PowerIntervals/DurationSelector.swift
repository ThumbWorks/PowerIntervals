//
//  DurationSelector.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 2/28/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation

protocol DurationSelector {
    var doneSelectingDuration: ((_: UInt) -> ())? {get set}
}
