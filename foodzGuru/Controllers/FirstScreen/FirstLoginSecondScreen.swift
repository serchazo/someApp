//
//  FirstLoginSecondScrennViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 11.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase

class FirstLoginSecondScreen: UIViewController {
    private let segueProfilePicOK = "segueProfilePicOK"
    private var user:User!
    
    // get from segue-r
    var userName:String!
    
    //
    private let photoPickerController = UIImagePickerController()
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }

    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.font = SomeApp.titleFont
            titleLabel.textColor = SomeApp.themeColor
            titleLabel.text = MyStrings.title.localized()
        }
    }
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!{
        didSet{
            warningLabel.text = MyStrings.warningLabel.localized()
        }
    }
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!{
        didSet{
            if #available(iOS 13, *){
                spinner.style = .large
            }
            spinner.hidesWhenStopped = true
        }
    }
    
    @IBOutlet weak var uploadImageButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    // MARK: timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        
        // 1. Get user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // 2. Get the profile picture
            //A. If the provider is facebook, get the info
            if self.user.photoURL != nil && self.user.providerData[0].providerID == "facebook.com"{
                // If the provider is facebook, we get the large picture
                let modifiedURL = self.user.photoURL!.absoluteString + "?type=large"
                self.photoURL = URL(string: modifiedURL)
                
                // B. if it's the firebase provider, we get the normal profile
            }else if self.user.photoURL != nil {
                self.photoURL = user.photoURL
            }else{
                // If the photoURL is empty, assign the default profile pic
                self.profilePicture.image = UIImage(named: "userdefault")
                self.photoURL = URL(string: "")
            }
        }
    }
    
    //
    private func configureButtons(){
        //Configure the image
        FoodzLayout.configureProfilePicture(imageView: profilePicture)
        
        // Upload image button
        FoodzLayout.configureButton(button: goButton)
        FoodzLayout.configureButtonNoBorder(button: uploadImageButton)
        goButton.setTitle(MyStrings.buttonGo.localized(), for: .normal)
        
        uploadImageButton.setTitle(MyStrings.buttonUpload.localized(), for: .normal)
        uploadImageButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.segueProfilePicOK,
            let seguedVC = segue.destination as? FirstLoginThirdScreen{
            seguedVC.username = userName
            seguedVC.photoURL = photoURL
        }
    }
    
}

// MARK: objc funcs
extension FirstLoginSecondScreen{
    // Upload profile picture
    @objc func uploadPhoto(){
        photoPickerController.delegate = self
        photoPickerController.sourceType =  UIImagePickerController.SourceType.photoLibrary
        self.present(photoPickerController, animated: true, completion: nil)
    }
}

// MARK: photo picker extension
extension FirstLoginSecondScreen: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        spinner.startAnimating()
        goButton.isHidden = true
        uploadImageButton.isHidden = true
        
        profilePicture.image = nil
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
                            print(FoodzLayout.FoodzStrings.log.localized(arguments: [error.localizedDescription]))
                        }else{
                            // Then get the download URL
                            imageRef.downloadURL { (url, error) in
                                guard let downloadURL = url else {
                                    // Uh-oh, an error occurred!
                                    print(FoodzLayout.FoodzStrings.log.localized(arguments: [error!.localizedDescription]))
                                    return
                                }
                                // Update the current photo
                                self.photoURL = downloadURL
                                self.spinner.stopAnimating()
                                self.goButton.isHidden = false
                                self.uploadImageButton.isHidden = false
                            }
                        }
                    }
                }
            }
        }
        photoPickerController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        profilePicture.sd_imageIndicator = SDWebImageActivityIndicator.gray
        profilePicture.sd_setImage(
        with: photoURL,
        placeholderImage: UIImage(named: "userdefault"),
        options: [],
        completed: nil)
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

// MARK: Localized Strings
extension FirstLoginSecondScreen{
    private enum MyStrings {
        case title
        case warningLabel
        case buttonGo
        case buttonUpload
        
        func localized(arguments: [CVarArg] = []) -> String{
            switch self{
            case .title:
                return String.localizedStringWithFormat(NSLocalizedString("FIRSTLOG2_TITLE", comment: "Configure"))
            case .warningLabel:
                return String.localizedStringWithFormat(NSLocalizedString("FIRSTLOG2_WARNING", comment: "can change"))
            case .buttonGo:
                return String.localizedStringWithFormat(NSLocalizedString("FIRSTLOG2_BUTTON_GO", comment: "Go"))
            case .buttonUpload:
                return String.localizedStringWithFormat(NSLocalizedString("FIRSTLOG2_BUTTON_UPLOAD", comment: "upload"))
            }
        }
    }
}
