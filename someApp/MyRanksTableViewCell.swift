//
//  MyRanksTableViewCell.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyRanksTableViewCell: UITableViewCell {

    @IBOutlet weak var cellIcon: UILabel!
    @IBOutlet weak var cellTitle: UILabel!
    
    @IBOutlet weak var cellCity: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
