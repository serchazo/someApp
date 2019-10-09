//
//  HomeCellWithIcon.swift
//  someApp
//
//  Created by Sergio Ortiz on 09.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class HomeCellWithIcon: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var bodyLabel: UILabel!{
        didSet{
            bodyLabel.lineBreakMode = .byWordWrapping
            bodyLabel.numberOfLines = 0
        }
    }
    
    @IBOutlet weak var iconLabel: UILabel!{
        didSet{
            iconLabel.layer.cornerRadius = 0.5 * iconLabel.bounds.size.height
            iconLabel.layer.masksToBounds = true
            iconLabel.layer.borderColor = SomeApp.themeColor.cgColor;
            iconLabel.layer.borderWidth = 1.0;
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        if selected {
            self.contentView.backgroundColor = SomeApp.themeColorOpaque
        }else{
            self.contentView.backgroundColor = .white
        }
    }

}
