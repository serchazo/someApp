//
//  FirstLoginFourthScreen.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 11.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class FirstLoginFourthScreen: UIViewController {
    
    private let segueBioOK = "segueBioOK"
    private let defaults = UserDefaults.standard
    
    // Instance variables
    private var user: User!
    
    // Get from segue-r
    var userName:String!
    var currentCity: City!
    var currentCountryName: String!
    var currentStateName: String!
    var bio:String!
    var photoURL:URL!
    
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.font = SomeApp.titleFont
            titleLabel.textColor = SomeApp.themeColor
            titleLabel.text = MyStrings.title.localized()
        }
    }
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        
        bioTextField.delegate = self
        bioTextField.keyboardType = .default
        
        // Get user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
        }
        
        self.hideKeyboardWhenTappedAround()
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
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    

}

// MARK: Go button
extension FirstLoginFourthScreen{
    // Configure
    func configureButtons(){
        FoodzLayout.configureButton(button: goButton)
        goButton.setTitle(MyStrings.buttonGo.localized(), for: .normal)
        goButton.addTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
        
    }
    // Setting up the user
    @objc func goButtonPressed(){
        // If the user is not signed in with facebook, we update display name and photo url on firebase
        
        if bioTextField.text == nil || bioTextField.text == ""{
            bio = ""
        }else{
            bio = bioTextField.text
        }
        let tmpCityString = currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/" + currentCity.name
        
        // Update the user profile
        if user.providerID != "facebook.com" {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = userName
            changeRequest.photoURL = photoURL
            changeRequest.commitChanges(completion: {error in
                if let error = error{
                    print(FoodzLayout.FoodzStrings.log.localized(arguments: error.localizedDescription))
                }
            })
        }
        // Create the user details object
        var urlString = ""
        if photoURL != nil {
            urlString = photoURL.absoluteString
        }
        
        var deviceToken = ""
        if SomeApp.deviceToken != nil{
            deviceToken = SomeApp.deviceToken
        }
        
        // Create the user details
        SomeApp.createUserFirstLogin(
            userId: user.uid,
            username: (userName!).lowercased(),
            bio: bio!,
            defaultCity: tmpCityString,
            photoURL: urlString,
            deviceToken: deviceToken)
        
        // Ad the first city
        SomeApp.addUserCity(userId: user.uid, city: currentCity, countryName: currentCountryName, stateName: currentStateName)
        
        // Save the default City
        defaults.set(tmpCityString, forKey: SomeApp.currentCityDefault)
        
        // And Go! to the app
        self.performSegue(withIdentifier: self.segueBioOK, sender: nil)
    }
}

// MARK: Text field extension
extension FirstLoginFourthScreen: UITextFieldDelegate{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        bioTextField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        bioTextField.resignFirstResponder()
        return true
    }
    
    // Max chars
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        let changedText = currentText.replacingCharacters(in: stringRange, with: string)
        return changedText.count <= 150
    }
}

// MARK: Localized Strings
extension FirstLoginFourthScreen{
    private enum MyStrings {
        case title
        case buttonGo
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .title:
                return String(
                format: NSLocalizedString("FIRSTLOG4_TITLE", comment: "Configure"),
                locale: .current,
                arguments: arguments)
            case .buttonGo:
            return String(
                format: NSLocalizedString("FIRSTLOG4_BUTTON_GO", comment: "Go"),
                locale: .current,
                arguments: arguments)
                
            }
        }
    }
}
