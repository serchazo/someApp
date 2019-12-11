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
    private let cornerRadious:CGFloat = 9
    private let loginOKSegueID = "loginOK"
    private let firstTimeSegueID = "firstTime"
    private var user:User!
    private var firstTimeFlag = false
    
    // Facebook login permissions
    private let readPermissions: [Permission] =  [ .publicProfile, .email ]
    
    @IBOutlet weak var textFieldLoginEmail: UITextField!{
        didSet{
            textFieldLoginEmail.keyboardType = .emailAddress
            textFieldLoginEmail.delegate = self
        }
    }
    @IBOutlet weak var textFieldLoginPassword: UITextField!{
        didSet{
            textFieldLoginPassword.delegate = self
        }
    }
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var orLabel: UILabel!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!{
        didSet{
            if #available(iOS 13, *){
                spinner.style = .large
            }
            spinner.isHidden = true
        }
    }
    
    @IBOutlet weak var warningTextView: UITextView!
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The warning UITextView
        let testText = prepareText()
        warningTextView.attributedText = testText
        warningTextView.delegate = self
        warningTextView.textAlignment = .center
        warningTextView.linkTextAttributes = [ .foregroundColor: SomeApp.themeColor ]
        
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
                //self.performSegue(withIdentifier: self.firstTimeSegueID, sender: nil)
                
                SomeApp.dbUserData.child(user!.uid).observeSingleEvent(of: .value, with: {snapshot in
                    // User data is already created
                    if snapshot.exists(){
                        // [START] temp code, upload device token
                        SomeApp.dbUserDevices.child(user!.uid).observeSingleEvent(of: .value, with: {snap in
                            if !snap.exists(){
                                InstanceID.instanceID().instanceID { (result, error) in
                                    if let error = error {
                                        print("Error fetching remote instance ID: \(error)")
                                    } else if let result = result {
                                        SomeApp.updateDeviceToken(userId: user!.uid, deviceToken: result.token)
                                        //print("Remote instance ID token: \(result.token)")
                                    }
                                }
                            }
                        })
                        // [END] temp code, upload device token
                        
                        // Verify if APN Token was changed
                        if SomeApp.tokenChangedFlag{
                            SomeApp.updateDeviceToken(userId: user!.uid, deviceToken: SomeApp.deviceToken)
                        }
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
        textFieldLoginEmail.layer.cornerRadius = cornerRadious
        textFieldLoginEmail.layer.masksToBounds = true
        
        textFieldLoginPassword.layer.cornerRadius = cornerRadious
        textFieldLoginPassword.layer.masksToBounds = true
        
        FoodzLayout.configureButton(button: loginButton)
        
        FoodzLayout.configureButton(button: signUpButton)
        signUpButton.setTitle(MyStrings.createAccount.localized, for: .normal)
        
        forgotPasswordButton.setTitleColor(SomeApp.themeColor, for: .normal)
        forgotPasswordButton.setTitle(MyStrings.forgotPassword.localized, for: .normal)
        
        // Configure the Login with Facebook button
        facebookButton.layer.cornerRadius = cornerRadious
        facebookButton.layer.masksToBounds = true
        facebookButton.setTitle(MyStrings.facebookLogin.localized, for: .normal)
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
                FoodzLayout.showWarning(vc: self, title: MyStrings.emptyInfo.localized, text: MyStrings.emptyInfoDetail.localized)
                return
        }
        
        // Perform the authorization
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            if let error = error, user == nil {
                let alert = UIAlertController(
                    title: MyStrings.loginFailed.localized,
                    message: error.localizedDescription,
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(
                    title: FoodzLayout.FoodzStrings.buttonOK.localized,
                    style: .default))
                self.present(alert,animated: true, completion: nil)
            }
        }
    }
    
    // MARK: forgot password
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: MyStrings.psswdResetTitle.localized,
            message: MyStrings.psswdResetMsg.localized,
            preferredStyle: .alert)
        // [START] Password reset action
        let passwordResetAction = UIAlertAction(title: MyStrings.psswdResetButton.localized,
                                                style: .default)
        { _ in
            //Get e-mail from the alert
            let emailField = alert.textFields![0]
            
            // Call firebase function
            Auth.auth().sendPasswordReset(withEmail: emailField.text!) { error in
                // There is an error
                if let error = error{
                    let alert = UIAlertController(title: FoodzLayout.FoodzStrings.msgError.localized,
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized,
                                                  style: .default))
                    self.present(alert,animated: true, completion: nil)
                }
            }
        }// [END] Password reset action
        
        let cancelAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonCancel.localized, style: .cancel)
        
        alert.addTextField { textEmail in
            textEmail.keyboardType = .emailAddress
            textEmail.placeholder = MyStrings.enterEmail.localized
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
            let confirmPasswordField = alert.textFields![2]
            
            // Passwords don't match
            if passwordField.text != confirmPasswordField.text {
                let notMatchAlert = UIAlertController(title: "Passwords don't match", message: "Your New and Confirm password do not match.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized, style: .default, handler: nil)
                notMatchAlert.addAction(okAction)
                self.present(notMatchAlert, animated: true, completion: nil)
            }
            // Call Firebase for an upgrade
            else{
                self.hideAndSeek(hide: true)
                
                // Call create user
                Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!){ user, error in
                    // If there is an error
                    if let error = error, user == nil {
                        // Pop-up
                        let alert = UIAlertController(title: "Sign up Failed", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(
                            title: FoodzLayout.FoodzStrings.buttonOK.localized,
                            style: .default))
                        self.present(alert,animated: true, completion: nil)
                        // Show the buttons
                        self.hideAndSeek(hide: false)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonCancel.localized, style: .cancel)
        
        alert.addTextField { textEmail in
            textEmail.keyboardType = .emailAddress
            textEmail.placeholder = MyStrings.enterEmail.localized}
        
        alert.addTextField { textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.placeholder = MyStrings.psswdCreate.localized
        }
        
        alert.addTextField { textConfirmPassword in
            textConfirmPassword.isSecureTextEntry = true
            textConfirmPassword.placeholder = MyStrings.psswdConfirm.localized
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
            let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized, style: .default)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        case .failed(let error):
            alertController = UIAlertController(
                title: "Login Failed",
                message: "Login failed with error \(error)",
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized, style: .default)
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    
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
        self.warningTextView.isHidden = hide
        
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func prepareText() -> NSMutableAttributedString{
        let result = NSMutableAttributedString()
        
        //Terms of service
        let eulaTextToSee:String = "Terms of Service"
        let eulaAttributedText = NSMutableAttributedString(string: eulaTextToSee)
        let eulaLink = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        eulaAttributedText.addAttribute(NSAttributedString.Key.link, value: eulaLink, range: NSMakeRange(0, eulaTextToSee.count))
        
        //Privacy Policy
        let privacyTextToSee:String = "Privacy Policy"
        let privacyAttributedText = NSMutableAttributedString(string: privacyTextToSee)
        let privacyLink = "https://foodzdotguru.wordpress.com/privacy-policy/"
        privacyAttributedText.addAttribute(NSAttributedString.Key.link, value: privacyLink, range: NSMakeRange(0, privacyTextToSee.count))
        
        result.append(NSMutableAttributedString(string: "By using our app you agree to our "))
        result.append(eulaAttributedText)
        result.append(NSMutableAttributedString(string: " and our "))
        result.append(privacyAttributedText)
        result.append(NSMutableAttributedString(string: "."))
        
        return result
    }
    
    // Coming back from segue when logoff
    @IBAction func unwindToLoginScreen(segue: UIStoryboardSegue){}
}

// MARK: warning UITextView stuff
extension LoginViewController: UITextViewDelegate{
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
}


//
extension LoginViewController{
    private enum MyStrings {
        case enterEmail
        case createAccount
        case forgotPassword
        case facebookLogin
        case emptyInfo
        case emptyInfoDetail
        case loginFailed
        case psswdResetTitle
        case psswdResetMsg
        case psswdResetButton
        case psswdCreate
        case psswdConfirm
        
        var localized: String{
            switch self{
            case .enterEmail:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_EMAIL", comment: "Enter"))
            case .createAccount:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_CREATE_ACCOUNT", comment: "Create account"))
            case .forgotPassword:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_FORGOT_PSSWD", comment: "Forgot password"))
            case .facebookLogin:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_FACEBOOK", comment: "Facebook login"))
            case .emptyInfo:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_EMPTY", comment: "Empty"))
            case .emptyInfoDetail:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_EMPTY_DETAIL", comment: "Empty"))
            case .loginFailed:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_FAILED", comment: "Failed"))
            case .psswdResetTitle:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_PSSWD_RESET_TITLE", comment: "Password Reset"))
            case .psswdResetMsg:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_PSSWD_RESET_MSG", comment: "Enter your e-mail"))
            case .psswdResetButton:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_PSSWD_RESET_BUTTON", comment: "Reset"))
            case .psswdCreate:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_PSSWD_CREATE", comment: "To create"))
            case .psswdConfirm:
                return String.localizedStringWithFormat(NSLocalizedString("LOGIN_PSSWD_CONFIRM", comment: "To confirm"))
            }
        }
        
        
    }
}
