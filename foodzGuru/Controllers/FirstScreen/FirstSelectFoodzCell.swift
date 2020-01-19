//
//  FirstSelectFoodzCell.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 19.01.20.
//  Copyright © 2020 sergioortiz.com. All rights reserved.
//

import UIKit

class FirstSelectFoodzCell: UICollectionViewCell {
    
    @IBOutlet weak var foodNameLabel: UILabel!
    @IBOutlet weak var foodImage: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = isSelected ? 4 : 0
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.systemIndigo.cgColor
        isSelected = false
    }
    
}
