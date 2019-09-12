//
//  RestoDetailCommentCell.swift
//  someApp
//
//  Created by Sergio Ortiz on 04.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class RestoDetailCommentCell: UITableViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var userLable: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dislikeButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
