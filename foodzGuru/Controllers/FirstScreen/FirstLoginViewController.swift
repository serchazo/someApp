//
//  FirstLoginViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 25.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class FirstLoginViewController: UIViewController {
    private let segueUserNameOK = "segueUserNameOK"
    
    private var user:User!
    private var userName:String!
    private var userNameOKFlag = false
    
    // MARK: outlets
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.text = MyStrings.title.localized()
        }
    }
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var userNameTakenLabel: UILabel!
    @IBOutlet weak var verifyNameSpinner: UIActivityIndicatorView!{
        didSet{
                verifyNameSpinner.style = .large
        }
    }
    @IBOutlet weak var goButton: UIButton!
    
    // MARK: Timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameField.delegate = self
        userNameField.keyboardType = .default
        userNameField.autocorrectionType = .no
        userNameField.placeholder = MyStrings.fieldPlaceholder.localized()
        
        // Get user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
        }
        
        // Go button configuration
        configureGoButton()
        // Do any additional setup after loading the view.
        userNameTakenLabel.isHidden = true
        
        self.hideKeyboardWhenTappedAround()
    }
    
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.segueUserNameOK,
            let seguedVC = segue.destination as? FirstLoginSecondScreen{
            seguedVC.userName = self.userName
        }
    }
 
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    // MARK: objc funcs
    @objc func verifyUserName(){
        // If the textfield is too short: alert and do nothing
        guard let nickname = userNameField.text,
            nickname.count >= 4 else {
            let alert = UIAlertController(
                title: MyStrings.nickInvalidTitle.localized(),
                message: MyStrings.nickInvalidMsg.localized(),
                preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                style: .default,
                handler: nil)
            alert.addAction(okAction)
            self.present(alert,animated: true)
            return
        }
        
        verifyNameSpinner.isHidden = false
        verifyNameSpinner.startAnimating()
        let pattern = "[^A-Za-z0-9]+"
        let tmpUserName = nickname.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        self.userName = tmpUserName.lowercased()
        
        SomeApp.dbUserData.queryOrdered(byChild: "nickname").queryEqual(toValue: userName).observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.exists(){
                // The username exists
                self.userNameField.text = self.userName
                self.userNameTakenLabel.textColor = .systemRed
                self.userNameTakenLabel.text = MyStrings.nickTaken.localized()
                self.userNameTakenLabel.isHidden = false
                
            }else  {
                // The username doesn't exist
                self.userNameField.text = self.userName
                self.userNameOKFlag = true
                self.userNameTakenLabel.textColor = .label 
                self.userNameTakenLabel.text = MyStrings.nickOK.localized()
                self.userNameTakenLabel.isHidden = false
            }
            self.configureGoButton()
            self.verifyNameSpinner.stopAnimating()
        })
    }
    
    // If the Go button is pressed,
    @objc func goButtonPressed(){
        self.performSegue(withIdentifier: self.segueUserNameOK, sender: nil)
    }
    
    // Configure the Go button
    private func configureGoButton(){
        FoodzLayout.configureButton(button: goButton)
        
       if userNameOKFlag{
        goButton.setTitle(MyStrings.buttonGo.localized(), for: .normal)
        goButton.removeTarget(self, action: #selector(verifyUserName), for: .touchUpInside)
        goButton.addTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
       }else{
        goButton.setTitle(MyStrings.buttonVerify.localized(), for: .normal)
        goButton.removeTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
        goButton.addTarget(self, action: #selector(verifyUserName), for: .touchUpInside)
        }
    }
}

// MARK: helper funcs
extension FirstLoginViewController{
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: Text field extension
extension FirstLoginViewController: UITextFieldDelegate{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        userNameOKFlag = false
        configureGoButton()
        userNameTakenLabel.isHidden = true
        return true
    }
    
    // Maximum characters for username
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        let changedText = currentText.replacingCharacters(in: stringRange, with: string)
        return changedText.count <= 15
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        userNameField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userNameField.resignFirstResponder()
        return true
    }
}

// MARK: Localized Strings
extension FirstLoginViewController{
    private enum MyStrings {
        case title
        case fieldPlaceholder
        case nickInvalidTitle
        case nickInvalidMsg
        case nickTaken
        case nickOK
        case buttonGo
        case buttonVerify
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .title:
                return String(
                format: NSLocalizedString("FIRSTLOG1_TITLE", comment: "Configure"),
                locale: .current,
                arguments: arguments)
            case .fieldPlaceholder:
                return String(
                format: NSLocalizedString("FIRSTLOG1_FIELD_PLACEHOLDER", comment: "username"),
                locale: .current,
                arguments: arguments)
            case .nickInvalidTitle:
                return String(
                format: NSLocalizedString("FIRSTLOG1_INVALID_TITLE", comment: "Invalid"),
                locale: .current,
                arguments: arguments)
            case .nickInvalidMsg:
                return String(
                format: NSLocalizedString("FIRSTLOG1_INVALID_MSG", comment: "Invalid"),
                locale: .current,
                arguments: arguments)
            case .nickTaken:
                return String(
                format: NSLocalizedString("FIRSTLOG1_NICK_TAKEN", comment: "Taken"),
                locale: .current,
                arguments: arguments)
            case .nickOK:
                return String(
                format: NSLocalizedString("FIRSTLOG1_NICK_OK", comment: "OK"),
                locale: .current,
                arguments: arguments)
            case .buttonGo:
                return String(
                format: NSLocalizedString("FIRSTLOG1_BUTTON_GO", comment: "Go"),
                locale: .current,
                arguments: arguments)
            case .buttonVerify:
                return String(
                format: NSLocalizedString("FIRSTLOG1_BUTTON_WAIT", comment: "Wait"),
                locale: .current,
                arguments: arguments)
            }
        }
    }
}
