//
//  MyRanksViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds
import SDWebImage

class MyRanks: UIViewController {
    //Control var
    var calledUser:UserDetails?
    var currentCity = City(name: "Singapore", state: "singapore", country: "singapore")
    
    // Class constants
    private static let addRanking = "addRankSegue"
    private static let showRakingDetail = "editRestoList"
    private static let screenSize = UIScreen.main.bounds.size
    private static let logoffSegue = "logoffSegue"
    
    // Instance variables
    private var user:User!
    private var rankings:[Ranking] = []
    private var foodItems:[FoodType] = []
    private var rankingReferenceForUser: DatabaseReference!
    private var foodDBReference: DatabaseReference!
    private var profileMenu = ["My profile", "Pic", "Settings", "Help & Support", "Log out"]
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    private let photoPickerController = UIImagePickerController()
    
    //For the myProfile swipe table
    private var transparentView = UIView()
    private var myProfileTableView = UITableView()
    
    // Ad stuff
    private var bannerView: GADBannerView!
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myRanksTable: UITableView!{
        didSet{
            myRanksTable.dataSource = self
            myRanksTable.delegate = self
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profilePictureImage: UIImageView!
    
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!{
        didSet{
            followersLabel.text = "Followers: - "
        }
    }
    @IBOutlet weak var followingLabel: UILabel!{
        didSet{
            followingLabel.text = "Following: - "
        }
    }
    @IBOutlet weak var followButton: UIButton!{
        didSet{
            followButton.isHidden = true
            followButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var adView: UIView!
    
    
    // MARK: Show myProfile table
    @IBAction func myProfileAction(_ sender: UIBarButtonItem) {        
        // Create the frame
        let window = UIApplication.shared.keyWindow
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        transparentView.frame = self.view.frame
        window?.addSubview(transparentView)
        
        // Add the table
        myProfileTableView.frame = CGRect(
            x: MyRanks.screenSize.width,
            y: MyRanks.screenSize.height * 0.1,
            width: MyRanks.screenSize.width * 0.9,
            height: MyRanks.screenSize.height * 0.9)
        window?.addSubview(myProfileTableView)
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickTransparentView))
        transparentView.addGestureRecognizer(tapGesture)
        
        // Cool "slide-up" animation when appearing
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0.7 //Start at 0, go to 0.5
                        self.myProfileTableView.frame = CGRect(
                            x: MyRanks.screenSize.width * 0.1,
                            y: MyRanks.screenSize.height * 0.1 ,
                            width: MyRanks.screenSize.width * 0.9,
                            height: MyRanks.screenSize.height * 0.9)
        },
                       completion: nil)
    }
    
