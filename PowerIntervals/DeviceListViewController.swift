//
//  DeviceListViewController.swift
//  PowerIntervals
//
//  Created by Roderic on 9/23/16.
//  Copyright © 2016 Thumbworks. All rights reserved.
//

import Foundation
import UIKit

class DeviceListViewController: UIViewController {
    
    @IBOutlet var tableDataSource: UITableViewDataSource?
    @IBOutlet var tableDelegate: UITableViewDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        tableDataSource = DeviceListDataSource()
        tableDelegate = DeviceListDelegate()
    }
}

class DeviceListDelegate: NSObject, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected ")
    }
}
