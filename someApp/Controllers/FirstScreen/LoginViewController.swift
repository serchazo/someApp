//
//  LoginViewController.swift
//  someApp
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
    
    @IBOutlet weak var textFieldLoginEmail: UITextField!
    @IBOutlet weak var textFieldLoginPassword: UITextField!
    @IBOutlet weak var facebookLoginButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Authentication observer
        Auth.auth().addStateDidChangeListener(){ auth,user in
            // test the value of user
            if user != nil {
                user?.reload(completion: {(error) in
                    guard error == nil else{
                        print("account disabled")
                        return
                    }
                    //
                    self.user = user
                    // Some cleanup before the Segue
                    self.textFieldLoginEmail.text = nil
                    self.textFieldLoginPassword.text = nil
                    
                    if !self.firstTimeFlag{
                        print("authorized")
                        self.performSegue(withIdentifier: self.loginOKSegueID, sender: nil)
                    }else{
                        self.performSegue(withIdentifier: self.firstTimeSegueID, sender: nil)
                    }
                })
                
                
            }
        }
        
        // Configure the Login with Facebook button
        facebookLoginButton.setTitle("Facebook Login", for: .normal)
        facebookLoginButton.addTarget(self, action: #selector(didTapFacebookButton), for: .touchUpInside)
        facebookLoginButton.setTitleColor(.white, for: .normal)
        facebookLoginButton.backgroundColor = #colorLiteral(red: 0.2585989833, green: 0.4022747874, blue: 0.6941830516, alpha: 1)

        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        guard let email = textFieldLoginEmail.text,
            let password = textFieldLoginPassword.text,
            email.count > 0,
            password.count > 0 else {
                let alert = UIAlertController(title: "Empty information",
                                              message: "Your e-mail or password can't be empty.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert,animated: true, completion: nil)
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
    
    // MARK: Sign up
    @IBAction func signUpPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Register",
                                      message: "Register",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            //Get e-mail and password from the alert
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
            
            // Call create user
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!){ user, error in

                Auth.auth().signIn(withEmail: self.textFieldLoginEmail.text!, password: self.textFieldLoginPassword.text!)
                self.firstTimeFlag = true
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { textEmail in textEmail.placeholder = "Enter your email"}
        
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
        let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
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
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