    //Disappear!
    @objc func onClickTransparentView(){
        // Animation when disapearing
        
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0 //Start at value above, go to 0
                        self.myProfileTableView.frame = CGRect(
                            x: MyRanks.screenSize.width,
                            y: MyRanks.screenSize.height * 0.1,
                            width: MyRanks.screenSize.width * 0.9,
                            height: MyRanks.screenSize.height * 0.9)
                        
        },
                       completion: nil)
        
        // Deselect the row to go back to normal
        if let indexPath = myRanksTable.indexPathForSelectedRow {
            myRanksTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: Timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myProfileTableView.delegate = self
        myProfileTableView.dataSource = self
        myProfileTableView.rowHeight = UITableView.automaticDimension
        myProfileTableView.estimatedRowHeight = 100
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            var thisUserId:String
            if self.calledUser == nil{
                thisUserId = user.uid
            }else{
                thisUserId = self.calledUser!.key
            }
            self.configureHeader(userId: thisUserId)
            
            let pathId = thisUserId + "/"+self.currentCity.country+"/"+self.currentCity.state+"/"+self.currentCity.key
            self.rankingReferenceForUser = SomeApp.dbUserRankings.child(pathId)
            self.foodDBReference = SomeApp.dbFoodTypeRoot
            self.updateTablewithRanking()
        }
        
        // Configure the banner ad
        configureBannerAd()

    }
    // MARK: Ad stuff
    private func configureBannerAd(){
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
    }
    
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        profilePictureImage.layer.cornerRadius = 0.5 * self.profilePictureImage.bounds.size.width
        profilePictureImage.layer.borderColor = SomeApp.themeColorOpaque.cgColor
        profilePictureImage.layer.borderWidth = 2.0
        profilePictureImage.layoutMargins = UIEdgeInsets(top: 3.0, left: 3.0, bottom: 3.0, right: 3.0)
        profilePictureImage.clipsToBounds = true
        
        profilePictureImage.sd_setImage(
        with: photoURL,
        placeholderImage: UIImage(named: "userdefault"),
        options: [],
        completed: nil)
    }
    
    // MARK: Configure header
    func configureHeader(userId: String){
        // Navbar
        if calledUser != nil{
            navigationItem.rightBarButtonItem = nil
        }
        
        // First, go get some data from the DB
        SomeApp.dbUserData.child(userId).observeSingleEvent(of: .value, with: {snapshot in
            var username:String = "User Profile"
            if let value = snapshot.value as? [String: AnyObject]{
                // 1. Username
                if let userNick = value["nickname"] as? String { username = userNick }
                self.navigationItem.title = username
                self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                // 2. User photo
                if let photoURL = value["photourl"] as? String {
                    self.photoURL = URL(string: photoURL)
                }
        
                // 3. User bio
                if let userBio = value["bio"] as? String,
                    userBio != ""{
                    self.bioLabel.text = userBio
                }else{
                    if self.calledUser == nil{
                        self.bioLabel.textColor = .lightGray
                        self.bioLabel.text = "Click on Profile to add a bio."}
                }
            }
        })
        
        // Follow button
        if calledUser != nil {
            followButton.backgroundColor = .white
            followButton.setTitleColor(SomeApp.themeColor, for: .normal)
            followButton.layer.cornerRadius = 15
            followButton.layer.borderColor = SomeApp.themeColor.cgColor
            followButton.layer.borderWidth = 1.0
            followButton.layer.masksToBounds = true
            
            // We need to verify if the user is already following the target
            let tmpRef = SomeApp.dbUserFollowing.child(user.uid)
            tmpRef.child(calledUser!.key).observeSingleEvent(of: .value, with: {snapshot in
                if snapshot.exists() {
                    self.followButton.setTitle("Unfollow", for: .normal)
                    self.followButton.addTarget(self, action: #selector(self.unfollow), for: .touchUpInside)
                }else{
                    self.followButton.setTitle("Follow", for: .normal)
                    self.followButton.addTarget(self, action: #selector(self.follow), for: .touchUpInside)
                }
                self.followButton.isHidden = false
                self.followButton.isEnabled = true
            })
        }
        
        // Followers button
        let followersRef = SomeApp.dbUserNbFollowers
        followersRef.child(userId).observe(.value, with: {snapshot in
            if snapshot.exists(),
                let followers = snapshot.value as? Int {
                self.followersLabel.text = "Followers: \(followers)"
            }else{
                self.followersLabel.text = "Followers: 0"
            }
        })
        // Following button
        let followingRef = SomeApp.dbUserNbFollowing
        followingRef.child(userId).observe(.value, with: {snapshot in
            if snapshot.exists(),
                let following = snapshot.value as? Int {
                self.followingLabel.text = "Following: \(following)"
            }else{
                self.followingLabel.text = "Following: 0"
            }
        })
        
    }

    
    // MARK: Update from DB
    func updateTablewithRanking(){
        self.rankingReferenceForUser.observe(.value, with: {snapshot in
            //
            var tmpRankings: [Ranking] = []
            var tmpFoodType: [FoodType] = []
            var count = 0
            
            for ranksPerUserAny in snapshot.children {
                if let ranksPerUserSnapshot = ranksPerUserAny as? DataSnapshot,
                    let rankingItem = Ranking(snapshot: ranksPerUserSnapshot){
                    tmpRankings.append(rankingItem)
                    
                    //Get food type per country
                    self.foodDBReference.child(self.currentCity.country).child(rankingItem.key).observeSingleEvent(of: .value, with: { foodSnapshot in
                        let foodItem = FoodType(snapshot: foodSnapshot)
                        tmpFoodType.append(foodItem!)
                        
                        // Apply the trick when using Joins
                        count += 1
                        if count == snapshot.childrenCount {
                            self.foodItems = tmpFoodType
                            self.rankings = tmpRankings
                            self.myRanksTable.reloadData()
                        }
                    })
                }
            }
        })
    }
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case MyRanks.showRakingDetail :
            if let seguedMVC = segue.destination as? ThisRanking{
                if let tmpCell = sender as? MyRanksTableViewCell,
                    let tmpIndexPath = myRanksTable.indexPath(for: tmpCell){
                    // I should send Ranking, Food Key, and current city
                    seguedMVC.currentRanking = rankings[tmpIndexPath.row]
                    seguedMVC.currentCity = self.currentCity
                    seguedMVC.currentFood = foodItems[tmpIndexPath.row]
                    seguedMVC.profileImage = profilePictureImage.image
                    if calledUser != nil {
                        seguedMVC.calledUser = calledUser
                    }
                }
            }
        case MyRanks.addRanking :
            if let seguedMVC = segue.destination as? MyRanksAddRankingViewController{
                seguedMVC.delegate = self
            }
        default: 
            break
        }
    }
    
    // MARK: objc functions
    
    @objc func follow(){
        SomeApp.follow(userId: user.uid, toFollowId: calledUser!.key)
        updateTablewithRanking()
    }
    
    @objc func unfollow(){
        SomeApp.unfollow(userId: user.uid, unfollowId: calledUser!.key)
        updateTablewithRanking()
    }
    
    @objc func logout(){
        do {
            try Auth.auth().signOut()
        } catch let error as NSError {
            print("Auth sign out failed: \(error.localizedDescription)")
        }
        onClickTransparentView()
        performSegue(withIdentifier: MyRanks.logoffSegue, sender: nil)
    }
    
    // Change profile pic
    @objc func changeProfilePicture(){
        print("change pic")
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
    
}

