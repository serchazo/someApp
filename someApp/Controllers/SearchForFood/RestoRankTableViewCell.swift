//
//  RestoRankTableViewCell.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class RestoRankTableViewCell: UITableViewCell {

    @IBOutlet weak var restoNameLabel: UILabel!
    @IBOutlet weak var restoShortDescLabel: UILabel!
    @IBOutlet weak var restoPointsLabel: UILabel!
    @IBOutlet weak var restoOtherInfoLabel: UILabel!
    
    @IBOutlet weak var restoImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            self.contentView.backgroundColor = #colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 0.4934449914)
        }

        // Configure the view for the selected state
    }
    
    func decorateCell(){
        //
        self.contentView.backgroundColor = UIColor.white
        
        self.contentView.layer.cornerRadius = 20.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = #colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 0.5131635274).cgColor  //UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true;
        
        
        /*
        self.layer.shadowColor = #colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1).cgColor
        self.layer.shadowOffset = CGSize(width:4.0,height: 4.0)
        self.layer.shadowRadius = 20.0
        self.layer.shadowOpacity = 1.0
        self.layer.masksToBounds = false;
        self.layer.shadowPath = UIBezierPath(roundedRect:self.bounds, cornerRadius:self.contentView.layer.cornerRadius).cgPath
         */
    }

}
