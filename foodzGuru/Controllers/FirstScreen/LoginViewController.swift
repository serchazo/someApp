//
//  LoginViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 05.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
// For Facebook login :
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin

class LoginViewController: UIViewController {
    private let loginOKSegueID = "loginOK"
    private let firstTimeSegueID = "firstTime"
    private var user:User!
    private var firstTimeFlag = false
    
    // Facebook login permissions
    private let readPermissions: [Permission] =  [ .publicProfile, .email ]
    
    @IBOutlet weak var textFieldLoginEmail: UITextField!{
        didSet{
            textFieldLoginEmail.keyboardType = .emailAddress
        }
    }
    @IBOutlet weak var textFieldLoginPassword: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var orLabel: UILabel!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!{
        didSet{
            spinner.isHidden = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Authentication observer
        Auth.auth().addStateDidChangeListener(){ auth,user in
            // test the value of user
            if user != nil {
                //
                self.hideAndSeek(hide: true)
                
                self.user = user
                // Some cleanup before the Segue
                self.textFieldLoginEmail.text = nil
                self.textFieldLoginPassword.text = nil
                // For testing the first screen
                //self.firstTimeFlag = true
                
                SomeApp.dbUserData.child(user!.uid).observeSingleEvent(of: .value, with: {snapshot in
                    // User data is already created
                    if snapshot.exists(){
                        self.performSegue(withIdentifier: self.loginOKSegueID, sender: nil)
                    }else{
                        self.performSegue(withIdentifier: self.firstTimeSegueID, sender: nil)
                    }
                })
            }else{
                //Set normal login page (Attention: this is useful in case we delete the profile)
                self.hideAndSeek(hide: false)
            }
        }
        
        // Configure the buttons
        FoodzLayout.configureButton(button: signUpButton)
        signUpButton.titleLabel?.text = "Create account"
        
        loginButton.layer.cornerRadius = 15
        loginButton.backgroundColor = SomeApp.themeColor
        //loginButton.layer.borderColor = SomeApp.themeColor.cgColor
        loginButton.layer.borderWidth = 1.0
        loginButton.layer.masksToBounds = true
        
        textFieldLoginEmail.layer.cornerRadius = 15
        textFieldLoginEmail.layer.masksToBounds = true
        
        textFieldLoginPassword.layer.cornerRadius = 15
        textFieldLoginPassword.layer.masksToBounds = true 
        
        // Configure the Login with Facebook button
        facebookButton.layer.cornerRadius = 15
        facebookButton.layer.masksToBounds = true
        facebookButton.setTitle("Facebook Login", for: .normal)
        facebookButton.addTarget(self, action: #selector(didTapFacebookButton), for: .touchUpInside)
        facebookButton.setTitleColor(.white, for: .normal)
        facebookButton.backgroundColor = #colorLiteral(red: 0.2585989833, green: 0.4022747874, blue: 0.6941830516, alpha: 1)

        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Auth.auth().removeStateDidChangeListener(handle!)
        
    }
    
    // MARK: Login
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        guard let email = textFieldLoginEmail.text,
            let password = textFieldLoginPassword.text,
            email.count > 0,
            password.count > 0 else {
                FoodzLayout.showWarning(vc: self, title: "Empty information", text: "Your e-mail or password can't be empty.")
                /*
                let alert = UIAlertController(title: "Empty information",
                                              message: "Your e-mail or password can't be empty.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert,animated: true, completion: nil)
                */
                return
        }
        
        // Perform the authorization
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            if let error = error, user == nil {
                let alert = UIAlertController(title: "Sign In Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert,animated: true, completion: nil)
            }
        }
    }
    
    // MARK: forgot password
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Password reset",
        message: "Enter your e-mail and you'll receive an e-mail with the instructions.",
        preferredStyle: .alert)
        
        let passwordResetAction = UIAlertAction(title: "Reset", style: .default){ _ in
            //Get e-mail from the alert
            let emailField = alert.textFields![0]
            
            // Call firebase function
            Auth.auth().sendPasswordReset(withEmail: emailField.text!) { error in
                // There is an error
                if let error = error{
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert,animated: true, completion: nil)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { textEmail in
            textEmail.keyboardType = .emailAddress
            textEmail.placeholder = "Enter your email"
        }
        
        alert.addAction(passwordResetAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    // MARK: Sign up
    @IBAction func signUpPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Register",
                                      message: "Enter your e-mail and create a new password.",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Create", style: .default) { _ in
            //Get e-mail and password from the alert
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
            
            // Call create user
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!){ user, error in
                // If there is an error
                if let error = error, user == nil {
                    let alert = UIAlertController(title: "Sign up Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert,animated: true, completion: nil)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { textEmail in
            textEmail.keyboardType = .emailAddress
            textEmail.placeholder = "Enter your email"}
        
        alert.addTextField { textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.placeholder = "Enter your password"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    

    // Don't segue from the button, only when the authorization is correct
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    // MARK: Login with FB stuff
    @objc func didTapFacebookButton() {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: readPermissions, viewController: self, completion: loginManagerDidComplete)
    }
    
    // func when receiving the answer from FB Login Manger
    private func loginManagerDidComplete(_ result: LoginResult) {
        let alertController: UIAlertController
        switch result {
        case .cancelled:
            
            alertController = UIAlertController(
                title: "Login Cancelled",
                message: "User cancelled login.",
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        case .failed(let error):
            alertController = UIAlertController(
                title: "Login Fail",
                message: "Login failed with error \(error)",
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        case .success:
            // Login succesful
            loginSuccesful()
        }
    }
    
    // Facebook login successful
    private func loginSuccesful(){
        
        // login to Firebase
        let accessToken = AccessToken.current!.tokenString
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("Some error: \(error.localizedDescription)")
                return
            }
            // User is signed in, verify if it's his first login
            if authResult?.additionalUserInfo != nil {
                self.firstTimeFlag = (authResult?.additionalUserInfo!.isNewUser)!
            }
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LoginViewController: UITextFieldDelegate {
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textFieldLoginEmail {
            textFieldLoginPassword.becomeFirstResponder()
        }
        if textField == textFieldLoginPassword {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: helper funcs
extension LoginViewController{
    
    private func hideAndSeek(hide: Bool){
        self.spinner.isHidden = !hide
        if hide{
            self.spinner.startAnimating()
        }else{
            self.spinner.stopAnimating()
        }
        self.textFieldLoginEmail.isHidden = hide
        self.textFieldLoginPassword.isHidden = hide
        self.facebookButton.isHidden = hide
        self.loginButton.isHidden = hide
        self.signUpButton.isHidden = hide
        self.orLabel.isHidden = hide
        self.forgotPasswordButton.isHidden = hide
        
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Coming back from segue when logoff
    @IBAction func unwindToLoginScreen(segue: UIStoryboardSegue){}
}
