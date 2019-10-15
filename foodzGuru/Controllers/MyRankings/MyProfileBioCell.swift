//
//  MyProfileBioCell.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 14.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyProfileBioCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
