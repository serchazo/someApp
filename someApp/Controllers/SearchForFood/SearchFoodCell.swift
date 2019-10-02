//
//  SearchFoodCell.swift
//  someApp
//
//  Created by Sergio Ortiz on 24.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class SearchFoodCell: UICollectionViewCell {
    
    @IBOutlet weak var cellIcon: UILabel!
    @IBOutlet weak var cellLabel: UILabel!
    
    func decorateCell(){
        
        self.contentView.layer.cornerRadius = 20.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor  //UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true;
        
    }
    
    
}
