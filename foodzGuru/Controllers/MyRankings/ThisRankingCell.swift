//
//  MyRanksEditRankingTableViewCell.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class ThisRankingCell: UITableViewCell {
    
    // Actions
    var editReviewAction: ((UITableViewCell) -> Void)?
    var showRestoDetailAction: ((UITableViewCell) -> Void)?
    var likeAction: ((UITableViewCell) -> Void)?
    
    // Actions
    @IBAction func detailsButtonPressed(_ sender: Any) {
        showRestoDetailAction?(self)
    }
    @IBAction func editReviewPressed(_ sender: Any) {
        editReviewAction?(self)
    }
    
    @IBAction func likeButtonPressed(_ sender: Any) {
        likeAction?(self)
    }
    
    // Outlets
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var restoName: UILabel!
    @IBOutlet weak var pointsGivenLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var detailsButton: UIButton!
    
    
    @IBOutlet weak var borderStack: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var nbLikesLabel: UILabel!
    
    @IBOutlet weak var editReviewButton: UIButton!{
        didSet{
            editReviewButton.isEnabled = false
            editReviewButton.isHidden = true
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.selectionStyle = .none

        // Configure the view for the selected state
    }

}
