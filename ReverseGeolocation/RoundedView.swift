//
//  RoundedView.swift
//  ReverseGeolocation
//
//  Created by Aivars Meijers on 27/06/2018.
//  Copyright © 2018 Aivars Meijers. All rights reserved.
//

import UIKit

class RoundedView: UIView {
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.masksToBounds = false
        self.layer.shadowRadius = 4.0
        self.layer.shadowOpacity = 0.2
    }
}
