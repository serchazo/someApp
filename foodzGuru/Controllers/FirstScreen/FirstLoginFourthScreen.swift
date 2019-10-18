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
    var bio:String!
    var photoURL:URL!
    
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.font = SomeApp.titleFont
            titleLabel.textColor = SomeApp.themeColor
            titleLabel.text = "One last step"
        }
    }
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        // Get user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
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
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    

}


// MARK: Go button
extension FirstLoginFourthScreen{
    // Configure
    func configureButtons(){
        FoodzLayout.configureButton(button: goButton)
        goButton.setTitle("Go", for: .normal)
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
                    print("There was an error updating the user profile: \(error.localizedDescription)")
                }
            })
        }
        // Create the user details object
        var urlString = ""
        if photoURL != nil {
            urlString = photoURL.absoluteString
        }
        
        SomeApp.createUserFirstLogin(
            userId: user.uid,
            username: userName!,
            bio: bio!,
            defaultCity: tmpCityString,
            photoURL: urlString)
        
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
}
