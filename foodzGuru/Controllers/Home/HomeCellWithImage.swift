//
//  HomeCellWithImage.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 07.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class HomeCellWithImage: UITableViewCell {

    @IBOutlet weak var cellImage: UIImageView!{
        didSet{
            cellImage.layer.cornerRadius = 0.5 * cellImage.bounds.size.height
            cellImage.layer.masksToBounds = true
            //cellImage.layer.borderColor = SomeApp.themeColor.cgColor;
            cellImage.layer.borderColor = UIColor.systemGray.cgColor
            cellImage.layer.borderWidth = 1.0;
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!{
        didSet{
            bodyLabel.lineBreakMode = .byWordWrapping
            bodyLabel.numberOfLines = 0
            bodyLabel.font = FoodzLayout.cellBody
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
            self.contentView.backgroundColor = .systemBackground
        }
    }

}
