//
//  FirstLoginViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class FirstLoginViewController: UIViewController {
    
    
    private static let continueToAppSegueID = "profileOK"
    private static let cityChooserSegueID = "chooseCity"
    private var user:User!
    private var userName:String!
    private var city:City!
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    
    // MARK: outlets
    
    
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.font = SomeApp.titleFont
            titleLabel.textColor = SomeApp.themeColor
            titleLabel.text = "Configure your profile"
        }
    }
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var uploadImageButton: UIButton!
    // Username outlets
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var userNameTakenLabel: UILabel!
    // Current city outlets
    @IBOutlet weak var selectCityLabel: UITextField!
    @IBOutlet weak var selectCityButton: UIButton!
    
    @IBOutlet weak var verifyUserNameButton: UIButton!
    // Bio stuff
    @IBOutlet weak var bioLabel: UILabel!
    
    @IBOutlet weak var bioField: UITextField!
    @IBOutlet weak var goButton: UIButton!{
        didSet{
            goButton.isEnabled = false
            goButton.backgroundColor = .gray
        }
    }
    @IBOutlet weak var spinner: UIActivityIndicatorView!{
        didSet{
            spinner.hidesWhenStopped = true
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get username
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            if self.user.photoURL != nil && self.user.providerData[0].providerID == "facebook.com"{
                // If the provider is facebook, we get the large picture
                let modifiedURL = self.user.photoURL!.absoluteString + "?type=large"
                self.photoURL = URL(string: modifiedURL)
                self.uploadImageButton.isEnabled = false
                self.uploadImageButton.isHidden = true
                
                
            }else if self.user.photoURL != nil {
                // if it's the firebase provider, we get the normal profile
                self.photoURL = user.photoURL
            }else{
                // TODO: If the photoURL is empty, assign the default profile pic
            }
            
            
            print("I'm probably complicating myself")
            print(self.user.providerData[0].providerID)
            print(self.user.displayName)
            print(self.user.photoURL?.absoluteString)
            print(self.user.email)
        }
        
        // Do any additional setup after loading the view.
        userNameTakenLabel.isHidden = true
        verifyUserNameButton.addTarget(self, action: #selector(verifyUserName), for: .touchUpInside)
        userNameField.addTarget(self, action: #selector(editingText), for: .editingDidBegin)
        goButton.addTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
        
        hideKeyboardWhenTappedAround()
    }
    
    // MARK: Get profile picture
    private func fetchImage(){
        if let url = photoURL{
            spinner.startAnimating()
            let urlContents = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                if let imageData = urlContents, url == self.photoURL {
                    self.profilePic.image = UIImage(data: imageData)
                    self.profilePic.layer.cornerRadius = 0.5 * self.profilePic.bounds.size.width
                    self.profilePic.layer.borderColor = SomeApp.themeColorOpaque.cgColor
                    self.profilePic.layer.borderWidth = 2.0
                    self.profilePic.layoutMargins = UIEdgeInsets(top: 3.0, left: 3.0, bottom: 3.0, right: 3.0)
                        //self.profilePic.frame.insetBy(dx: 2.0, dy: 2.0)
                    self.profilePic.clipsToBounds = true
                    self.spinner.stopAnimating()
                    
                }
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
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == FirstLoginViewController.cityChooserSegueID{
            return true
        }else{
            return false
        }
    }
    
    // MARK: objc funcs
    @objc func verifyUserName(){
        
        guard let nickname = userNameField.text,
            nickname.count >= 4 else {
            let alert = UIAlertController(title: "Invalid name", message: "Your user name should be at least 4 characters long.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert,animated: true)
            return
        }
        
        let pattern = "[^A-Za-z0-9]+"
        self.userName = nickname.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
        SomeApp.dbUserData.queryOrdered(byChild: "nickname").queryEqual(toValue: userName).observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.exists(){
                // The username exists
                self.userNameField.text = self.userName
                self.userNameTakenLabel.isHidden = false
            }else  {
                // The username doesn't exist
                self.userNameField.text = self.userName
                self.goButton.isEnabled = true
                self.goButton.backgroundColor = SomeApp.themeColor
            }
        })
    }
    // Setting up the user
    @objc func goButtonPressed(){
        // Then create
        SomeApp.createUserFirstLogin(userId: user.uid, username: userName, bio: bioField?.text ?? "")
        
        // If the user is not signed in with facebook, we update display name and photo url on firebase
        if user.providerID != "facebook.com" {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = userName
            changeRequest.photoURL = photoURL
        }
        
        //user.displayName = userName
        self.performSegue(withIdentifier: FirstLoginViewController.continueToAppSegueID, sender: nil)
    }
    
    // Editing the text field
    @objc func editingText(){
        goButton.isEnabled = false
        goButton.backgroundColor = .gray
        userNameTakenLabel.isHidden = true
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

// MARK: Get the city from the City Chooser
extension FirstLoginViewController: ItemChooserViewDelegate {
    func itemChooserReceiveCity(_ sender: City) {
        city = sender
        print(city.name)
        
    }
}
