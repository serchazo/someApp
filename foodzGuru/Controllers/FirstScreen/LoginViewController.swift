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
    private let selectFoodSegue = "selectFoodFirst"
    private let firstTimeSegueID = "firstTime"
    private var user:User!
    private var firstTimeFlag = false
    
    private var userDevicesHandle:UInt!
    
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
                
                // I. Verify if the user has filled his/her data
                SomeApp.dbUserData.child(user!.uid).observeSingleEvent(of: .value, with: {snapshot in
                    // I. AUser data is already created
                    if snapshot.exists(){
                        
                        // [START] temp code, upload device token
                        InstanceID.instanceID().instanceID { (result, error) in
                            if let error = error {
                                print(FoodzLayout.FoodzStrings.log.localized(arguments: error.localizedDescription))
                            } else if let result = result {
                                SomeApp.updateDeviceToken(userId: user!.uid, deviceToken: result.token)
                            }
                        }
                        // [END] temp code, upload device token
                        
                        // Verify if APN Token was changed
                        if SomeApp.tokenChangedFlag{
                            SomeApp.updateDeviceToken(userId: user!.uid, deviceToken: SomeApp.deviceToken)
                        }
                        
                        // II. Verify if the user is following some foodz
                        SomeApp.dbUserFollowingRankings.child(user!.uid).observeSingleEvent(of: .value, with: {foodSnap in
                            // II.A. If the user is already following some foodz go to the app
                            if foodSnap.exists(){
                                self.performSegue(withIdentifier: self.loginOKSegueID, sender: nil)
                            }
                            // II.B. If not, then first select foodz
                            else{
                                self.performSegue(withIdentifier: self.selectFoodSegue, sender: nil)
                            }
                        })
                        
                    }
                    // I.B. If not, go look for the data first
                    else{
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
        signUpButton.setTitle(MyStrings.createAccount.localized(), for: .normal)
        
        forgotPasswordButton.setTitleColor(SomeApp.themeColor, for: .normal)
        forgotPasswordButton.setTitle(MyStrings.forgotPassword.localized(), for: .normal)
        
        // Configure the Login with Facebook button
        facebookButton.layer.cornerRadius = cornerRadious
        facebookButton.layer.masksToBounds = true
        facebookButton.setTitle(MyStrings.facebookLogin.localized(), for: .normal)
        facebookButton.addTarget(self, action: #selector(didTapFacebookButton), for: .touchUpInside)
        facebookButton.setTitleColor(.white, for: .normal)
        facebookButton.backgroundColor = #colorLiteral(red: 0.2585989833, green: 0.4022747874, blue: 0.6941830516, alpha: 1)

        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Auth.auth().removeStateDidChangeListener(handle!)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.userDevicesHandle != nil{
            SomeApp.dbUserDevices.child(user!.uid).removeObserver(withHandle: self.userDevicesHandle)
        }
    }
    
    // MARK: Login
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        guard let email = textFieldLoginEmail.text,
            let password = textFieldLoginPassword.text,
            email.count > 0,
            password.count > 0 else {
                FoodzLayout.showWarning(vc: self, title: MyStrings.emptyInfo.localized(), text: MyStrings.emptyInfoDetail.localized())
                return
        }
        
        // Perform the authorization
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            if let error = error, user == nil {
                let alert = UIAlertController(
                    title: MyStrings.loginFailed.localized(),
                    message: error.localizedDescription,
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(
                    title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                    style: .default))
                self.present(alert,animated: true, completion: nil)
            }
        }
    }
    
    // MARK: forgot password
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: MyStrings.psswdResetTitle.localized(),
            message: MyStrings.psswdResetMsg.localized(),
            preferredStyle: .alert)
        // [START] Password reset action
        let passwordResetAction = UIAlertAction(title: MyStrings.psswdResetButton.localized(),
                                                style: .default)
        { _ in
            //Get e-mail from the alert
            let emailField = alert.textFields![0]
            
            // Call firebase function
            Auth.auth().sendPasswordReset(withEmail: emailField.text!) { error in
                // There is an error
                if let error = error{
                    let alert = UIAlertController(title: FoodzLayout.FoodzStrings.msgError.localized(),
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                                                  style: .default))
                    self.present(alert,animated: true, completion: nil)
                }
            }
        }// [END] Password reset action
        
        let cancelAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonCancel.localized(), style: .cancel)
        
        alert.addTextField { textEmail in
            textEmail.keyboardType = .emailAddress
            textEmail.placeholder = MyStrings.enterEmail.localized()
        }
        
        alert.addAction(passwordResetAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    // MARK: Sign up
    @IBAction func signUpPressed(_ sender: UIButton) {
        let alert = UIAlertController(
            title: MyStrings.createAccount.localized(),
            message: MyStrings.createAccountGuide.localized(),
            preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: MyStrings.createButton.localized(),
                                       style: .default) { _ in
            //Get e-mail and password from the alert
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
            let confirmPasswordField = alert.textFields![2]
            
            // Passwords don't match
            if passwordField.text != confirmPasswordField.text {
                let notMatchAlert = UIAlertController(
                    title: MyStrings.psswdNotMatch.localized(),
                    message: MyStrings.psswdNotMatchMsg.localized(),
                    preferredStyle: .alert)
                let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized(), style: .default, handler: nil)
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
                        let alert = UIAlertController(
                            title: MyStrings.createFailed.localized(),
                            message: error.localizedDescription,
                            preferredStyle: .alert)
                        alert.addAction(UIAlertAction(
                            title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                            style: .default))
                        self.present(alert,animated: true, completion: nil)
                        // Show the buttons
                        self.hideAndSeek(hide: false)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonCancel.localized(), style: .cancel)
        
        alert.addTextField { textEmail in
            textEmail.keyboardType = .emailAddress
            textEmail.placeholder = MyStrings.enterEmail.localized()}
        
        alert.addTextField { textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.placeholder = MyStrings.psswdCreate.localized()
        }
        
        alert.addTextField { textConfirmPassword in
            textConfirmPassword.isSecureTextEntry = true
            textConfirmPassword.placeholder = MyStrings.psswdConfirm.localized()
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
                title: MyStrings.facebookCancelledTitle.localized(),
                message: MyStrings.facebookCancelledMsg.localized(),
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized(), style: .default)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        case .failed(let error):
            alertController = UIAlertController(
                title: MyStrings.loginFailed.localized(),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized(), style: .default)
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
                print(FoodzLayout.FoodzStrings.log.localized(arguments: error.localizedDescription))
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
        let eulaTextToSee:String = FoodzLayout.FoodzStrings.eulaTermsOfService.localized()
        let eulaAttributedText = NSMutableAttributedString(string: eulaTextToSee)
        let eulaLink = FoodzLayout.FoodzStrings.eulaTermsOfServiceURL.localized()
        eulaAttributedText.addAttribute(NSAttributedString.Key.link, value: eulaLink, range: NSMakeRange(0, eulaTextToSee.count))
        
        //Privacy Policy
        let privacyTextToSee:String = FoodzLayout.FoodzStrings.eulaPrivacyPolicy.localized()
        let privacyAttributedText = NSMutableAttributedString(string: privacyTextToSee)
        let privacyLink = FoodzLayout.FoodzStrings.eulaPrivacyPolicyURL.localized()
        privacyAttributedText.addAttribute(NSAttributedString.Key.link, value: privacyLink, range: NSMakeRange(0, privacyTextToSee.count))
        
        result.append(NSMutableAttributedString(
            string: MyStrings.eulaText.localized(),
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label]))
        result.append(eulaAttributedText)
        result.append(NSMutableAttributedString(
            string: MyStrings.eulaTextAppend.localized(),
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label]))
        result.append(privacyAttributedText)
        result.append(NSMutableAttributedString(
            string: ".",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label]))
        
        return result
    }
    
    // Coming back from segue when logoff
    @IBAction func unwindToLoginScreen(segue: UIStoryboardSegue){}
}

