//
//  EditableRestoCell.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 18.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class EditableRestoCell: UITableViewCell {
    var tapAction: ((UITableViewCell) -> Void)?
    
    @IBOutlet weak var restoLabel: UILabel!
    
    @IBOutlet weak var delButton: UIButton!
    
    @IBAction func delButtonPressed(_ sender: Any) {
        tapAction?(self)
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
