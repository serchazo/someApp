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
        button.layer.cornerRadius = 15
        button.layer.borderColor = SomeApp.themeColor.cgColor
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        button.setTitleColor(SomeApp.themeColor, for: .normal)
    }
    
    static func configureButtonNoBorder(button: UIButton){
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        button.setTitleColor(SomeApp.themeColor, for: .normal)
    }
    
    // Configure profile picture
    static func configureProfilePicture(imageView: UIImageView){
        imageView.layer.cornerRadius = 0.5 * imageView.bounds.size.width
        //imageView.layer.borderColor = SomeApp.themeColor.cgColor
        imageView.layer.borderColor = UIColor.systemGray.cgColor
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
        cell.editReviewTextView.textColor = UIColor.label
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
        placeHolderAd.text = FoodzStrings.adPlaceholderLong.localized()
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
        alert.addAction(UIAlertAction(
            title: FoodzLayout.FoodzStrings.buttonOK.localized(),
            style: .default))
        vc.present(alert,animated: true, completion: nil)
    }
}

// MARK: fonts
extension FoodzLayout{
    static var cellBody: UIFont{
        return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.preferredFont(forTextStyle: .footnote).withSize(15.0))
    }
    
    
}

// MARK: General Strings
extension FoodzLayout{
    enum FoodzStrings{
        case appName
        case appURL
        case buttonOK
        case buttonCancel
        case msgError
        case log
        case loading
        case eulaTermsOfService
        case eulaTermsOfServiceURL
        case eulaPrivacyPolicy
        case eulaPrivacyPolicyURL
        case adPlaceholderLong
        case adPlaceholderShortTitle
        case adPlaceholderShortMsg
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .appName:
                return String(
                format: NSLocalizedString("FOODZ_APP_NAME", comment: "name"),
                locale: .current,
                arguments: arguments)
            case .appURL:
                return String(
                format: NSLocalizedString("FOODZ_URL", comment: "URL"),
                locale: .current,
                arguments: arguments)
            case .buttonOK:
                return String(
                format: NSLocalizedString("BUTTON_OK", comment: "OK"),
                locale: .current,
                arguments: arguments)
            case .buttonCancel:
                return String(
                format: NSLocalizedString("BUTTON_CANCEL", comment: "Cancel"),
                locale: .current,
                arguments: arguments)
            case .msgError:
                return String(
                format: NSLocalizedString("MSG_ERROR", comment: "Error"),
                locale: .current,
                arguments: arguments)
            case .log:
                return String(
                format: NSLocalizedString("LOG", comment: "Log"),
                locale: .current,
                arguments: arguments)
            case .loading:
                return String(
                format: NSLocalizedString("MSG_LOADING", comment: "Loading"),
                locale: .current,
                arguments: arguments)
            case .eulaTermsOfService:
                return String(
                format: NSLocalizedString("FOODZ_EULA_TERMSOFSERVICE", comment: "EULA"),
                locale: .current,
                arguments: arguments)
            case .eulaTermsOfServiceURL:
                return String(
                format: NSLocalizedString("FOODZ_EULA_TERMS_URL", comment: "URL"),
                locale: .current,
                arguments: arguments)
            case .eulaPrivacyPolicy:
                return String(
                format: NSLocalizedString("FOODZ_EULA_PRIVACY_POLICY", comment: "Policy"),
                locale: .current,
                arguments: arguments)
            case .eulaPrivacyPolicyURL:
                return String(
                format: NSLocalizedString("FOODZ_EULA_PRIVACY_POLICY_URL", comment: "URL"),
                locale: .current,
                arguments: arguments)
            case .adPlaceholderLong:
                return String(
                format: NSLocalizedString("AD_PLACEHOLDER_LONG", comment: "Advertisement"),
                locale: .current,
                arguments: arguments)
            case .adPlaceholderShortTitle:
                return String(
                format: NSLocalizedString("AD_PLACEHOLDER_SHORT_TITLE", comment: "Advertisement"),
                locale: .current,
                arguments: arguments)
            case .adPlaceholderShortMsg:
                return String(
                format: NSLocalizedString("AD_PLACEHOLDER_SHORT_MSG", comment: "Advertisement"),
                locale: .current,
                arguments: arguments)
            }
        }
    }
}
