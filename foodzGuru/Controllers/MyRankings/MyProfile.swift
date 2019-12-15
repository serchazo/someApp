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
import SafariServices
import SDWebImage

class MyProfile: UIViewController {
    
    // Get from segue-r
    var profileImage: UIImage!
    var bioString: String!
    
    // Instance variables
    private var user:User!
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    private var profileMenu = ["Button", "Bio","bioButton","changePassButton", "Help & Support", "More","Log out"]
    private let photoPickerController = UIImagePickerController()
    private let logoffSegue = "logoffSegue"
    private let changePicCellId = "changePicCellId"
    private let changeBioCellId = "changeBioCellId"
    private let changePicCellXib = "ChangeProfilePicCell"
    private let changeBioCellXib = "ChangeBioCell"
    private let screenSize = UIScreen.main.bounds.size
    private let editBioCellId = "EditReviewCell"
    private let editBioCellXib = "EditReviewCell"
    
    private var isUploadingPic:Bool = false
    
    // Suport stuff
    private let supportAdress = MyStrings.supportEmailAddress.localized()
    private let supportSubject = MyStrings.supportEmailSubject.localized()
    private let supportBody = MyStrings.supportEmailBody.localized()
    
    // handles
    private var userDataHandle:UInt!
    
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
            
            // For avoiding drawing the extra lines
            myProfileTable.tableFooterView = UIView()
        }
    }
    
    @IBOutlet weak var tableHeaderView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var imageSpinner: UIActivityIndicatorView!
    
    // MARK: timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // First, go get some data from the DB
            self.userDataHandle = SomeApp.dbUserData.child(user.uid).observe(.value, with: {snapshot in
                //
                if let value = snapshot.value as? [String: AnyObject]{
                    if let photoURL = value["photourl"] as? String {
                        self.photoURL = URL(string: photoURL)
                    }else{
                        self.photoURL = URL(string: "")
                    }
                }
            })
        }
        
    }
    
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = MyStrings.navBarTitle.localized()
        setUpTables()
    }
    
    //
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if userDataHandle != nil {
            SomeApp.dbUserData.child(user.uid).removeObserver(withHandle: userDataHandle)
        }
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
            // Change picture button
            if indexPath.row == 0{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let changePicButton = UIButton(type: .custom)
                changePicButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                changePicButton.setTitleColor(SomeApp.themeColor, for: .normal)
                changePicButton.setTitle(MyStrings.buttonChangeProfilePic.localized(), for: .normal)
                changePicButton.addTarget(self, action: #selector(changeProfilePicture), for: .touchUpInside)
                cell.addSubview(changePicButton)
                
                return cell
            }
                // Change bio cell
            else if indexPath.row == 1,
                let cell = myProfileTable.dequeueReusableCell(withIdentifier: changeBioCellId, for: indexPath) as? MyProfileBioCell{
                cell.titleLabel.text = MyStrings.buttonBio.localized()
                
                if bioString != nil && bioString != ""{
                    cell.bioLabel.text = bioString!
                }else{
                    cell.bioLabel.text = MyStrings.buttonBioEmpty.localized()
                }
                cell.selectionStyle = .none
                return cell
            }
                // Change bio button
            else if indexPath.row == 2{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let changeBioButton = UIButton(type: .custom)
                changeBioButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                changeBioButton.setTitleColor(SomeApp.themeColor, for: .normal)
                changeBioButton.setTitle(MyStrings.buttonBioEdit.localized(), for: .normal)
                changeBioButton.addTarget(self, action: #selector(changeBio), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(changeBioButton)
                
                return cell
            }
                // Change password button
            else if indexPath.row == 3{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let changePasswordButton = UIButton(type: .custom)
                changePasswordButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                changePasswordButton.setTitleColor(SomeApp.themeColor, for: .normal)
                changePasswordButton.setTitle(MyStrings.buttonPsswd.localized(), for: .normal)
                changePasswordButton.addTarget(self, action: #selector(changePasswordAction), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(changePasswordButton)
                
                return cell
            }
                // Help button
            else if indexPath.row == 4 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let helpButton = UIButton(type: .custom)
                helpButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                helpButton.setTitleColor(SomeApp.themeColor, for: .normal)
                helpButton.setTitle(MyStrings.buttonHelp.localized(), for: .normal)
                helpButton.addTarget(self, action: #selector(showHelp), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(helpButton)
                
                return cell
            }
                // More button
            else if indexPath.row == 5 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let moreButton = UIButton(type: .custom)
                moreButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
                moreButton.setTitleColor(SomeApp.themeColor, for: .normal)
                moreButton.setTitle(MyStrings.buttonMore.localized(), for: .normal)
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
                logoutButton.setTitle(MyStrings.buttonSignOut.localized(), for: .normal)
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
            fatalError("My Profile: Cannot create cell")
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
    // show help
    @objc func showHelp(){
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let vc = SFSafariViewController(url: URL(string: FoodzLayout.FoodzStrings.appURL.localized())!, configuration: config)
        vc.navigationController?.navigationBar.titleTextAttributes = [
        NSAttributedString.Key.foregroundColor: SomeApp.themeColor]
        vc.preferredControlTintColor = SomeApp.themeColor
        vc.preferredBarTintColor = UIColor.white
        
        present(vc, animated: true)
    }
    
    // MARK: Change password
       @objc func changePasswordAction(_ sender: UIButton){
        let alert = UIAlertController(title: MyStrings.buttonPsswd.localized(),
        message: nil,
        preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(
            title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
            style: .cancel)
        
        let saveAction = UIAlertAction(
            title: MyStrings.buttonPsswdConfirm.localized(),
            style: .default) { _ in
                //Get e-mail and password from the alert
                let oldPassword = alert.textFields![0].text!
                let newPassword = alert.textFields![1].text!
                let confirmPassword = alert.textFields![2].text!
                
                // Passwords don't match
                if newPassword != confirmPassword {
                    let notMatchAlert = UIAlertController(
                        title: MyStrings.buttonPsswdErrorTitle.localized(),
                        message: MyStrings.buttonPsswdErrorMsg.localized(),
                        preferredStyle: .alert)
                    let okAction = UIAlertAction(
                        title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                        style: .default, handler: nil)
                    notMatchAlert.addAction(okAction)
                    self.present(notMatchAlert, animated: true, completion: nil)
                }
            // Call Firebase for an upgrade
            else{
                self.changePassword(email: self.user.email!, currentPassword: oldPassword, newPassword: newPassword) { (error) in
                    if error != nil {
                        let alert = UIAlertController(
                            title: MyStrings.buttonPsswdErrorTitle.localized(),
                            message: error!.localizedDescription,
                            preferredStyle: .alert)
                        alert.addAction(UIAlertAction(
                            title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                            style: .default))
                        self.present(alert,animated: true, completion: nil)
                    }
                    else {
                        let alert = UIAlertController(
                            title: MyStrings.buttonPsswdSuccessTitle.localized(),
                            message: MyStrings.buttonPsswdSuccessMsg.localized(),
                            preferredStyle: .alert)
                        alert.addAction(UIAlertAction(
                            title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                            style: .default))
                        self.present(alert,animated: true, completion: nil)
                    }
                }
                
            }
            
        }// [END] saveAction
        
        alert.addTextField { oldPassword in
            oldPassword.isSecureTextEntry = true
            oldPassword.autocapitalizationType = .none
            oldPassword.placeholder = MyStrings.buttonPsswdOld.localized()}
        
        alert.addTextField { newPassword in
            newPassword.isSecureTextEntry = true
            newPassword.autocapitalizationType = .none
            newPassword.placeholder = MyStrings.buttonPsswdNew.localized()
        }
        
        alert.addTextField { confirmPassword in
            confirmPassword.isSecureTextEntry = true
            confirmPassword.autocapitalizationType = .none
            confirmPassword.placeholder = MyStrings.buttonPsswdNewConfirm.localized()
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
       }
    
    func changePassword(email: String, currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (result, error) in
            if let error = error {
                completion(error)
            }
            else {
                Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
                    completion(error)
                })
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
        if bioString == nil || bioString!.count < 3{
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
                    alert.addAction(UIAlertAction(
                        title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                        style: .default))
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
                alert.addAction(UIAlertAction(
                    title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                    style: .default))
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
            SomeApp.dbUserData.removeAllObservers()
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
            message: nil,
            preferredStyle: .actionSheet)
        
        // About
        let aboutAction = UIAlertAction(title: "About", style: .default, handler: {_ in
            var version = "n/a"
            if let versionOp = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String{
                version = versionOp
            }
            var build = "n/a"
            if let buildOp = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String{
                build = buildOp
            }
            
            let aboutPopUp = UIAlertController(title: "About", message: "Version: \(version) Build: \(build)", preferredStyle: .alert)
            let OKAbout = UIAlertAction(
                title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                style: .default, handler: nil)
            aboutPopUp.addAction(OKAbout)
            self.present(aboutPopUp, animated: true)
        })
        
        // Send feedback
        let feedbackAction = UIAlertAction(title: "Send Feedback", style: .default, handler: { _ in
            let mailComposeViewController = self.configureMailComposer()
            if MFMailComposeViewController.canSendMail(){
                self.present(mailComposeViewController, animated: true, completion: nil)
            }else{
                print("Can't send email")
            }
        })
        
        // See EULA
        let eulaAction = UIAlertAction(
            title: FoodzLayout.FoodzStrings.eulaTermsOfService.localized(),
            style: .default, handler: {_ in
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                let eulaURL = FoodzLayout.FoodzStrings.eulaTermsOfServiceURL.localized()
                
                let vc = SFSafariViewController(url: URL(string: eulaURL)!, configuration: config)
                vc.navigationController?.navigationBar.titleTextAttributes = [
                    NSAttributedString.Key.foregroundColor: SomeApp.themeColor]
                vc.preferredControlTintColor = SomeApp.themeColor
                vc.preferredBarTintColor = UIColor.white
                
                self.present(vc, animated: true)
        })
        
        // See Privacy Policy
        let privacyPolicyAction = UIAlertAction(
            title: FoodzLayout.FoodzStrings.eulaPrivacyPolicy.localized(),
            style: .default, handler: {_ in
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                let privacyURL = FoodzLayout.FoodzStrings.eulaPrivacyPolicyURL.localized()
                
                let vc = SFSafariViewController(url: URL(string: privacyURL)!, configuration: config)
                vc.navigationController?.navigationBar.titleTextAttributes = [
                    NSAttributedString.Key.foregroundColor: SomeApp.themeColor]
                vc.preferredControlTintColor = SomeApp.themeColor
                vc.preferredBarTintColor = UIColor.white
                
                self.present(vc, animated: true)
        })
        
        // Delete Action
        let deleteProfileAction = UIAlertAction(title: "Delete profile", style: .destructive, handler: {  _ in
            let deleteAlert = UIAlertController(
                title: "Delete Profile?", message: "Warning: this can't be undone.", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: {_ in
                SomeApp.deleteUser(userId: self.user.uid)
                self.logout()
            })
            let cancelDelete = UIAlertAction(
                title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                style: .cancel, handler: nil)
            
            deleteAlert.addAction(cancelDelete)
            deleteAlert.addAction(deleteAction)
            self.present(deleteAlert,animated: true)
            
        })
        let cancelAction = UIAlertAction(
            title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
            style: .cancel, handler: nil)
        alert.addAction(aboutAction)
        alert.addAction(feedbackAction)
        alert.addAction(privacyPolicyAction)
        alert.addAction(eulaAction)
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
        imageSpinner.isHidden = false
        imageSpinner.startAnimating()
        profileImageView.image = nil
        
        DispatchQueue.main.async {
            if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                // First dismiss picker
                self.photoPickerController.dismiss(animated: true, completion: nil)
                self.isUploadingPic = true
                
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
                            print(print(FoodzLayout.FoodzStrings.log.localized(arguments: error.localizedDescription)))
                        }else{
                            // Then get the download URL
                            imageRef.downloadURL { (url, error) in
                                guard let downloadURL = url else {
                                    // Uh-oh, an error occurred!
                                    print(print(FoodzLayout.FoodzStrings.log.localized(arguments: error!.localizedDescription)))
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
        
    }
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        FoodzLayout.configureProfilePicture(imageView: profileImageView)
        
        profileImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        profileImageView.sd_setImage(
        with: photoURL,
        placeholderImage: UIImage(named: "userdefault"),
        options: [],
            completed: nil)
        imageSpinner.isHidden = true
        imageSpinner.stopAnimating()

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

// MARK: Localized Strings
extension MyProfile{
    private enum MyStrings {
        case supportEmailAddress
        case supportEmailSubject
        case supportEmailBody
        case navBarTitle
        case buttonChangeProfilePic
        case buttonBio
        case buttonBioEmpty
        case buttonBioEdit
        case buttonPsswd
        case buttonPsswdConfirm
        case buttonPsswdErrorTitle
        case buttonPsswdErrorMsg
        case buttonPsswdSuccessTitle
        case buttonPsswdSuccessMsg
        case buttonPsswdOld
        case buttonPsswdNew
        case buttonPsswdNewConfirm
        case buttonHelp
        case buttonMore
        case buttonSignOut
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .supportEmailAddress:
                return String(
                format: NSLocalizedString("MYPROFILE_SUPPORT_EMAIL_ADDRESS", comment: "email"),
                locale: .current,
                arguments: arguments)
            case .supportEmailSubject:
                return String(
                format: NSLocalizedString("MYPROFILE_SUPPORT_EMAIL_SUBJECT", comment: "Subject"),
                locale: .current,
                arguments: arguments)
            case .supportEmailBody:
                return String(
                format: NSLocalizedString("MYPROFILE_SUPPORT_EMAIL_BODY", comment: "Body"),
                locale: .current,
                arguments: arguments)
            case .navBarTitle:
                return String(
                format: NSLocalizedString("MYPROFILE_NAVBAR_TITLE", comment: "Title"),
                locale: .current,
                arguments: arguments)
            case .buttonChangeProfilePic:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPIC", comment: "Title"),
                locale: .current,
                arguments: arguments)
            case .buttonBio:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_BIO_NAME", comment: "Biography"),
                locale: .current,
                arguments: arguments)
            case .buttonBioEmpty:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_BIO_EMPTY", comment: "Biography"),
                locale: .current,
                arguments: arguments)
            case .buttonBioEdit:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_BIO_EDIT", comment: "Biography"),
                locale: .current,
                arguments: arguments)
            case .buttonPsswd:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD", comment: "Password"),
                locale: .current,
                arguments: arguments)
                
            case .buttonPsswdConfirm:
                return String(
                    format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_CONFIRM", comment: "Password"),
                    locale: .current,
                    arguments: arguments)
            case .buttonPsswdErrorTitle:
                return String(
                    format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_ERROR_MATCH_TITLE", comment: "Password"),
                    locale: .current,
                    arguments: arguments)
            case .buttonPsswdErrorMsg:
                return String(
                    format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_ERROR_MATCH_MSG", comment: "Password"),
                    locale: .current,
                    arguments: arguments)
            case .buttonPsswdSuccessTitle:
            return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_SUCCESS_TITLE", comment: "Success"),
                locale: .current,
                arguments: arguments)
            case .buttonPsswdSuccessMsg:
            return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_SUCCESS_MSG", comment: "Success"),
                locale: .current,
                arguments: arguments)
            case .buttonPsswdOld:
            return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_OLD", comment: "Success"),
                locale: .current,
                arguments: arguments)
            case .buttonPsswdNew:
            return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_NEW", comment: "Success"),
                locale: .current,
                arguments: arguments)
            case .buttonPsswdNewConfirm:
            return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_CHANGEPSSWD_NEWCONFIRM", comment: "Success"),
                locale: .current,
                arguments: arguments)
            
            case .buttonHelp:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_HELP", comment: "Help"),
                locale: .current,
                arguments: arguments)
            case .buttonMore:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_MORE", comment: "More"),
                locale: .current,
                arguments: arguments)
            case .buttonSignOut:
                return String(
                format: NSLocalizedString("MYPROFILE_BUTTON_LOGOFF", comment: "Sign out"),
                locale: .current,
                arguments: arguments)
            }
        }
    }
}
