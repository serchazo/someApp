//
//  MyRanksEditRankingTableViewCell.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyRanksEditRankingTableViewCell: UITableViewCell {

    @IBOutlet weak var restoImage: UILabel!
    @IBOutlet weak var restoName: UILabel!
    @IBOutlet weak var restoTmpInfo: UILabel!
    
    var restoForThisCell:BasicResto!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
