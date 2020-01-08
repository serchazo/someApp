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
    private static let showRankingDetail = "showRankingDetail"
    private static let screenSize = UIScreen.main.bounds.size
    private let segueChangeCoty = "changeCity"
    private let segueMyProfile = "showMyProfile"
    private let segueFollowers = "followersSegue"
    private let segueFollowing = "followingSegue"
    
    // Handles
    private var userDataHandle:UInt!
    private var followersHandle:UInt!
    private var followingHandle:UInt!
    private var rankingRefHandle:[(handle: UInt, dbPath:String)] = []
    private var userBlockedHandle:UInt!
    private var innerUserBlockedHandle: UInt!
    
    // Instance variables
    private var user:User!
    private var rankings:[Ranking] = []
    private var foodItems:[FoodType] = []
    private var emptyListFlag = false
    private var blockedFlag = false
    private var innerBlockedFlag = false
    private let defaults = UserDefaults.standard
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    private var bioString:String!
    
    @IBOutlet weak var myRanksCollection: UICollectionView!{
        didSet{
            myRanksCollection.delegate = self
            myRanksCollection.dataSource = self
        }
    }
    
    
    @IBOutlet weak var profilePictureImage: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followersButton: UIButton!{
        didSet{
            followersButton.setTitleColor(SomeApp.themeColor, for: .normal)
            let followersTitle = MyStrings.followers.localized() + ": -"
            followersButton.setTitle(followersTitle, for: .normal)
        }
    }
    @IBOutlet weak var followingButton: UIButton!{
        didSet{
            followingButton.setTitleColor(SomeApp.themeColor, for: .normal)
            let followingTitle = MyStrings.followers.localized() + ": -"
            followingButton.setTitle(followingTitle, for: .normal)
        }
    }
    @IBOutlet weak var followButton: UIButton!{
        didSet{
            followButton.isHidden = true
            followButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var changeCityButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: Ad stuff
    @IBOutlet weak var adView: UIView!
    // Ad stuff
    private var bannerView: GADBannerView!
    
    
    // MARK: Timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rankingRefHandle.removeAll()
        
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
            // II. Go ninja Go
            self.goNinjago(userId: thisUserId)
        }
        
        // Configure the banner ad
        configureBannerAd()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myRanksCollection.collectionViewLayout = generateLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        var userId = user.uid
        if calledUser != nil{
            userId = calledUser!.key
        }
        DispatchQueue.global(qos: .utility).async{
            if self.userDataHandle != nil{
                SomeApp.dbUserData.child(userId).removeObserver(withHandle: self.userDataHandle)
            }
            if self.followersHandle != nil {
                SomeApp.dbUserNbFollowers.child(userId).removeObserver(withHandle: self.followersHandle)
            }
            if self.followingHandle != nil {
                SomeApp.dbUserNbFollowing.child(userId).removeObserver(withHandle: self.followingHandle)
            }
            if self.userBlockedHandle != nil {
                let dbPath = self.calledUser!.key + "/" + self.user.uid
                SomeApp.dbUserBlocked.child(dbPath).removeObserver(withHandle: self.userBlockedHandle)
            }
            if self.innerUserBlockedHandle != nil {
                let dbPath = self.user.uid + "/" + self.calledUser!.key
                SomeApp.dbUserBlocked.child(dbPath).removeObserver(withHandle: self.innerUserBlockedHandle)
            }
            for (handle,dbPath) in self.rankingRefHandle{
                SomeApp.dbUserRankings.child(dbPath).removeObserver(withHandle: handle)
            }
        }
        //Remove banner delegate
        // Configure the banner ad
        bannerView.delegate = nil
    }
    
    // MARK: get city
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
    
    private func goNinjago(userId:String){
        // First, verify if the user is not blocked
        if calledUser != nil {
            let dbPath = calledUser!.key + "/" + user.uid
            userBlockedHandle = SomeApp.dbUserBlocked.child(dbPath).observe(.value, with: {snapshot in
                if snapshot.exists() {
                    self.blockedFlag = true
                    self.blockedUserHeader()
                }
                // If the user is not blocked
                else{
                    self.readFromDB(userId: userId)
                }
            })
            // The "inner" handle: verify if I'm the blocker
            let innerDBPath = self.user.uid + "/" + self.calledUser!.key
            innerUserBlockedHandle = SomeApp.dbUserBlocked.child(innerDBPath).observe(.value, with: { innerSnap in
                    self.innerBlockedFlag = innerSnap.exists()
            })
        }
        // My own info
        else{
            readFromDB(userId: userId)
        }
        
    }
    
    // MARK: blocked User Header
    func blockedUserHeader(){
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = navigationItem.backBarButtonItem
        navigationItem.title = MyStrings.blockedProfileName.localized()
        changeCityButton.isHidden = true
        changeCityButton.isEnabled = false
        bioLabel.text = MyStrings.blockedProfileBio.localized()
        
        //
    }
    
    // MARK: Read from DB
    func readFromDB(userId: String){
        // Navbar
        if calledUser != nil{
            let reportButton = UIBarButtonItem(title: "...", style: .done, target: self, action: #selector(reportActions))
            navigationItem.rightBarButtonItem = reportButton
            navigationItem.leftBarButtonItem = navigationItem.backBarButtonItem
        }
        
        // First, go get some data from the DB
        userDataHandle = SomeApp.dbUserData.child(userId).observe(.value, with: {snapshot in
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
                    self.currentCity = City(country: "sg", state: "sg", key: "sin", name: "Singapore")
                }
                // Change city button and title
                if self.currentCity != nil{
                    self.changeCityButton.setTitle(self.currentCity.name, for: .normal)
                    self.titleLabel.text = "My recommendations in \(self.currentCity.name)"
                }else{
                    self.changeCityButton.setTitle(MyStrings.selectCity.localized(), for: .normal)
                }
        
                // 4. User bio
                if let userBio = value["bio"] as? String,
                    userBio != ""{
                    self.bioLabel.text = userBio
                    self.bioString = userBio
                }else{
                    if self.calledUser == nil{
                        self.bioLabel.textColor = .systemGray2
                        self.bioLabel.text = MyStrings.emptyBio.localized()}
                }
                
                
                // 5. Update ranking
                self.updateTablewithRanking(userId: userId)
            }
        })
        
        // Change city button
        FoodzLayout.configureButtonNoBorder(button: changeCityButton)
        
        // Follow button
        if calledUser != nil {
            FoodzLayout.configureButtonNoBorder(button: followButton)
            
            // We need to verify if the user is already following the target
            let tmpRef = SomeApp.dbUserFollowing.child(user.uid)
            tmpRef.child(calledUser!.key).observeSingleEvent(of: .value, with: {snapshot in
                if snapshot.exists() {
                    self.followButton.setTitle(MyStrings.unfollow.localized(), for: .normal)
                    self.followButton.addTarget(self, action: #selector(self.unfollow), for: .touchUpInside)
                }else{
                    self.followButton.setTitle(MyStrings.follow.localized(), for: .normal)
                    self.followButton.addTarget(self, action: #selector(self.follow), for: .touchUpInside)
                }
                self.followButton.isHidden = false
                self.followButton.isEnabled = true
            })
        }
        
        // Followers button
        var followersString = MyStrings.followers.localized() + ": 0"
        followersButton.setTitle(followersString, for: .normal)
        followersHandle = SomeApp.dbUserNbFollowers.child(userId).observe(.value, with: {snapshot in
            if snapshot.exists(),
                let followers = snapshot.value as? Int {
                followersString = MyStrings.followers.localized() + ": " + String(followers)
                self.followersButton.setTitle(followersString, for: .normal)
            }
        })
        // Following button
        var followingString = MyStrings.following.localized() + ": 0"
        followingButton.setTitle(followingString, for: .normal)
        followingHandle = SomeApp.dbUserNbFollowing.child(userId).observe(.value, with: {snapshot in
            if snapshot.exists(),
                let following = snapshot.value as? Int {
                followingString = MyStrings.following.localized() + ": " + String(following)
                self.followingButton.setTitle(followingString, for: .normal)
            }
        })
        
    }

    
    // MARK: Update from DB
    func updateTablewithRanking(userId: String){
        let pathId = userId + "/"+self.currentCity.country+"/"+self.currentCity.state+"/"+self.currentCity.key
        
        rankingRefHandle.append((handle: SomeApp.dbUserRankings.child(pathId).observe(.value, with: {snapshot in
            //
            var tmpRankings: [Ranking] = []
            var tmpFoodType: [FoodType] = []
            var count = 0
            
            if !snapshot.exists(){
                // If we don't have a ranking, mark the empty list flag
                self.emptyListFlag = true
                self.myRanksCollection.reloadData()
                self.myRanksCollection.collectionViewLayout.invalidateLayout()
            }else{
                self.emptyListFlag = false
                for ranksPerUserAny in snapshot.children {
                    if let ranksPerUserSnapshot = ranksPerUserAny as? DataSnapshot,
                        let rankingItem = Ranking(snapshot: ranksPerUserSnapshot){
                        tmpRankings.append(rankingItem)
                        
                        //Get food type per country
                        SomeApp.dbFoodTypeRoot.child(self.currentCity.country).child(rankingItem.key).observeSingleEvent(of: .value, with: { foodSnapshot in
                            let foodItem = FoodType(snapshot: foodSnapshot)
                            if foodItem != nil{
                                tmpFoodType.append(foodItem!)
                            }
                            
                            // Apply the trick when using Joins
                            count += 1
                            if count == snapshot.childrenCount {
                                self.foodItems = tmpFoodType
                                self.rankings = tmpRankings
                                self.myRanksCollection.reloadData()
                                self.myRanksCollection.collectionViewLayout.invalidateLayout()
                            }
                        })
                    }
                }
            }
        }), dbPath: pathId))
        
        
    }
    
    // MARK: Report Action
    @objc func reportActions(){
        let alert = UIAlertController(
        title: nil,
        message: nil,
        preferredStyle: .actionSheet)
        
        // [START] Report Profile Action
        let reportProfileAction = UIAlertAction(
            title: MyStrings.reportProfileTitle.localized(),
            style: .destructive, handler: {  _ in
                let reasonForReporting = UIAlertController(
                    title: MyStrings.reportProfileTitle.localized(),
                    message: MyStrings.reportProfileReasonAsk.localized(),
                    preferredStyle: .actionSheet)
            // Choose your decision
            for content in ReportActions.allCases {
                let reportAction = UIAlertAction(
                    title: content.localized(),
                    style: .default,
                    handler: { _ in
                        SomeApp.reportUser(userId: self.user.uid, reportedId: self.calledUser!.key, reason: content)
                    // Warn the user
                    let thanks = UIAlertController(
                        title: MyStrings.reportProfileConfirmationTitle.localized(),
                        message: MyStrings.reportProfileConfirmationMsg.localized(),
                        preferredStyle: .alert)
                    let okAction = UIAlertAction(
                        title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                        style: .default, handler: nil)
                    thanks.addAction(okAction)
                    self.present(thanks,animated: true)
                    //
                })
                reasonForReporting.addAction(reportAction)
            }
            let cancelAction = UIAlertAction(
                title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                style: .cancel, handler: nil)
            reasonForReporting.addAction(cancelAction)
            
            self.present(reasonForReporting,animated: true)
        })
        // [END] Report Profile Action
        
        // [START] Block user action
        var tmpTitle = MyStrings.buttonBlock.localized()
        if innerBlockedFlag {tmpTitle = MyStrings.buttonUnblock.localized()}
        
        let blockProfileAction = UIAlertAction(title: tmpTitle, style: .destructive, handler: { _ in
            // [START] If haven't blocked yet : ask to block
            if !self.innerBlockedFlag{
                
                let confirmAlert = UIAlertController(
                    title: MyStrings.buttonBlockConfirmAskTitle.localized(arguments: self.calledUser!.nickName),
                    message: MyStrings.buttonBlockConfirmAskMsg.localized(),
                    preferredStyle: .alert)
                let blockAction = UIAlertAction(
                    title: MyStrings.buttonBlockConfirmOK.localized(),
                    style: .destructive,
                    handler: { _ in
                        SomeApp.blockUser(userId: self.user.uid, blockedUserId: self.calledUser!.key)
                    // Alert the user
                    let thanks = UIAlertController(
                        title: MyStrings.buttonBlockBlocked.localized(),
                        message: nil,
                        preferredStyle: .alert)
                    let okAction = UIAlertAction(
                        title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                        style: .default, handler: nil)
                    thanks.addAction(okAction)
                    self.present(thanks,animated: true)
                })
                let cancelAction = UIAlertAction(
                    title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                    style: .default, handler: nil)
                confirmAlert.addAction(blockAction)
                confirmAlert.addAction(cancelAction)
                self.present(confirmAlert,animated: true)
            }// [END] If haven't blocked yet : ask to block
            
            // [START] If I have blocked : ask to unblock
            else{
                let confirmAlert = UIAlertController(
                    title: MyStrings.buttonUnblockConfirmAskTitle.localized( arguments: self.calledUser!.nickName),
                    message: MyStrings.buttonUnblockConfirmAskMsg.localized(),
                    preferredStyle: .alert)
                let blockAction = UIAlertAction(
                    title: MyStrings.buttonUnblockConfirmOK.localized(),
                    style: .destructive,
                    handler: { _ in
                        SomeApp.unblockUser(userId: self.user.uid, blockedUserId: self.calledUser!.key)
                        // Alert the user
                        let thanks = UIAlertController(title: MyStrings.buttonUnblockBlocked.localized(), message: nil, preferredStyle: .alert)
                        let okAction = UIAlertAction(
                            title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                            style: .default, handler: nil)
                        thanks.addAction(okAction)
                        self.present(thanks,animated: true)
                })
                let cancelAction = UIAlertAction(
                    title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                    style: .default, handler: nil)
                confirmAlert.addAction(blockAction)
                confirmAlert.addAction(cancelAction)
                self.present(confirmAlert,animated: true)
            } // [END] If I have blocked : ask to unblock
            
        })
        // [END] Block user action
        
        alert.addAction(blockProfileAction)
        alert.addAction(reportProfileAction)
        let cancelAction = UIAlertAction(
            title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
            style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert,animated: true)
    }
    
    // MARK: Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case MyRanks.showRankingDetail :
        if let seguedMVC = segue.destination as? ThisRanking{
            if let tmpCell = sender as? SearchFoodCell,
                let tmpIndexPath = myRanksCollection.indexPath(for: tmpCell){
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
        case self.segueFollowers:
            if let followsVC = segue.destination as? FollowersViewController{
                followsVC.calledUser = self.calledUser
                followsVC.whatList = .Followers
            }
        case self.segueFollowing:
            if let followsVC = segue.destination as? FollowersViewController{
                followsVC.calledUser = self.calledUser
                followsVC.whatList = .Following
            }
            
        default: 
            break
        }
    }
    
    // MARK: objc functions
    @objc func follow(){
        SomeApp.follow(userId: user.uid, toFollowId: calledUser!.key)
        readFromDB(userId: calledUser!.key)
        followButton.removeTarget(self, action: #selector(self.follow), for: .touchUpInside)
    }
    
    @objc func unfollow(){
        let alert = UIAlertController(
        title: MyStrings.unfollow.localized() + "?",
        message: MyStrings.unfollowAlertMsg.localized(),
        preferredStyle: .alert)
        // OK
        alert.addAction(UIAlertAction(
            title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
            style: .default, handler: nil))
        // Unfollow
        alert.addAction(UIAlertAction(
            title: MyStrings.unfollow.localized(),
            style: .destructive,
            handler: {
                (action: UIAlertAction)->Void in
                // Unfollow
                SomeApp.unfollow(userId: self.user.uid, unfollowId: self.calledUser!.key)
                self.readFromDB(userId: self.calledUser!.key)
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
            self.myRanksCollection.reloadData()
            self.myRanksCollection.collectionViewLayout.invalidateLayout()
            
        }else{
            // Ranking already in list
            let alert = UIAlertController(
                title: MyStrings.duplicateRankingTitle.localized(),
                message: MyStrings.duplicateRankingMsg.localized(arguments: withFood.name, city.name),
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(
                title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                style: .default,
                handler: {
                    (action: UIAlertAction)->Void in
                    //do nothing
            }))
            present(alert, animated: false, completion: nil)
        }
    }
}


// MARK: Collection stuff
extension MyRanks: UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard rankings.count > 0 else { return 1 }
        return rankings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // TODO: while loading display a spinner
        guard rankings.count > 0 else {
            // then go
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "foodCell", for: indexPath) as? SearchFoodCell {
                cell.cellIcon.text = ""
                cell.cellLabel.text = FoodzLayout.FoodzStrings.loading.localized()
                return cell
            }else{
                fatalError("Cannot create cell")
            }
        }
        // Icon cells
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "foodCell", for: indexPath) as? SearchFoodCell {
            
            cell.cellIcon.text = rankings[indexPath.row].icon
            cell.cellLabel.text = rankings[indexPath.row].name
            
            return cell
        }
        
        // Cannot
        else{
            fatalError("Cannot create cell")
        }
    }
}


