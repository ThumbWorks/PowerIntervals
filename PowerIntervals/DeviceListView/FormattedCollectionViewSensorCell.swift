//
//  FormattedCollectionViewSensorCell.swift
//  PowerIntervals
//
//  Created by Roderic Campbell on 1/25/17.
//  Copyright © 2017 Thumbworks. All rights reserved.
//

import Foundation

class FormattedCollectionViewSensorCell: UICollectionViewCell {
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var sensorID: UILabel!
    @IBOutlet weak var power: UILabel!
    
    override func prepareForReuse() {
        sensorID.text = nil
        power.text = "0"
    }
    
    override func awakeFromNib() {
        layer.cornerRadius = 8.0
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1.0
        clipsToBounds = true
    }
}
