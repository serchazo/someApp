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
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height * 0.8))
        return view
    }()
    
    lazy var titleLabel : UILabel = {
        let tmpLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: SomeApp.titleFont.lineHeight + 20 ))
        
        //let textColor = UIColor.white
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: SomeApp.themeColor,
            .font: SomeApp.titleFont,
            ]
        tmpLabel.attributedText = NSAttributedString(string: "Edit your Ranking description", attributes: attributes)
        tmpLabel.textAlignment = NSTextAlignment.center
        
        return tmpLabel
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
    }

}
