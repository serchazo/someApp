//
//  MyProfile.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 14.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import MessageUI

class MyProfile: UIViewController {
    
    
    // Get from segue-r
    var profileImage: UIImage!
    var bioString: String!
    
    
    // Instance variables
    private var user:User!
    private var photoURL: URL!
    private var profileMenu = ["Profile Pic", "Button", "Bio","bioButton", "Help & Support", "More","Log out"]
    private let photoPickerController = UIImagePickerController()
    private let logoffSegue = "logoffSegue"
    private let changePicCellId = "changePicCellId"
    private let changeBioCellId = "changeBioCellId"
    private let changePicCellXib = "ChangeProfilePicCell"
    private let changeBioCellXib = "ChangeBioCell"
    private let screenSize = UIScreen.main.bounds.size
    private let editBioCellId = "EditReviewCell"
    private let editBioCellXib = "EditReviewCell"
    
    // Suport stuff
    private let supportAdress = "support@foodz.guru"
    private let supportSubject = "Feedback on Foodz.guru"
    private let supportBody = "My feedback: "
    
    //For Edit the Bio swipe-up
    private var bioTransparentView = UIView()
    private var bioTableView = UITableView()
    private var bioTextField = UITextView()

    @IBOutlet weak var myProfileTable: UITableView!{
        didSet{
            myProfileTable.delegate = self
            myProfileTable.dataSource = self
            myProfileTable.rowHeight = UITableView.automaticDimension
            myProfileTable.estimatedRowHeight = 80
        }
    }
    
