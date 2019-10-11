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
            titleLabel.font = SomeApp.titleFont
            titleLabel.textColor = SomeApp.themeColor
            titleLabel.text = "Configure your profile (1/4)"
        }
    }
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var userNameTakenLabel: UILabel!
    @IBOutlet weak var verifyNameSpinner: UIActivityIndicatorView!
    @IBOutlet weak var goButton: UIButton!
    
    // MARK: Timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameField.delegate = self
        userNameField.keyboardType = .default
        
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
            let alert = UIAlertController(title: "Invalid name", message: "Your user name should be at least 4 characters long.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert,animated: true)
            return
        }
        
        verifyNameSpinner.isHidden = false
        verifyNameSpinner.startAnimating()
        let pattern = "[^A-Za-z0-9]+"
        self.userName = nickname.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
        SomeApp.dbUserData.queryOrdered(byChild: "nickname").queryEqual(toValue: userName).observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.exists(){
                // The username exists
                self.userNameField.text = self.userName
                self.userNameTakenLabel.textColor = .systemRed
                self.userNameTakenLabel.text = "This username is already taken."
                self.userNameTakenLabel.isHidden = false
                
            }else  {
                // The username doesn't exist
                self.userNameField.text = self.userName
                self.userNameOKFlag = true
                self.userNameTakenLabel.textColor = .darkText
                self.userNameTakenLabel.text = "Good! This username is available."
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
            goButton.setTitle("Go!", for: .normal)
            goButton.removeTarget(self, action: #selector(verifyUserName), for: .touchUpInside)
            goButton.addTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
        }else{
            goButton.setTitle("Verify username", for: .normal)
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
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        userNameField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userNameField.resignFirstResponder()
        return true
    }
}
