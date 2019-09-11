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
    var cellBasicFood = ""
    
    
    
    func decorateCell(){
        //
        self.contentView.backgroundColor = UIColor.white
        
        self.contentView.layer.cornerRadius = 20.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor  //UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true;
        
        
        self.layer.shadowColor = basicModel.themeColorOpaque.cgColor
        self.layer.shadowOffset = CGSize(width:0.0,height: 0.0)
        self.layer.shadowRadius = 20.0
        self.layer.shadowOpacity = 1.0
        self.layer.masksToBounds = false;
        self.layer.shadowPath = UIBezierPath(roundedRect:self.bounds, cornerRadius:self.contentView.layer.cornerRadius).cgPath
    }
    
    
}
