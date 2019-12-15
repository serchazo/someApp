//
//  FirstLoginAcceptEULA.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 16.11.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import SafariServices

class FirstLoginAcceptEULA: UIViewController {
    // Constants
    let segueName = "eulaAccepted"

    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.font = SomeApp.titleFont
            titleLabel.textColor = SomeApp.themeColor
            titleLabel.text = MyStrings.title.localized()
        }
    }
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!{
        didSet{
            warningLabel.text = nil
        }
    }
    
    
    @IBOutlet weak var byUsingLabel: UILabel!
    @IBOutlet weak var eulaButton: UIButton!{
        didSet{
            eulaButton.setTitleColor(SomeApp.themeColor, for: .normal)
        }
    }
    @IBOutlet weak var privacyButton: UIButton!{
        didSet{
            privacyButton.setTitleColor(SomeApp.themeColor, for: .normal)
        }
    }
    
    // Go to EULA
    @IBAction func eulaButtonPressed(_ sender: Any) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let eulaURL = FoodzLayout.FoodzStrings.eulaTermsOfServiceURL.localized()
        
        let vc = SFSafariViewController(url: URL(string: eulaURL)!, configuration: config)
        vc.navigationController?.navigationBar.titleTextAttributes = [
        NSAttributedString.Key.foregroundColor: SomeApp.themeColor]
        vc.preferredControlTintColor = SomeApp.themeColor
        vc.preferredBarTintColor = UIColor.white
        
        present(vc, animated: true)
    }
    
    @IBAction func privacyButtonPressed(_ sender: Any) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let privacyURL = FoodzLayout.FoodzStrings.eulaPrivacyPolicyURL.localized()
        
        let vc = SFSafariViewController(url: URL(string: privacyURL)!, configuration: config)
        vc.navigationController?.navigationBar.titleTextAttributes = [
        NSAttributedString.Key.foregroundColor: SomeApp.themeColor]
        vc.preferredControlTintColor = SomeApp.themeColor
        vc.preferredBarTintColor = UIColor.white
        
        present(vc, animated: true)
    }
    
    // go Button
    @IBOutlet weak var goButton: UIButton!
    
    @IBAction func goButtonPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: MyStrings.popupTitle.localized(),
            message: MyStrings.popupMsg.localized(),
            preferredStyle: .alert)
        let OKAction = UIAlertAction(title: MyStrings.popupAgree.localized(),
                                     style: .default){_ in
            self.performSegue(withIdentifier: self.segueName, sender: nil)
        }
        let notOKAction = UIAlertAction(title: MyStrings.popupNotAgree.localized(),
                                        style: .destructive, handler: { _ in
            //Alert
            let dontAgreeAlert = UIAlertController(
                title: MyStrings.popupNotAgreeTitle.localized(),
                message: MyStrings.popupNotAgreeMsg.localized(),
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized(), style: .default, handler: nil)
            dontAgreeAlert.addAction(okAction)
            self.present(dontAgreeAlert,animated:true)
        })
        alert.addAction(OKAction)
        alert.addAction(notOKAction)
        
        present(alert, animated:true)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Go button configuration
        FoodzLayout.configureButton(button: goButton)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
           return false
       }
}


// MARK: Localized Strings
extension FirstLoginAcceptEULA{
    private enum MyStrings {
        case title
        case popupTitle
        case popupMsg
        case popupAgree
        case popupNotAgree
        case popupNotAgreeTitle
        case popupNotAgreeMsg
        
        func localized(arguments: CVarArg...) -> String{
        switch self{
        case .title:
            return String(
                format: NSLocalizedString("FIRSTLOG_EULA_TITLE", comment: "I do"),
                locale: .current,
                arguments: arguments)
        case .popupTitle:
            return String(
                format: NSLocalizedString("FIRSTLOG_EULA_POPUP_TITLE", comment: "I do"),
                locale: .current,
                arguments: arguments)
        case .popupMsg:
            return String(
                format: NSLocalizedString("FIRSTLOG_EULA_POPUP_MSG", comment: "I do"),
                locale: .current,
                arguments: arguments)
        case .popupAgree:
            return String(
                format: NSLocalizedString("FIRSTLOG_EULA_POPUP_AGREE", comment: "I do"),
                locale: .current,
                arguments: arguments)
        case .popupNotAgree:
            return String(
                format: NSLocalizedString("FIRSTLOG_EULA_POPUP_NOTAGREE", comment: "I do not"),
                locale: .current,
                arguments: arguments)
        case .popupNotAgreeTitle:
            return String(
                format: NSLocalizedString("FIRSTLOG_EULA_POPUP_NOTAGREE_TITLE", comment: "Cannot"),
                locale: .current,
                arguments: arguments)
        case .popupNotAgreeMsg:
            return String(
                format: NSLocalizedString("FIRSTLOG_EULA_POPUP_NOTAGREE_MSG", comment: "I do not"),
                locale: .current,
                arguments: arguments)
        }
        }
    }
}