// MARK: update the ranking list when we receive the event from the menu choser
extension MyRanks: MyRanksAddRankingViewDelegate{
    func addRankingReceiveInfoToCreate(inCity: String, withFood: FoodType) {
        
        // Test if we already have that ranking in our list
        if (rankings.filter {$0.key == withFood.key}).count == 0{
            // If we don't have the ranking, we add it to Firebase
            let defaultDescription = "Spent all my life looking for the best " + withFood.name + " places in " + currentCity.name + ". This is the definitive list."
            let newRanking = Ranking(foodKey: withFood.key,name: withFood.name, icon: withFood.icon, description: defaultDescription)
            // Create a child reference and update the value
            let newRankingRef = self.rankingReferenceForUser.child(newRanking.key)
            newRankingRef.setValue(newRanking.toAnyObject())
            // Only need to reload.  The firebase observer will update the content
            myRanksTable.reloadData()
            
        }else{
            // Ranking already in list
            let alert = UIAlertController(
                title: "Duplicate ranking",
                message: "You already have a \(withFood.name) ranking in \(inCity).",
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: {
                    (action: UIAlertAction)->Void in
                    //do nothing
            }))
            present(alert, animated: false, completion: nil)
        }
    }
}

// MARK: table stuff
extension MyRanks: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        // Verifiy if it's the myProfile table
        if tableView == myProfileTableView{
            return 1
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Verifiy if it's the myProfile table
        if tableView == myProfileTableView{
            return 5
        }else{
            // The normal table
            switch(section){
            case 0:
                guard rankings.count == foodItems.count else { return 1 }
                return rankings.count
            default: return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == myProfileTableView{
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
    
    // Delete ranking on swipe
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView == myRanksTable && indexPath.section == 0 && calledUser == nil {
            return UITableViewCell.EditingStyle.delete
        }else{
            return UITableViewCell.EditingStyle.none
            
        }
    }
    
    // then
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            // Delete from model
            SomeApp.deleteUserRanking(userId: user.uid, city: currentCity, ranking: rankings[indexPath.row])
            
            // Delete the row (only for smothness, we will download again)
            rankings.remove(at: indexPath.row)
            foodItems.remove(at: indexPath.row)
            myRanksTable.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    //cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Verifiy if it's the myProfile table
        if tableView == myProfileTableView{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            if indexPath.row == 0 {
                // Change picture row
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                configureChangePictureCell(cell: cell)
                return cell
            }
            if indexPath.row == 4 {
                // Logout row
                let logoutButton = UIButton(type: .custom)
                logoutButton.frame = CGRect(x: 0, y: cell.frame.minY, width: myProfileTableView.frame.width, height: cell.frame.height)
                logoutButton.setTitleColor(.red, for: .normal)
                logoutButton.setTitle("Log out", for: .normal)
                logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
                cell.selectionStyle = .none
                cell.addSubview(logoutButton)
                
                return cell
                
            }else{
                cell.textLabel?.text = profileMenu[indexPath.row]
                return cell
            }
            
        }else{
            // The normal table
            guard rankings.count > 0 && rankings.count == foodItems.count else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Waiting for services"
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            // Rankings table
            let tmpCell = tableView.dequeueReusableCell(withIdentifier: "MyRanksCell", for: indexPath)
            if let cell = tmpCell as? MyRanksTableViewCell {
                cell.iconLabel.text = foodItems[indexPath.row].icon
                let tmpTitleText = "Best " + foodItems[indexPath.row].name + " in " + currentCity.name
                cell.titleLabel.text = tmpTitleText
                cell.descriptionLabel.text = rankings[indexPath.row].description
            }
            return tmpCell
        }
        
    }
    
    // Sizing
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == myProfileTableView && indexPath.row == 0 {
            return 120
        }else{
            return UITableView.automaticDimension
        }
    }
    
}

