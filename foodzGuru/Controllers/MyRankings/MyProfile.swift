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

        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
        }
        
        myProfileTable.register(UINib(nibName: changePicCellXib, bundle: nil), forCellReuseIdentifier: changePicCellId)
        myProfileTable.register(UINib(nibName: changeBioCellXib, bundle: nil), forCellReuseIdentifier: changeBioCellId)
        
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
        return profileMenu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            return cell
        }
        // Change bio button
        else if indexPath.row == 3{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let changeBioButton = UIButton(type: .custom)
            changeBioButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTable.frame.width, height: cell.frame.height)
            changeBioButton.setTitleColor(SomeApp.themeColor, for: .normal)
            changeBioButton.setTitle("Edit Bio", for: .normal)
            changeBioButton.addTarget(self, action: #selector(changeProfilePicture), for: .touchUpInside)
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
            moreButton.addTarget(self, action: #selector(changeProfilePicture), for: .touchUpInside)
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
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == myProfileTable{
            print(indexPath)
            print("\(indexPath.row) :  \(profileMenu[indexPath.row])")
            
            if indexPath.row == 1{
                print(profileMenu[indexPath.row-1])
            }else if indexPath.row == 2{
                print(profileMenu[indexPath.row-1])
            }else if indexPath.row == 3{
                print(profileMenu[indexPath.row-1])
            }else if indexPath.row == 5{
                print(profileMenu[indexPath.row-1])
                
            }
        }
    }
    
}

// MARK: funcs
extension MyProfile{
    // Change profile pic
    @objc func changeProfilePicture(){
        photoPickerController.delegate = self
        photoPickerController.sourceType =  UIImagePickerController.SourceType.photoLibrary
        self.present(photoPickerController, animated: true, completion: nil)
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
    
    // MARK: logout
    @objc func logout(){
        do {
            try Auth.auth().signOut()
        } catch let error as NSError {
            print("Auth sign out failed: \(error.localizedDescription)")
        }
        performSegue(withIdentifier: self.logoffSegue, sender: nil)
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
