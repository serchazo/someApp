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
    private static let continueToAppSegueID = "profileOK"
    private static let cityChooserSegueID = "chooseCity"
    private var user:User!
    private var userName:String!
    private var userNameOKFlag = false
    private var city:City!
    private let photoPickerController = UIImagePickerController()
    
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
    @IBOutlet weak var uploadImageButton: UIButton!{
        didSet{
            self.uploadImageButton.isEnabled = false
            self.uploadImageButton.isHidden = true
        }
    }
    // Username outlets
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var userNameTakenLabel: UILabel!
    
    @IBOutlet weak var verifyNameSpinner: UIActivityIndicatorView!
    
    
    // Current city outlets
    @IBOutlet weak var selectCityField: UITextField!{
        didSet{
            selectCityField.isEnabled = true
            selectCityField.delegate = self
        }
    }
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
    
    // MARK: Timeline funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.startAnimating()
        // I. Get username
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            //A. If the provider is facebook, get the info
            if self.user.photoURL != nil && self.user.providerData[0].providerID == "facebook.com"{
                // If the provider is facebook, we get the large picture
                let modifiedURL = self.user.photoURL!.absoluteString + "?type=large"
                self.photoURL = URL(string: modifiedURL)
            
            // B. if it's the firebase provider, we get the normal profile
            }else if self.user.photoURL != nil {
                self.photoURL = user.photoURL
                self.uploadImageButton.isEnabled = true
                self.uploadImageButton.isHidden = false
            }else{
                // If the photoURL is empty, assign the default profile pic
                let defaultPicRef = SomeApp.storageUsersRef
                defaultPicRef.child("default.png").downloadURL(completion: {url, error in
                    if let error = error {
                       // Handle any errors
                        print("Error downloading the default picture \(error.localizedDescription).")
                     } else {
                       self.photoURL = url
                     }
                })
                
                self.uploadImageButton.isEnabled = true
                self.uploadImageButton.isHidden = false
            }
        }
        
        // Do any additional setup after loading the view.
        userNameTakenLabel.isHidden = true
        verifyUserNameButton.addTarget(self, action: #selector(verifyUserName), for: .touchUpInside)
        userNameField.addTarget(self, action: #selector(editingText), for: .editingDidBegin)
        goButton.addTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
        uploadImageButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)
        
        hideKeyboardWhenTappedAround()
    }
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        profilePic.sd_setImage(
        with: photoURL,
        placeholderImage: UIImage(named: "userdefault"),
        options: [],
        completed: nil)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == FirstLoginViewController.cityChooserSegueID,
        let destinationSegueVC = segue.destination as? ItemChooserViewController {
            destinationSegueVC.firstLoginFlag = true
            destinationSegueVC.delegate = self
        }
    }
    
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
                self.configureGoButton()
                self.userNameTakenLabel.textColor = .darkText
                self.userNameTakenLabel.text = "Good! This username is available."
                self.userNameTakenLabel.isHidden = false
            }
            self.verifyNameSpinner.stopAnimating()
        })
    }
    // Setting up the user
    @objc func goButtonPressed(){
        // Then create
        let cityString = city.country + "/" + city.state + "/" + city.key + "/" + city.name
        SomeApp.createUserFirstLogin(userId: user.uid, username: userName, bio: bioField?.text ?? "", defaultCity: cityString, photoURL: photoURL.absoluteString)
        
        // If the user is not signed in with facebook, we update display name and photo url on firebase
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
        
        self.performSegue(withIdentifier: FirstLoginViewController.continueToAppSegueID, sender: nil)
    }
    private func configureGoButton(){
        if city != nil && userNameOKFlag {
            goButton.isEnabled = true
            goButton.backgroundColor = SomeApp.themeColor
        }else{
            goButton.isEnabled = false
            goButton.backgroundColor = .gray
        }
    }
    
    // Editing the text field
    @objc func editingText(){
        userNameOKFlag = false
        configureGoButton()
        userNameTakenLabel.isHidden = true
    }
    
    // Upload profile picture
    @objc func uploadPhoto(){
        photoPickerController.delegate = self
        photoPickerController.sourceType =  UIImagePickerController.SourceType.photoLibrary
        self.present(photoPickerController, animated: true, completion: nil)
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
    func itemChooserReceiveCity(city: City, countryName: String, stateName: String) {
        selectCityField.placeholder = city.name
        selectCityButton.setTitle("Change", for: .normal)
        configureGoButton()
    }
}

// MARK: photo picker extension
extension FirstLoginViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        spinner.startAnimating()
        profilePic.image = nil
        DispatchQueue.main.async {
            if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                // Resize the image before uploading (less MBs on the user)
                let squareImage = self.squareImage(image: pickedImage)
                let transformedImage = self.resizeImage(image: squareImage, newDimension: 200)
                
                // Transform to data
                if transformedImage != nil {
                    let imageData:Data = transformedImage!.pngData()!
                    // Prepare the file first
                    let storagePath = self.user.uid + "/profilepicture.png"
                    let imageRef = SomeApp.storageUsersRef.child(storagePath)
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/png"

                    // Upload data and metadata
                    imageRef.putData(imageData, metadata: metadata) { (metadata, error) in
                        if let error = error {
                            print("Error uploading the image! \(error.localizedDescription)")
                        }else{
                            // Then get the download URL
                            imageRef.downloadURL { (url, error) in
                                guard let downloadURL = url else {
                                    // Uh-oh, an error occurred!
                                    print("Error getting the download URL")
                                    return
                                }
                                // Update the current photo
                                self.photoURL = downloadURL
                            }
                        }
                    }
                }
            }
        }
        photoPickerController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Resize the image
    // Snipet from StackOverFlow
    func resizeImage(image: UIImage, newDimension: CGFloat) -> UIImage? {
        let scale = newDimension / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newDimension, height: newHeight))
        
        image.draw(in: CGRect(x: 0, y: 0, width: newDimension, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    //  Resize Image: from https://gist.github.com/licvido/55d12a8eb76a8103c753
    func squareImage(image: UIImage) -> UIImage{
        let originalWidth  = image.size.width
        let originalHeight = image.size.height
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0
        var edge: CGFloat = 0.0
        
        if (originalWidth > originalHeight) {
            // landscape
            edge = originalHeight
            x = (originalWidth - edge) / 2.0
            y = 0.0
            
        } else if (originalHeight > originalWidth) {
            // portrait
            edge = originalWidth
            x = 0.0
            y = (originalHeight - originalWidth) / 2.0
        } else {
            // square
            edge = originalWidth
        }
        
        let cropSquare = CGRect(x: x, y: y, width: edge, height: edge)
        let imageRef = image.cgImage!.cropping(to: cropSquare)!;
        
        return UIImage(cgImage: imageRef, scale: UIScreen.main.scale, orientation: image.imageOrientation)
    }
}

// MARK: Edit text field delegate
extension FirstLoginViewController: UITextFieldDelegate{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == selectCityField{
            self.performSegue(withIdentifier: FirstLoginViewController.cityChooserSegueID, sender: nil)
            
            return false
        }else{
            return true
        }
    }
}