// MARK: Layout stuff
extension MyRanks{
    // snippet from : https://www.raywenderlich.com/5436806-modern-collection-views-with-compositional-layouts
    func generateLayout() -> UICollectionViewLayout {
        // Insets
        let insets = NSDirectionalEdgeInsets(
            top: 2,
            leading: 2,
            bottom: 2,
            trailing: 2)
      
        // We have three row styles
        // Style 1: 'Full': A full width photo
        // Style 2: 'Main with pair': A 2/3 width photo with two 1/3 width photos stacked vertically
        // Style 3: 'Triplet': Three 1/3 width photos stacked horizontally
        
        // I. First type. Full
        let fullPhotoItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                //heightDimension: .fractionalWidth(3/4)))
                heightDimension: .fractionalWidth(5.2/8))) // slightly smaller than 3/4 for the label not to be too big
        
        fullPhotoItem.contentInsets = insets
      
        // II. Second type: Main with pair
        /* Reserve
        let mainItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(2/3),
                heightDimension: .fractionalHeight(1.0)))
        
        mainItem.contentInsets = insets
      
        // Pair items are inside a group
        let pairItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(0.5)))
        
        pairItem.contentInsets = insets
      
        let trailingGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1/3),
                heightDimension: .fractionalHeight(1.0)),
            subitem: pairItem,
            count: 2)
      
        // Then the group
        
        let mainWithPairGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(4/8)),
                //heightDimension: .fractionalWidth(4/9)),
            subitems: [mainItem, trailingGroup])
         */
        
        // III. Third type. Twins
        let twinItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(4/8),
                heightDimension: .fractionalHeight(1.0)))
        
        twinItem.contentInsets = insets
        
        let twinGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(3/8)),
            subitems: [twinItem, twinItem])
      
        // IV. Fourth type. Reversed main with pair
        /*
        let mainWithPairReversedGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(4/9)),
            subitems: [trailingGroup, mainItem])
       */
        
        // V. Finally
        let nestedGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                //heightDimension: .fractionalWidth(13/8)),
                heightDimension: .fractionalWidth(8.2/8)),
            //subitems: [ twinGroup, fullPhotoItem, mainWithPairGroup]
            subitems: [ twinGroup, fullPhotoItem]
        )
        
        /*
        // Header
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: self.headerKind,
            alignment: .top)
         section.boundarySupplementaryItems = [sectionHeader]
        */
        
        let section = NSCollectionLayoutSection(group: nestedGroup)
        
        // Return the layout
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
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
    
    // Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        //print("adViewDidReceiveAd")
        FoodzLayout.removeDefaultAd(adView: adView)
        
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
    
    // Tells the delegate that a full-screen view will be presented in response
    // to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        //print("adViewWillPresentScreen")
    }
    
    // Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        //print("adViewWillDismissScreen")
    }
    
    // Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        //print("adViewDidDismissScreen")
    }
    
    // Tells the delegate that a user click will open another app (such as
    // the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        //print("adViewWillLeaveApplication")
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

