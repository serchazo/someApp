//
//  TimelineCellWithImage.swift
//  someApp
//
//  Created by Sergio Ortiz on 29.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class TimelineCellWithImage: UITableViewCell {
    
    var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    
    var userId:String!{
        didSet{
            getPhotoURL()
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!{
        didSet{
            bodyLabel.lineBreakMode = .byWordWrapping
            bodyLabel.numberOfLines = 0
        }
    }
    @IBOutlet weak var spinner: UIActivityIndicatorView!{
        didSet{
            spinner.startAnimating()
            spinner.hidesWhenStopped = true
        }
    }
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var cellImage: UIImageView!{
        didSet{
            cellImage.layer.cornerRadius = 0.5 * cellImage.bounds.size.height
            cellImage.layer.masksToBounds = true
            cellImage.layer.borderColor = SomeApp.themeColor.cgColor;
            cellImage.layer.borderWidth = 1.0;
        }
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        if let url = photoURL{
            let urlContents = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                if let imageData = urlContents, url == self.photoURL {
                    self.cellImage.image = UIImage(data: imageData)
                    self.cellImage.layer.cornerRadius = 0.5 * self.cellImage.bounds.size.width
                    self.cellImage.layer.borderColor = SomeApp.themeColorOpaque.cgColor
                    self.cellImage.layer.borderWidth = 2.0
                    self.cellImage.layoutMargins = UIEdgeInsets(top: 3.0, left: 3.0, bottom: 3.0, right: 3.0)
                    self.cellImage.clipsToBounds = true
                    self.spinner.stopAnimating()
                    
                }
            }
        }
    }
    
    //MARK: get photo URL from user
    private func getPhotoURL(){
        print("Test: \(userId)")
        let userRef = SomeApp.dbUserData
        userRef.child(userId!).observeSingleEvent(of: .value, with: {snapshot in
            if let value = snapshot.value as? [String:Any],
                let tmpPhotoURL = value["photourl"] as? String{
                self.photoURL = URL(string: tmpPhotoURL)
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
            }
            
        })
        
    }

}
