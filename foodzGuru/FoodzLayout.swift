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
    static let screenSize = UIScreen.main.bounds.size
    
    // Configure Button
    static func configureButton(button: UIButton){
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.layer.borderColor = SomeApp.themeColor.cgColor
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
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
    
    // Configure Edit Text Cell
    static func configureEditTextCell(cell: EditReviewCell){
        // Cell stuff
        cell.selectionStyle = .none
        
        // Title label
        cell.titleLabel.textColor = SomeApp.themeColor
        cell.titleLabel.font = SomeApp.titleFont
        cell.titleLabel.textAlignment = .center
        
        // The textview
        cell.editReviewTextView.textColor = UIColor.gray
        cell.editReviewTextView.font = UIFont.preferredFont(forTextStyle: .body)
        cell.editReviewTextView.isScrollEnabled = true
        cell.editReviewTextView.keyboardType = UIKeyboardType.default
        cell.editReviewTextView.allowsEditingTextAttributes = true
        
        // Button
        cell.doneButton.isHidden = false
        cell.doneButton.isEnabled = true 
        cell.doneButton.backgroundColor = SomeApp.themeColor
        cell.doneButton.layer.cornerRadius = 0.5 * cell.doneButton.bounds.size.width
        cell.doneButton.layer.masksToBounds = true
    }
    
    // Pop-up table
    static func popupTable(viewController: UIViewController, transparentView: UIView, tableView: UITableView){
        // Window
        let window = UIApplication.shared.keyWindow
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        transparentView.frame = viewController.view.frame
        window?.addSubview(transparentView)
        
        // Add the table
        tableView.frame = CGRect(
            x: 0,
            y: FoodzLayout.screenSize.height,
            width: FoodzLayout.screenSize.width,
            height: FoodzLayout.screenSize.height * 0.9)
        window?.addSubview(tableView)
        
        // Cool "slide-up" animation when appearing
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        transparentView.alpha = 0.7 //Start at 0, go to 0.5
                        tableView.frame = CGRect(
                            x: 0,
                            y: FoodzLayout.screenSize.height - self.screenSize.height * 0.9 ,
                            width: FoodzLayout.screenSize.width,
                            height: FoodzLayout.screenSize.height * 0.9)
                        //self.bioTextField.becomeFirstResponder()
                        //sender.backgroundColor = .white
        },
                       completion: nil)
        
        
    }
    
}
