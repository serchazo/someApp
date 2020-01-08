//
//  MyReview.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 05.01.20.
//  Copyright © 2020 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class MyReview: UIViewController {
    
    // Get from Segue-r
    var currentResto: Resto!
    var currentCity: City!
    var currentFood: FoodType!
    
    // Instance variables
    private var user: User!
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    
    // Outlets
    @IBOutlet weak var myPicture: UIImageView!
    @IBOutlet weak var myReviewTextView: UITextView!{
        didSet{
            myReviewTextView.delegate = self
        }
    }
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    // MARK: timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Get the current user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // Get the user picture
            SomeApp.dbUserData.child(user.uid).observeSingleEvent(of: .value, with: {snapshot in
                //
                if let value = snapshot.value as? [String: AnyObject]{
                    if let photoURL = value["photourl"] as? String {
                        self.photoURL = URL(string: photoURL)
                    }else{
                        self.photoURL = URL(string: "")
                    }
                }
            })
            
            // Get the current review (if any)
            let userReviewPath = user.uid + "/" + self.currentCity.country + "/" + self.currentCity.state + "/" + self.currentCity.key + "/" + self.currentResto.key
            
            SomeApp.dbUserReviews.child(userReviewPath).observe(.value, with:{ reviewSnap in
            if reviewSnap.exists(),
                let reviewValue = reviewSnap.value as? [String: AnyObject],
                let reviewText = reviewValue["text"] as? String{
                self.myReviewTextView.text = reviewText
                }
            })
            
        }
        //
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        myReviewTextView.becomeFirstResponder()
        self.navigationItem.title = currentResto.name
        
    }
    
    // MARK: Actions
    @IBAction func doneButtonPressed(_ sender: Any) {
        // Write to model
        SomeApp.updateUserReview(
                userid: user.uid,
                resto: currentResto,
                city: currentCity,
                foodId: currentFood.key ,
                text: myReviewTextView.text)
        
        //Close the view
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        FoodzLayout.configureProfilePicture(imageView: myPicture)
        
        myPicture.sd_imageIndicator = SDWebImageActivityIndicator.gray
        myPicture.sd_setImage(
        with: photoURL,
        placeholderImage: UIImage(named: "userdefault"),
        options: [],
            completed: nil)
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


// MARK: UITextView Delegate stuff
extension MyReview: UITextViewDelegate{
    
    // Set the character limit
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 1500
        
    }
}