// MARK: configure cells
extension MyRanks{
    private func configureChangePictureCell(cell: UITableViewCell){
        
        let backView = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: 110))
        
        let profilePicThumbnail = UIImageView()
        profilePicThumbnail.frame = CGRect(x: myProfileTableView.frame.width/2 - 35, y: 10, width: 70, height: 70)
        profilePicThumbnail.layer.cornerRadius = 0.5 * profilePicThumbnail.bounds.size.width
        profilePicThumbnail.layer.borderColor = SomeApp.themeColorOpaque.cgColor
        profilePicThumbnail.layer.borderWidth = 1.0
        profilePicThumbnail.clipsToBounds = true
        profilePicThumbnail.image = profilePictureImage.image
        
        backView.addSubview(profilePicThumbnail)
        
        let changeProfilePicButton = UIButton(type: .custom)
        changeProfilePicButton.frame = CGRect(x: myProfileTableView.frame.width * 3/8, y: 90, width: myProfileTableView.frame.width/4, height: 20)
        changeProfilePicButton.layer.cornerRadius = 10
        changeProfilePicButton.layer.masksToBounds = true
        changeProfilePicButton.setTitle("Change", for: .normal)
        changeProfilePicButton.tintColor = .white
        changeProfilePicButton.backgroundColor = SomeApp.themeColor
        changeProfilePicButton.addTarget(self, action: #selector(changeProfilePicture), for: .touchUpInside)

        backView.addSubview(changeProfilePicButton)
        
        cell.addSubview(backView)
        
    }
}

// MARK: Some view stuff
extension MyRanks{
    private var iconFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    private var cellTitleFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
    
    private var cellCityNameFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
}

// MARK: Banner Ad Delegate
extension MyRanks: GADBannerViewDelegate{
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(bannerView)
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
        
        //small animation
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}

// MARK: photo picker extension
extension MyRanks: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        profilePictureImage.image = nil
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
        onClickTransparentView()
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
