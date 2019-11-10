//
//  EditRankingTitleCell.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 09.11.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class EditRankingTitleCell: UITableViewCell {
    var doneAction: ((UITableViewCell) -> Void)?
    var cancelAction: ((UITableViewCell) -> Void)?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        doneAction?(self)
    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
        cancelAction?(self)
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
