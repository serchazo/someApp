//
//  CommentCell.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 30.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    var likeAction: ((UITableViewCell) -> Void)?
    var moreAction: ((UITableViewCell) -> Void)?
    
    @IBAction func likeButtonPressed(_ sender: Any) {
        likeAction?(self)
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!{
        didSet{
            bodyLabel.lineBreakMode = .byWordWrapping
            bodyLabel.numberOfLines = 0
        }
    }
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var nbLikesLabel: UILabel!
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        moreAction?(self)
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
