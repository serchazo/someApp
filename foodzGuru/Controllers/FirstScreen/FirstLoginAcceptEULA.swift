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
    
    let segueName = "eulaAccepted"

    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.font = SomeApp.titleFont
            titleLabel.textColor = SomeApp.themeColor
            titleLabel.text = "Accept Licence Agreement"
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
        
        let eulaURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        
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
        
        let privacyURL = "https://foodzdotguru.wordpress.com/privacy-policy/"
        
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
            title: "Accept conditions",
            message: "I agree to foodz.guru Terms of Service and Privacy Policy.",
            preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "I agree", style: .default){_ in
            self.performSegue(withIdentifier: self.segueName, sender: nil)
        }
        let notOKAction = UIAlertAction(title: "I don't agree", style: .destructive, handler: { _ in
            //Alert
            let dontAgreeAlert = UIAlertController(
                title: "Can't go further",
                message: "If you don't accept the conditions you can't use the app.",
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized, style: .default, handler: nil)
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