    // MARK: timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "My Profile"
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
        }
        setUpTables()
        
    }
    
    // Set up the tables
    private func setUpTables(){
        // myProfileTable (normal table)
        myProfileTable.register(UINib(nibName: changePicCellXib, bundle: nil), forCellReuseIdentifier: changePicCellId)
        myProfileTable.register(UINib(nibName: changeBioCellXib, bundle: nil), forCellReuseIdentifier: changeBioCellId)
        
        // Edit Bio Table
        bioTableView.delegate = self
        bioTableView.dataSource = self
        bioTextField.delegate = self
        bioTableView.register(UINib(nibName: editBioCellXib, bundle: nil), forCellReuseIdentifier: editBioCellId)
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

// MARK: Table stuff
extension MyProfile: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.bioTableView{
            return 1
        }else{
            return profileMenu.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Edit Bio pop-up
        if tableView == self.bioTableView,
            let cell = bioTableView.dequeueReusableCell(withIdentifier: self.editBioCellId, for: indexPath) as? EditReviewCell{
            
            configureEditBioCell(cell: cell)
            return cell
        }
        // [Start] The normal Table
        else if tableView == self.myProfileTable{
            // Picture cell
            if indexPath.row == 0,
                let cell = myProfileTable.dequeueReusableCell(withIdentifier: changePicCellId, for: indexPath) as? MyProfileChangePicCellTableViewCell{
                FoodzLayout.configureProfilePicture(imageView: cell.profilePicture)
                cell.profilePicture.image = self.profileImage
                cell.selectionStyle = .none
                
                return cell
            }
                // Change picture button
            else if indexPath.row == 1{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let changePicButton = UIButton(type: .custom)
                changePicButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                changePicButton.setTitleColor(SomeApp.themeColor, for: .normal)
                changePicButton.setTitle("Change Profile Picture", for: .normal)
                changePicButton.addTarget(self, action: #selector(changeProfilePicture), for: .touchUpInside)
                //cell.selectionStyle = .none
                cell.addSubview(changePicButton)
                
                return cell
                
            }
                // Change bio cell
            else if indexPath.row == 2,
                let cell = myProfileTable.dequeueReusableCell(withIdentifier: changeBioCellId, for: indexPath) as? MyProfileBioCell{
                cell.titleLabel.text = "Bio"
                
                if bioString != nil && bioString != ""{
                    cell.bioLabel.text = bioString!
                }else{
                    cell.bioLabel.text = "Enter a bio."
                }
                cell.selectionStyle = .none
                return cell
            }
                // Change bio button
            else if indexPath.row == 3{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let changeBioButton = UIButton(type: .custom)
                changeBioButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                changeBioButton.setTitleColor(SomeApp.themeColor, for: .normal)
                changeBioButton.setTitle("Edit Bio", for: .normal)
                changeBioButton.addTarget(self, action: #selector(changeBio), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(changeBioButton)
                
                return cell
            }
                // Help button
            else if indexPath.row == 4 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let helpButton = UIButton(type: .custom)
                helpButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                helpButton.setTitleColor(SomeApp.themeColor, for: .normal)
                helpButton.setTitle("Help & Support", for: .normal)
                helpButton.addTarget(self, action: #selector(changeProfilePicture), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(helpButton)
                
                return cell
            }
                // More button
            else if indexPath.row == 5{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let moreButton = UIButton(type: .custom)
                moreButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                moreButton.setTitleColor(SomeApp.themeColor, for: .normal)
                moreButton.setTitle("More", for: .normal)
                moreButton.addTarget(self, action: #selector(popupMoreMenu), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(moreButton)
                
                return cell
            }
                // Log out
            else if indexPath.row == 6 {
                // Logout row
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let logoutButton = UIButton(type: .custom)
                logoutButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                logoutButton.setTitleColor(.red, for: .normal)
                logoutButton.setTitle("Log out", for: .normal)
                logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(logoutButton)
                
                return cell
                
            }else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = profileMenu[indexPath.row]
                return cell
            }
        }
        // [END] Normal table
        else{
            fatalError("Cannot")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == bioTableView{
            return 450
        }
        // "Normal" Table
        else{
            return UITableView.automaticDimension
        }
    }
}

// MARK: funcs
extension MyProfile{
    // Change profile pic
    @objc func changeProfilePicture(_ sender: UIButton){
        sender.backgroundColor = SomeApp.themeColorOpaque
        photoPickerController.delegate = self
        photoPickerController.sourceType =  UIImagePickerController.SourceType.photoLibrary
        self.present(photoPickerController, animated: true, completion: nil)
        sender.backgroundColor = .white
    }
    
    // update user profile
    @objc func updateUserProfile(){
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = photoURL
        changeRequest.commitChanges(completion: {error in
            if let error = error{
                print("There was an error updating the user profile: \(error.localizedDescription)")
            }
            else{
                SomeApp.updateProfilePic(userId: self.user.uid, photoURL: self.photoURL.absoluteString)
            }
        })
    }
    
    // MARK: Change bio
    @objc func changeBio(_ sender: UIButton){
        //sender.backgroundColor = SomeApp.themeColorOpaque
        
        FoodzLayout.popupTable(viewController: self,
                               transparentView: bioTransparentView,
                               tableView: bioTableView)
        
        // Set the first responder
        if let cell = bioTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditReviewCell{
            cell.editReviewTextView.becomeFirstResponder()
        }
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickBioTransparentView))
        bioTransparentView.addGestureRecognizer(tapGesture)
    }
    
    //Disappear!
    @objc func onClickBioTransparentView(){
        // Animation when disapearing
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.bioTransparentView.alpha = 0 //Start at value above, go to 0
                        self.bioTableView.frame = CGRect(
                            x: 0,
                            y: self.screenSize.height ,
                            width: self.screenSize.width,
                            height: self.screenSize.height * 0.9)
                        self.bioTableView.endEditing(true)
                        
        },
                       completion: nil)
        
        // Deselect the row to go back to normal
        //if let indexPath = editRankTableView.indexPathForSelectedRow {
        //    editRankTableView.deselectRow(at: indexPath, animated: true)
        //}
    }
    
    // MARK: Edit Bio cell
    func configureEditBioCell(cell: EditReviewCell){
        
        FoodzLayout.configureEditTextCell(cell: cell)
        //title
        cell.titleLabel.text = "Edit Bio"
        cell.warningLabel.text = "Max 500 characters"
        
        // set up the TextField.  This var is defined in the class to take the value later
        if bioString == nil || bioString!.count < 5{
            cell.editReviewTextView.text = "Write a Bio here."
        }else{
            cell.editReviewTextView.text = bioString!
        }
        cell.editReviewTextView.becomeFirstResponder()
        
        cell.doneButton.setTitle("Done!", for: .normal)
        cell.updateReviewAction = { (cell) in
            let tmpBio = cell.editReviewTextView.text
            if tmpBio != "" && tmpBio != "Write a Bio here." {
                if tmpBio!.count > 500 {
                    // Too long
                    //Can't use FoodzLayout cz of the closure
                    let alert = UIAlertController(title: "Bio too long",
                                                  message: "Your bio shouldn't exceed 500 characters.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert,animated:true) {
                        cell.editReviewTextView.becomeFirstResponder()
                    }
                    
                }else{
                    // can write
                    SomeApp.updateBio(userId: self.user.uid, bio: tmpBio!)
                    self.bioString = tmpBio!
                    self.onClickBioTransparentView()
                    // Update cell
                    self.myProfileTable.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                    
                    
                }
            }else{
                //Empty bio
                //Can't use FoodzLayout cz of the closure
                let alert = UIAlertController(title: "Empty Bio",
                                              message: "Your bio is empty.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert,animated:true) {
                    cell.editReviewTextView.becomeFirstResponder()
                }
            }
        }
        
        cell.selectionStyle = .none
    }
    
    // MARK: logout
    @objc func logout(){
        do {
            try Auth.auth().signOut()
        } catch let error as NSError {
            print("Auth sign out failed: \(error.localizedDescription)")
        }
        performSegue(withIdentifier: self.logoffSegue, sender: nil)
    }
    
    // MARK: popup More menu
    @objc func popupMoreMenu(){
        let alert = UIAlertController(
            title: "More actions",
            message: "Some text",
            preferredStyle: .actionSheet)
        
        let feedbackAction = UIAlertAction(title: "Send Feedback", style: .default, handler: { _ in
            let mailComposeViewController = self.configureMailComposer()
            if MFMailComposeViewController.canSendMail(){
                self.present(mailComposeViewController, animated: true, completion: nil)
            }else{
                print("Can't send email")
            }
        })
        // Delete Action
        let deleteProfileAction = UIAlertAction(title: "Delete profile", style: .destructive, handler: {  _ in
            let deleteAlert = UIAlertController(
                title: "Delete Profile?", message: "Warning: this can't be undone.", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: {_ in
                SomeApp.deleteUser(userId: self.user.uid)
                self.logout()
            })
            let cancelDelete = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            deleteAlert.addAction(cancelDelete)
            deleteAlert.addAction(deleteAction)
            self.present(deleteAlert,animated: true)
            
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            print("Cancel")
        })
        alert.addAction(feedbackAction)
        alert.addAction(deleteProfileAction)
        alert.addAction(cancelAction)
        
        present(alert,animated: true, completion: nil)
    }
    
    // Send mail
    func configureMailComposer() -> MFMailComposeViewController{
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients([self.supportAdress])
        mailComposeVC.setSubject(self.supportSubject)
        mailComposeVC.setMessageBody(self.supportBody, isHTML: false)
        return mailComposeVC
    }
    
}

// MARK: photo picker extension
extension MyProfile: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        profileImage = nil
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
                                // Update the user
                                self.updateUserProfile()
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

// MARK: UITextView Delegate
extension MyProfile:UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 250
    }
    
}

// MARK: mail delegate
extension MyProfile: MFMailComposeViewControllerDelegate{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
