//
//  FoodzLayout.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 11.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import UIKit

class FoodzLayout{
    
    // Configure Button
    static func configureButton(button: UIButton){
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.layer.borderColor = SomeApp.themeColor.cgColor
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        button.setTitleColor(SomeApp.themeColor, for: .normal)
    }
    
    // Configure profile picture
    static func configureProfilePicture(imageView: UIImageView){
        imageView.layer.cornerRadius = 0.5 * imageView.bounds.size.width
        imageView.layer.borderColor = SomeApp.themeColorOpaque.cgColor
        imageView.layer.borderWidth = 2.0
        imageView.layoutMargins = UIEdgeInsets(top: 3.0, left: 3.0, bottom: 3.0, right: 3.0)
        imageView.clipsToBounds = true
    }
    
    
}
