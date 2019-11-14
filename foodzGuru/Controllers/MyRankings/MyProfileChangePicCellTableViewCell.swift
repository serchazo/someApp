//
//  MyProfileChangePicCellTableViewCell.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 14.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyProfileChangePicCellTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var picSpinner: UIActivityIndicatorView!{
        didSet{
            if #available(iOS 13, *){
                picSpinner.style = .large
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
