//
//  MyRanksEditDescriptionCell.swift
//  someApp
//
//  Created by Sergio Ortiz on 09.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyRanksEditDescriptionCell: UITableViewCell {
    
    lazy var backView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 150))
        return view
    }()
    
    lazy var titleLabel : UILabel = {
        let tmpLabel = UILabel(frame: CGRect(x: 8, y: 8, width: self.frame.width - 16, height: 30))
        tmpLabel.text = "Edit Description"
        return tmpLabel
    }()
    
    lazy var editTextField : UITextField = {
        let tmpTextField = UITextField(frame: CGRect(x: 8, y: 38, width: self.frame.width - 16, height: 100))
        tmpTextField.text = "Enter your description here."
        return tmpTextField
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        addSubview(backView)
        backView.addSubview(titleLabel)
        backView.addSubview(editTextField)
    }

}
