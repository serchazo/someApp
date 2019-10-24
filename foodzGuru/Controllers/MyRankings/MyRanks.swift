//
//  MyRanksViewController.swift
//  foodzGuru
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
    var currentCity: City!
    
    // Class constants
    private static let addRanking = "addRankSegue"
    private static let showRakingDetail = "editRestoList"
    private static let screenSize = UIScreen.main.bounds.size
    private let segueChangeCoty = "changeCity"
    private let segueMyProfile = "showMyProfile"
    
    // Instance variables
    private var user:User!
    private var rankings:[Ranking] = []
    private var foodItems:[FoodType] = []
    private var emptyListFlag = false
    private var rankingReferenceForUser: DatabaseReference!
    private var foodDBReference: DatabaseReference!
    private let defaults = UserDefaults.standard
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    private var bioString:String!
    
    
    
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
    
    @IBOutlet weak var changeCityButton: UIButton!
    
    // MARK: Ad stuff
    @IBOutlet weak var adView: UIView!
    // Ad stuff
    private var bannerView: GADBannerView!
    
    
    // MARK: Timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        // Deselect the row to go back to normal
        if let indexPath = myRanksTable.indexPathForSelectedRow {
            myRanksTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            
            if self.currentCity != nil{
                self.updateTablewithRanking(userId: thisUserId)
            }
            self.foodDBReference = SomeApp.dbFoodTypeRoot
        }
        
        // Configure the banner ad
        configureBannerAd()

    }
    
    // MARK: get city
    /*
    private func getCurrentCityFromDefaults() -> City{
        if let currentCityString = defaults.object(forKey: SomeApp.currentCityDefault) as? String{
            let cityArray = currentCityString.components(separatedBy: "/")
            return City(country: cityArray[0], state: cityArray[1], key: cityArray[2], name: cityArray[3])
        }else{
            return City(country: "singapore", state: "singapore", key: "singapore", name: "Singapore")
        }
    }*/
    
    //
    private func parseCityFromString(string2parse: String) -> City{
        let cityArray = string2parse.components(separatedBy: "/")
        return City(country: cityArray[0], state: cityArray[1], key: cityArray[2], name: cityArray[3])
    }
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        FoodzLayout.configureProfilePicture(imageView: profilePictureImage)

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
            navigationItem.leftBarButtonItem = navigationItem.backBarButtonItem
        }
        FoodzLayout.configureButton(button: changeCityButton)
        
        // First, go get some data from the DB
        SomeApp.dbUserData.child(userId).observe(.value, with: {snapshot in
            var username:String = "User Profile"
            if let value = snapshot.value as? [String: AnyObject]{
                // 1. Username
                if let userNick = value["nickname"] as? String { username = userNick }
                self.navigationItem.title = username
    
                // 2. User photo
                if let photoURL = value["photourl"] as? String {
                    self.photoURL = URL(string: photoURL)
                }else{
                    self.photoURL = URL(string: "")
                }
                
                // 3. Default city
                if self.calledUser != nil,
                    let tmpCity = value["default"] as? String {
                    self.currentCity = self.parseCityFromString(string2parse: tmpCity)
                }else if let currentCityString = self.defaults.object(forKey: SomeApp.currentCityDefault) as? String{
                    self.currentCity = self.parseCityFromString(string2parse: currentCityString)
                }else{
                    self.currentCity = City(country: "singapore", state: "singapore", key: "singapore", name: "Singapore")
                }
                // Change city button
                if self.currentCity != nil{
                    self.changeCityButton.setTitle(self.currentCity.name, for: .normal)
                }else{
                    self.changeCityButton.setTitle("Select city", for: .normal)
                }
        
                // 4. User bio
                if let userBio = value["bio"] as? String,
                    userBio != ""{
                    self.bioLabel.text = userBio
                    self.bioString = userBio
                }else{
                    if self.calledUser == nil{
                        self.bioLabel.textColor = .lightGray
                        self.bioLabel.text = "Click on Profile to add a bio."}
                }
                
                // 5. Update ranking
                self.updateTablewithRanking(userId: userId)
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
    func updateTablewithRanking(userId: String){
        let pathId = userId + "/"+self.currentCity.country+"/"+self.currentCity.state+"/"+self.currentCity.key
        rankingReferenceForUser = SomeApp.dbUserRankings.child(pathId)
        
        rankingReferenceForUser.observe(.value, with: {snapshot in
            //
            var tmpRankings: [Ranking] = []
            var tmpFoodType: [FoodType] = []
            var count = 0
            
            if !snapshot.exists(){
                // If we don't have a ranking, mark the empty list flag
                self.emptyListFlag = true
                self.myRanksTable.reloadData()
            }else{
                self.emptyListFlag = false
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
            }
        })
    }
    
    // MARK: Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case MyRanks.showRakingDetail :
            if let seguedMVC = segue.destination as? ThisRanking{
                if let tmpCell = sender as? MyRanksTableViewCell,
                    let tmpIndexPath = myRanksTable.indexPath(for: tmpCell){
                    // I should send Food Key, and current city
                    seguedMVC.currentCity = self.currentCity
                    seguedMVC.currentFood = foodItems[tmpIndexPath.row]
                    seguedMVC.profileImage = profilePictureImage.image
                    if calledUser != nil {
                        seguedMVC.calledUser = calledUser
                    }
                }
            }
        case MyRanks.addRanking :
            if let seguedMVC = segue.destination as? AddRanking{
                seguedMVC.delegate = self
                seguedMVC.currentCity = currentCity
            }
        case self.segueChangeCoty:
            if let cityChoserVC = segue.destination as? MyCities{
                if calledUser != nil{
                    cityChoserVC.calledUser = calledUser
                }
                cityChoserVC.myCitiesDelegate = self
            }
        case self.segueMyProfile:
            if let myProfileVC = segue.destination as? MyProfile{
                myProfileVC.bioString = bioString
                myProfileVC.profileImage = profilePictureImage.image
            }
        default: 
            break
        }
    }
    
    // MARK: objc functions
    @objc func follow(){
        SomeApp.follow(userId: user.uid, toFollowId: calledUser!.key)
        configureHeader(userId: calledUser!.key)
        followButton.removeTarget(self, action: #selector(self.follow), for: .touchUpInside)
    }
    
    @objc func unfollow(){
        let alert = UIAlertController(
        title: "Unfollow ?",
        message: "You will no longer receive updates and notifications from this user.",
        preferredStyle: .alert)
        // OK
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: {
                (action: UIAlertAction)->Void in
                //do nothing
        }))
        // Unfollow
        alert.addAction(UIAlertAction(
            title: "Unfollow",
            style: .destructive,
            handler: {
                (action: UIAlertAction)->Void in
                // Unfollow
                SomeApp.unfollow(userId: self.user.uid, unfollowId: self.calledUser!.key)
                self.configureHeader(userId: self.calledUser!.key)
                self.followButton.removeTarget(self, action: #selector(self.unfollow), for: .touchUpInside)
        }))
        present(alert, animated: false, completion: nil)
    }
    
    
    
}

