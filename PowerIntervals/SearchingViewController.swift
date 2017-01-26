//
//  SearchingViewController.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 1/25/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation

class SearchingViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        Logger.track(event: "SearchingView appeared")
    }
    
    var createFakePMFromSearch: (() -> ())?
    @IBAction func tapped() {
        createFakePMFromSearch!()
    }
    
}
