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
    var calledUser:UserDetails!
    var currentCity = City(name: "singapore", state: "singapore", country: "singapore")
    
    // Class constants
    private static let addRanking = "addRankSegue"
    private static let showRakingDetail = "editRestoList"
    private static let screenSize = UIScreen.main.bounds.size
    
    // Instance variables
    private var user:User!
    private var rankings:[Ranking] = []
    private var foodItems:[FoodType] = []
    private var rankingReferenceForUser: DatabaseReference!
    private var foodDBReference: DatabaseReference!
    private var profileMenu = ["My profile", "Pic", "Settings", "Help & Support", "Log out"]
    
    //For the myProfile swipe table
    private var transparentView = UIView()
    private var myProfileTableView = UITableView()
    
    // Ad stuff
    private var bannerView: GADBannerView!
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myRanksTable: UITableView!{
        didSet{
            myRanksTable.dataSource = self
            myRanksTable.delegate = self
        }
    }
    
    // Action buttons
    
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
    
    //
    // MARK : Timeline funcs
    //
    
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
            
            // II.A. If the callingUserId String is empty, then it is the current user
            if self.calledUser == nil {
                let pathId = user.uid+"/"+self.currentCity.country+"/"+self.currentCity.state+"/"+self.currentCity.key
                // 2. Once we get the user, update!
                self.rankingReferenceForUser = SomeApp.dbUserRankings.child(pathId)
                self.foodDBReference = SomeApp.dbFoodTypeRoot
                self.updateTablewithRanking()
                
            }else{
                // II. B. The user is a "visitor", go get some data
                let pathId = self.calledUser.key+"/"+self.currentCity.country+"/"+self.currentCity.state+"/"+self.currentCity.key
                SomeApp.dbUserData.child(self.calledUser.key).observeSingleEvent(of: .value, with: {snapshot in
                    if let value = snapshot.value as? [String: AnyObject],
                        let userNick = value["nickname"] as? String{
                        self.navigationItem.title = userNick
                        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                    }
                })
                self.rankingReferenceForUser = SomeApp.dbUserRankings.child(pathId)
                self.foodDBReference = SomeApp.dbFoodTypeRoot
                self.updateTablewithRanking()
                // hide navbar buttons
                self.navigationItem.leftBarButtonItem = nil
                self.navigationItem.rightBarButtonItem = nil
            }
        }
        // Ad stuff
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self
        
        
        bannerView.load(GADRequest())
        bannerView.delegate = self

    }
    
    func updateTablewithRanking(){
        
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: MyRanks.screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: MyRanks.screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = SomeApp.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        if calledUser == nil {
            labelView.text = "Tell the world your favorite restorants"
        }else{
            labelView.text = "\(calledUser.nickName)'s favorite restorants!"
        }
        headerView.addSubview(labelView)
        // Follow button
        if calledUser != nil{
            let followButton = UIButton(type: .custom)
            followButton.frame = CGRect(x: MyRanks.screenSize.width/3, y: 60, width: MyRanks.screenSize.width/3, height: 40)
            followButton.backgroundColor = SomeApp.themeColor
            followButton.setTitleColor(.white, for: .normal)
            
            // We need to verify if the user is already following the target
            let tmpRef = SomeApp.dbUserFollowing.child(user.uid)
            tmpRef.child(calledUser.key).observeSingleEvent(of: .value, with: {snapshot in
                if snapshot.exists() {
                    followButton.setTitle("Unfollow", for: .normal)
                    followButton.addTarget(self, action: #selector(self.unfollow), for: .touchUpInside)
                    headerView.addSubview(followButton)
                }else{
                    followButton.setTitle("Follow", for: .normal)
                    followButton.addTarget(self, action: #selector(self.follow), for: .touchUpInside)
                    headerView.addSubview(followButton)
                }
                
            })
            headerView.frame = CGRect(x: 0, y: 0, width: MyRanks.screenSize.width, height: 100)
            
        }else{
            
        }
        self.myRanksTable.tableHeaderView = headerView
        
        //
        self.rankingReferenceForUser.observeSingleEvent(of: .value, with: {snapshot in
            //
            var tmpRankings: [Ranking] = []
            var tmpFoodType: [FoodType] = []
            var count = 0
            
            for ranksPerUserAny in snapshot.children {
                if let ranksPerUserSnapshot = ranksPerUserAny as? DataSnapshot,
                    let rankingItem = Ranking(snapshot: ranksPerUserSnapshot){
                    tmpRankings.append(rankingItem)
                    
                    //Get food type, first look in the "world"
                    self.foodDBReference.child("world").child(rankingItem.key).observeSingleEvent(of: .value, with: { foodSnapshot in
                        if foodSnapshot.exists(){
                            let foodItem = FoodType(snapshot: foodSnapshot)
                            tmpFoodType.append(foodItem!)
                        }else{
                            // if not, look in the country
                            self.foodDBReference.child(self.currentCity.country).child(rankingItem.key)
                            
                        }
                        
                        
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
    
    /// MARK : objc functions
    
    @objc
    func follow(){
        SomeApp.follow(userId: user.uid, toFollowId: calledUser.key)
        updateTablewithRanking()
    }
    
    @objc
    func unfollow(){
        SomeApp.unfollow(userId: user.uid, unfollowId: calledUser.key)
        updateTablewithRanking()
    }
    
    @objc
    func logout(){
        // 4
        do {
            try Auth.auth().signOut()
            onClickTransparentView()
            self.dismiss(animated: true, completion: nil)
        } catch (let error) {
            print("Auth sign out failed: \(error)")
        }
    }
    
}

// MARK : update the ranking list when we receive the event from the menu choser
extension MyRanks: MyRanksAddRankingViewDelegate{
    func addRankingReceiveInfoToCreate(inCity: String, withFood: FoodType) {
        
        // Test if we already have that ranking in our list
        if (rankings.filter {$0.key == withFood.key}).count == 0{
            // If we don't have the ranking, we add it to Firebase
            let newRanking = Ranking(foodKey: withFood.key,name: withFood.name)
            // Create a child reference and update the value
            let newRankingRef = self.rankingReferenceForUser.child(newRanking.key)
            newRankingRef.setValue(newRanking.toAnyObject())
            updateTablewithRanking()
            
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

// MARK : table stuff
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
            SomeApp.deleteUserRanking(userId: user.uid, rankingId: rankings[indexPath.row].key)
            
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
                let addCommentButton = UIButton(type: .custom)
                addCommentButton.frame = CGRect(x: 0, y: cell.frame.minY, width: cell.frame.width, height: cell.frame.height)
                //addCommentButton.backgroundColor = SomeApp.themeColor
                //addCommentButton.layer.cornerRadius = 20 //0.5 * addCommentButton.bounds.size.width
                //addCommentButton.layer.masksToBounds = true
                addCommentButton.setTitleColor(.red, for: .normal)
                addCommentButton.setTitle("Log out", for: .normal)
                addCommentButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
                
                cell.selectionStyle = .none
                cell.addSubview(addCommentButton)
                
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

// MARK : Ad suftt
extension MyRanks: GADBannerViewDelegate{
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
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
            ])
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