// MARK: Add ranking delegate
extension MyRanks: AddRankingDelegate{
    func addRankingReceiveInfoToCreate(city: City, withFood: FoodType) {
        // Test if the ranking isn't in our list
        if (rankings.filter {$0.key == withFood.key}).count == 0{
            // If we don't have the ranking, we add it to Firebase
            SomeApp.newUserRanking(userId: user.uid, city: city, food: withFood)
            // Only need to reload.  The firebase observer will update the content
            myRanksTable.reloadData()
            
        }else{
            // Ranking already in list
            let alert = UIAlertController(
                title: "Duplicate ranking",
                message: "You already have a \(withFood.name) ranking in \(city.name).",
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section){
        case 0:
            guard rankings.count == foodItems.count else { return 1 }
            if emptyListFlag == true{
                return 1
            }else{
                return rankings.count
            }
        default: return 0
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
            SomeApp.deleteUserRanking(userId: user.uid, city: currentCity, foodId: rankings[indexPath.row].key)
            
            // Delete the row (only for smothness, we will download again)
            rankings.remove(at: indexPath.row)
            foodItems.remove(at: indexPath.row)
            myRanksTable.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    //cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // The normal table
        guard (rankings.count > 0 && rankings.count == foodItems.count) || emptyListFlag else{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Waiting for services"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            
            return cell
        }
        
        if emptyListFlag{
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "No rankings in \(currentCity.name) yet!"
            cell.detailTextLabel?.text = "Click on + and tell the world your favorite places!"
            return cell
        }else{
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

// MARK: Ad Stuff
extension MyRanks: GADBannerViewDelegate{
    // My funcs
    private func configureBannerAd(){
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
    }
    
    // Ad delegate
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
        
        // Default Ad
        FoodzLayout.defaultAd(adView: adView)
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

// MARK: city choser extension
extension MyRanks: MyCitiesDelegate{
    func myCitiesChangeCity(_ sender: City) {
        if currentCity == nil || sender.key != currentCity.key{
            rankings.removeAll()
            foodItems.removeAll()
            currentCity = sender
            changeCityButton.setTitle(currentCity.name, for: .normal)
            
            let tmpCityString = sender.country + "/" + sender.state + "/" + sender.key + "/" + sender.name
            // Save the default City
            defaults.set(tmpCityString, forKey: SomeApp.currentCityDefault)
            
            if calledUser == nil{
                updateTablewithRanking(userId: user.uid)
            }else{
                updateTablewithRanking(userId: calledUser!.key)
            }
        }
    }
}