// MARK: Localized Strings
extension MyRanks{
    private enum MyStrings {
        case followers
        case following
        case blockedProfileName
        case blockedProfileBio
        case selectCity
        case emptyBio
        case follow
        case unfollow
        case reportProfileTitle
        case reportProfileReasonAsk
        case reportProfileConfirmationTitle
        case reportProfileConfirmationMsg
        case buttonBlock
        case buttonUnblock
        case buttonBlockConfirmAskTitle
        case buttonBlockConfirmAskMsg
        case buttonBlockConfirmOK
        case buttonBlockBlocked
        case buttonUnblockConfirmAskTitle
        case buttonUnblockConfirmAskMsg
        case buttonUnblockConfirmOK
        case buttonUnblockBlocked
        case unfollowAlertMsg
        case duplicateRankingTitle
        case duplicateRankingMsg
        case emptyRankingTitle
        case emptyRankingMsg
        case bestPlacesTitle
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .followers:
                return String(
                format: NSLocalizedString("MYRANKS_FOLLOWERS", comment: "Follow"),
                locale: .current,
                arguments: arguments)
            case .following:
                return String(
                format: NSLocalizedString("MYRANKS_FOLLOWING", comment: "Follow"),
                locale: .current,
                arguments: arguments)
            case .follow:
                    return String(
                format: NSLocalizedString("MYRANKS_FOLLOW", comment: "Follow"),
                locale: .current,
                arguments: arguments)
            case .unfollow:
                    return String(
                format: NSLocalizedString("MYRANKS_UNFOLLOW", comment: "Unfollow"),
                locale: .current,
                arguments: arguments)
            case .blockedProfileName:
                return String(
                format: NSLocalizedString("MYRANKS_BLOCKEDPROFILE_NAME", comment: "Not found"),
                locale: .current,
                arguments: arguments)
            case .blockedProfileBio:
                return String(
                format: NSLocalizedString("MYRANKS_BLOCKEDPROFILE_BIO", comment: "Not found"),
                locale: .current,
                arguments: arguments)
            case .selectCity:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_SELECTCITY", comment: "City"),
                locale: .current,
                arguments: arguments)
            case .emptyBio:
                return String(
                format: NSLocalizedString("MYRANKS_BIO_EMPTY", comment: "Empty"),
                locale: .current,
                arguments: arguments)
            case .reportProfileTitle:
                return String(
                format: NSLocalizedString("MYRANKS_REPORTPROFILE_TITLE", comment: "To report"),
                locale: .current,
                arguments: arguments)
            case .reportProfileReasonAsk:
                return String(
                format: NSLocalizedString("MYRANKS_REPORTPROFILE_ASK_FOR_REASON", comment: "Why report"),
                locale: .current,
                arguments: arguments)
            case .reportProfileConfirmationTitle:
                return String(
                format: NSLocalizedString("MYRANKS_REPORTPROFILE_CONFIRMATION_TITLE", comment: "confirmation"),
                locale: .current,
                arguments: arguments)
            case .reportProfileConfirmationMsg:
                return String(
                format: NSLocalizedString("MYRANKS_REPORTPROFILE_CONFIRMATION_MSG", comment: "We will analyse"),
                locale: .current,
                arguments: arguments)
            case .buttonBlock:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_BLOCK", comment: "Block"),
                locale: .current,
                arguments: arguments)
            case .buttonUnblock:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_UNBLOCK", comment: "Unblock"),
                locale: .current,
                arguments: arguments)
            case .buttonBlockConfirmAskTitle:
                return String(
                    format: NSLocalizedString("MYRANKS_BUTTON_BLOCK_CONFIRM_TITLE", comment: "Block"),
                    locale: .current,
                    arguments: arguments)
            case .buttonBlockConfirmAskMsg:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_BLOCK_CONFIRM_MSG", comment: "Please confirm"),
                locale: .current,
                arguments: arguments)
            case .buttonBlockConfirmOK:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_BLOCK_CONFIRM_OK", comment: "Block"),
                locale: .current,
                arguments: arguments)
            case .buttonBlockBlocked:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_BLOCK_BLOCKED", comment: "Blocked"),
                locale: .current,
                arguments: arguments)
            case .buttonUnblockConfirmAskTitle:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_UNBLOCK_CONFIRM_TITLE", comment: "Block"),
                locale: .current,
                arguments: arguments)
            case .buttonUnblockConfirmAskMsg:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_UNBLOCK_CONFIRM_MSG", comment: "Please confirm"),
                locale: .current,
                arguments: arguments)
            case .buttonUnblockConfirmOK:
                return String(
                format: NSLocalizedString("MYRANKS_UNBUTTON_BLOCK_CONFIRM_OK", comment: "Block"),
                locale: .current,
                arguments: arguments)
            case .buttonUnblockBlocked:
                return String(
                format: NSLocalizedString("MYRANKS_BUTTON_UNBLOCK_BLOCKED", comment: "Blocked"),
                locale: .current,
                arguments: arguments)
            case .unfollowAlertMsg:
                return String(
                format: NSLocalizedString("MYRANKS_UNFOLLOW_ALERT_MSG", comment: "Unfollow"),
                locale: .current,
                arguments: arguments)
            case .duplicateRankingTitle:
                return String(
                format: NSLocalizedString("MYRANKS_DUPLICATE_RANKING_TITLE", comment: "Double"),
                locale: .current,
                arguments: arguments)
            case .duplicateRankingMsg:
                return String(
                format: NSLocalizedString("MYRANKS_DUPLICATE_RANKING_MSG", comment: "Double"),
                locale: .current,
                arguments: arguments)
            case .emptyRankingTitle:
                return String(
                    format: NSLocalizedString("MYRANKS_EMPTY_RANKING_TITLE", comment: "Empty"),
                    locale: .current,
                    arguments: arguments)
            case .emptyRankingMsg:
                return String(
                format: NSLocalizedString("MYRANKS_EMPTY_RANKING_MSG", comment: "Empty"),
                locale: .current,
                arguments: arguments)
            case .bestPlacesTitle:
                return String(
                    format: NSLocalizedString("MYRANKS_BESTPLACES_TITLE", comment: "Empty"),
                    locale: .current,
                    arguments: arguments)

            }
        }
    }
}
