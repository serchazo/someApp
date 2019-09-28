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
    @IBOutlet weak var imageSpinner: UIActivityIndicatorView!
    
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
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            var thisUserId:String
            if self.calledUser == nil{
                thisUserId = user.uid
            }else{
                thisUserId = self.calledUser!.key
                // hide navbar buttons
                self.navigationItem.leftBarButtonItem = nil
                self.navigationItem.rightBarButtonItem = nil
            }
            self.configureHeader(userId: thisUserId)
            
            let pathId = thisUserId + "/"+self.currentCity.country+"/"+self.currentCity.state+"/"+self.currentCity.key
            self.rankingReferenceForUser = SomeApp.dbUserRankings.child(pathId)
            self.foodDBReference = SomeApp.dbFoodTypeRoot
            self.updateTablewithRanking()
        }
        // MARK: Ad stuff
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
        
        if let url = photoURL{
            let urlContents = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                if let imageData = urlContents, url == self.photoURL {
                    self.profilePictureImage.image = UIImage(data: imageData)
                    self.imageSpinner.stopAnimating()
                }
            }
        }
    }
    
    // MARK: Configure header
    func configureHeader(userId: String){
        // First, go get some data from the DB
        SomeApp.dbUserData.child(userId).observeSingleEvent(of: .value, with: {snapshot in
            var username:String = "User Profile"
            if let value = snapshot.value as? [String: AnyObject]{
                // 1. Username
                if let userNick = value["nickname"] as? String { username = userNick }
                self.navigationItem.title = username
                self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                // 2. User photo
                if let photoURL = value["photourl"] as? String { self.photoURL = URL(string: photoURL) }
                else{ // assign default photo URL
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
            followButton.backgroundColor = SomeApp.themeColor
            followButton.setTitleColor(.white, for: .normal)
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
            if let seguedMVC = segue.destination as? EditRanking{
                if let tmpCell = sender as? MyRanksTableViewCell,
                    let tmpIndexPath = myRanksTable.indexPath(for: tmpCell){
                    // I should send Ranking, Food Key, and current city
                    seguedMVC.currentRanking = rankings[tmpIndexPath.row]
                    seguedMVC.currentCity = self.currentCity
                    seguedMVC.currentFood = foodItems[tmpIndexPath.row]
                    if calledUser != nil {
                        seguedMVC.calledUserId = calledUser
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
        //self.dismiss(animated: true, completion: nil)
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
            if indexPath.row == 4 {
                // The button
                let logoutButton = UIButton(type: .custom)
                logoutButton.frame = CGRect(x: 0, y: cell.frame.minY, width: cell.frame.width, height: cell.frame.height)
                //addCommentButton.backgroundColor = SomeApp.themeColor
                //addCommentButton.layer.cornerRadius = 20 //0.5 * addCommentButton.bounds.size.width
                //addCommentButton.layer.masksToBounds = true
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

// MARK: Ad Delegate
extension MyRanks: GADBannerViewDelegate{
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(bannerView)
        
        /*
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])*/
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
