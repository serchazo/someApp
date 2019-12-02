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
    
    static func configureButtonNoBorder(button: UIButton){
        button.backgroundColor = .white
        //button.layer.cornerRadius = 15
        //button.layer.borderColor = SomeApp.themeColor.cgColor
        //button.layer.borderWidth = 1.0
        //button.layer.masksToBounds = true
        button.titleLabel?.textAlignment = .center
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
    
    // Configure Default Ad
    static func defaultAd(adView: UIView){
        let placeHolderAd = UILabel(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        placeHolderAd.layer.cornerRadius = 15
        placeHolderAd.clipsToBounds = true
        placeHolderAd.numberOfLines = 2
        placeHolderAd.backgroundColor = .lightGray
        placeHolderAd.textAlignment = .center
        placeHolderAd.font = UIFont.preferredFont(forTextStyle: .footnote)
        placeHolderAd.text = "Place your announcement here! support@foodz.guru"
        placeHolderAd.tag = 100
        adView.addSubview(placeHolderAd)
    }
    
    static func removeDefaultAd(adView: UIView){
        if let viewWithTag = adView.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
    }
    
    // Pop-up table
    static func popupTable(viewController: UIViewController, transparentView: UIView, tableView: UITableView){
        // Window
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        //let window = UIApplication.shared.keyWindow
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
        
        tableView.layer.cornerRadius = 20
        tableView.clipsToBounds = true
        
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

// MARK: Alerts
extension FoodzLayout{
    static func showWarning(vc: UIViewController, title: String, text: String){
        let alert = UIAlertController(title: title,
                                      message: text,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert,animated: true, completion: nil)
    }
}

// MARK: fonts
extension FoodzLayout{
    static var cellBody: UIFont{
        return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.preferredFont(forTextStyle: .footnote).withSize(15.0))
    }
    
    
}
