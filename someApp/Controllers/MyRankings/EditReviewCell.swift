//
//  EditReviewCell.swift
//  someApp
//
//  Created by Sergio Ortiz on 03.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class EditReviewCell: UITableViewCell {
    var updateReviewAction: ((EditReviewCell) -> Void)?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editReviewTextView: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        updateReviewAction?(self)
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