// MARK: UITextView stuff
extension LoginViewController: UITextViewDelegate{
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
}


// MARK: Localized Strings
extension LoginViewController{
    private enum MyStrings {
        case enterEmail
        case createAccount
        case createAccountGuide
        case createButton
        case createFailed
        case forgotPassword
        case facebookLogin
        case facebookCancelledTitle
        case facebookCancelledMsg
        case emptyInfo
        case emptyInfoDetail
        case loginFailed
        case psswdResetTitle
        case psswdResetMsg
        case psswdResetButton
        case psswdCreate
        case psswdConfirm
        case psswdNotMatch
        case psswdNotMatchMsg
        case eulaText
        case eulaTextAppend
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .enterEmail:
                return String(
                format: NSLocalizedString("LOGIN_EMAIL", comment: "Enter"),
                locale: .current,
                arguments: arguments)
            case .createAccount:
                return String(
                format: NSLocalizedString("LOGIN_CREATE_ACCOUNT", comment: "Create account"),
                locale: .current,
                arguments: arguments)
            case .createAccountGuide:
                return String(
                format: NSLocalizedString("LOGIN_CREATE_GUIDE", comment: "Create"),
                locale: .current,
                arguments: arguments)
            case .createButton:
                return String(
                format: NSLocalizedString("LOGIN_CREATE_BUTTON", comment: "Create"),
                locale: .current,
                arguments: arguments)
            case .createFailed:
                return String(
                format: NSLocalizedString("LOGIN_CREATE_FAILED", comment: "Create failed"),
                locale: .current,
                arguments: arguments)
            case .forgotPassword:
                return String(
                format: NSLocalizedString("LOGIN_FORGOT_PSSWD", comment: "Forgot password"),
                locale: .current,
                arguments: arguments)
            case .facebookLogin:
                return String(
                format: NSLocalizedString("LOGIN_FACEBOOK", comment: "Facebook login"),
                locale: .current,
                arguments: arguments)
            case .facebookCancelledTitle:
                return String(
                format: NSLocalizedString("LOGIN_FACEBOOK_CANCELLED_MSG", comment: "Cancel"),
                locale: .current,
                arguments: arguments)
            case .facebookCancelledMsg:
                return String(
                format: NSLocalizedString("LOGIN_FACEBOOK_CANCELLED_TITLE", comment: "Cancel"),
                locale: .current,
                arguments: arguments)
            case .emptyInfo:
                return String(
                format: NSLocalizedString("LOGIN_EMPTY", comment: "Empty"),
                locale: .current,
                arguments: arguments)
            case .emptyInfoDetail:
                return String(
                format: NSLocalizedString("LOGIN_EMPTY_DETAIL", comment: "Empty"),
                locale: .current,
                arguments: arguments)
            case .loginFailed:
                return String(
                format: NSLocalizedString("LOGIN_FAILED", comment: "Failed"),
                locale: .current,
                arguments: arguments)
            case .psswdResetTitle:
                return String(
                format: NSLocalizedString("LOGIN_PSSWD_RESET_TITLE", comment: "Password Reset"),
                locale: .current,
                arguments: arguments)
            case .psswdResetMsg:
                return String(
                format: NSLocalizedString("LOGIN_PSSWD_RESET_MSG", comment: "Enter your e-mail"),
                locale: .current,
                arguments: arguments)
            case .psswdResetButton:
                return String(
                format: NSLocalizedString("LOGIN_PSSWD_RESET_BUTTON", comment: "Reset"),
                locale: .current,
                arguments: arguments)
            case .psswdCreate:
                return String(
                format: NSLocalizedString("LOGIN_PSSWD_CREATE", comment: "To create"),
                locale: .current,
                arguments: arguments)
            case .psswdConfirm:
                return String(
                format: NSLocalizedString("LOGIN_PSSWD_CONFIRM", comment: "To confirm"),
                locale: .current,
                arguments: arguments)
            case .psswdNotMatch:
                return String(
                format: NSLocalizedString("LOGIN_PSSWD_NOTMATCH_TITLE", comment: "Not equal"),
                locale: .current,
                arguments: arguments)
            case .psswdNotMatchMsg:
                return String(
                format: NSLocalizedString("LOGIN_PSSWD_NOTMATCH_MSG", comment: "Not equal"),
                locale: .current,
                arguments: arguments)
            case .eulaText:
                return String(
                format: NSLocalizedString("LOGIN_EULA_TEXT", comment: "using"),
                locale: .current,
                arguments: arguments)
            case .eulaTextAppend:
                return String(
                format: NSLocalizedString("LOGIN_EULA_TEXT_APPEND", comment: "and"),
                locale: .current,
                arguments: arguments)
            }
        }
        
        
    }
}
