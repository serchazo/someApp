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
    @IBOutlet weak var restoPointsLabel: UILabel!
    @IBOutlet weak var restoOtherInfoLabel: UILabel!
    
    @IBOutlet weak var restoPositionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            self.contentView.backgroundColor = SomeApp.themeColorOpaque
        }
    }
    

}
