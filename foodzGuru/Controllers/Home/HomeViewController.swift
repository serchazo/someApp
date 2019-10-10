//
//  HomeViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 15.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class HomeViewController: UIViewController {
    
    // Class variables
    private static let timelineCellIdentifier = "TimelineCell"
    private static let timelineCellNibIdentifier = "TimelineCell"
    private let timelineCellWithImage = "TimelineCellWithImage"
    private let timelineCellWithImageNibId = "TimelineCellWithImage"
    
    // Cell identifiers
    private let timelineNewUserRanking = "timelineUserRanking"
    private let timelineUserFollowing = "timelineUserFollowing"
    private let timelineNewUserReview = "timelineUserNewReview"
    private let timelineNewFavorite = "timelineUserFavorite"
    private let timelineRankingInfo = "timelineRankingInfoCell"
    
    // Segue identifiers
    private let segueIDShowUserFromNewRanking = "showUserFromNewRanking"
    private let segueIDShowUserFromFollowing = "showUserFollowing"
    private let segueIDShowUserReview = "showUserReview"
    private let segueIDShowUserFavorite = "showUserFavorite"
    private let segueIDShowTopRestos = "showTopRestos"
    
    // Instance variables
    private var user: User!
    private var somePost: [(key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)] = []
    private var userTimelineReference: DatabaseReference!
    
    
    @IBOutlet weak var newsFeedTable: UITableView!{
        didSet{
            newsFeedTable.delegate = self
            newsFeedTable.dataSource = self
            newsFeedTable.register(TimelineCell.self, forCellReuseIdentifier: HomeViewController.timelineCellIdentifier)
            // register cells
            newsFeedTable.register(UINib(nibName: HomeViewController.timelineCellNibIdentifier, bundle: nil), forCellReuseIdentifier: HomeViewController.timelineCellIdentifier)
            newsFeedTable.register(UINib(nibName: timelineCellWithImageNibId, bundle: nil), forCellReuseIdentifier: timelineCellWithImage)
            
            
            newsFeedTable.rowHeight = UITableView.automaticDimension
            newsFeedTable.estimatedRowHeight = 150
        }
    }
    
    // MARK: Timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if let indexPath = newsFeedTable.indexPathForSelectedRow {
            newsFeedTable.deselectRow(at: indexPath, animated: true)
        }

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Foodz.guru"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // 1. Get the logged in user - needed for the next step
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // 2. Once we get the user, update!
            self.userTimelineReference = SomeApp.dbUserTimeline.child(user.uid)
            self.updateTimelinefromDB()
        }
    }
    
    // MARK: update from DB
    func updateTimelinefromDB(){
        userTimelineReference.queryOrdered(byChild: "timestamp").observeSingleEvent(of: .value, with: {snapshot in
            var count = 0
            var tmpPosts:[(key: String, type:String, timestamp:Double, payload: String, initiator:String, target: String, targetName: String)] = []
        
            for child in snapshot.children{
                if let timeLineSnap = child as? DataSnapshot,
                    let value = timeLineSnap.value as? [String:AnyObject],
                    let type = value["type"] as? String,
                    let timestamp = value["timestamp"] as? Double,
                    let payload = value["payload"] as? String{
                    // Following could be empty
                    var tmpTarget = ""
                    if let target = value["target"] as? String {tmpTarget = target}
                    var tmpTargetName = ""
                    if let targetName = value["targetName"] as? String {tmpTargetName = targetName}
                    var tmpInitiator = ""
                    if let initiator = value["initiator"] as? String {tmpInitiator = initiator}
                    
                    tmpPosts.append((
                        key: timeLineSnap.key,
                        type: type,
                        timestamp: timestamp,
                        payload: payload,
                        initiator: tmpInitiator,
                        target: tmpTarget,
                        targetName: tmpTargetName))
                    
                    // Use the trick
                    count += 1
                    if count == snapshot.childrenCount{
                        self.somePost = tmpPosts.reversed()
                        self.newsFeedTable.reloadData()
                    }
                }
            }
        })
    }
    

    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == self.segueIDShowUserFromNewRanking,
            let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let myRanksVC = segue.destination as? MyRanks{
            
            myRanksVC.currentCity = getCityFromNewRanking(target: somePost[indexPath.row].target, targetName:somePost[indexPath.row].targetName)
            myRanksVC.calledUser = getUserObjectFromNewRanking(post: somePost[indexPath.row])
        }
        //Show user ranking details for new following
        else if segue.identifier == self.segueIDShowUserFromFollowing,
        let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let myRanksVC = segue.destination as? MyRanks{
            
            myRanksVC.calledUser = getUserObjectFromNewFollowing(post: somePost[indexPath.row])
            myRanksVC.currentCity = getCityFromFollowing(target: somePost[indexPath.row].target)
        }
        // Show ThisRanking for new review
        else if segue.identifier == self.segueIDShowUserReview,
            let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let thisRankingVC = segue.destination as? ThisRanking{
            // Setup the stuff
            let parseResult = parseNewReview(target: somePost[indexPath.row].target, targetName: somePost[indexPath.row].targetName, initiator: somePost[indexPath.row].initiator)
            
            thisRankingVC.calledUser = parseResult.user
            thisRankingVC.currentCity = parseResult.city
            thisRankingVC.currentFood = parseResult.food
        }
        // Show ThisRanking for new favorite
        else if segue.identifier == self.segueIDShowUserFavorite,
            let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let thisRankingVC = segue.destination as? ThisRanking{
            // Setup the stuff
            let parseResult = parseNewReview(target: somePost[indexPath.row].target, targetName: somePost[indexPath.row].targetName, initiator: somePost[indexPath.row].initiator)
            
            thisRankingVC.calledUser = parseResult.user
            thisRankingVC.currentCity = parseResult.city
            thisRankingVC.currentFood = parseResult.food
        }
        // Show resto rank for ranking stuff
        else if segue.identifier == self.segueIDShowTopRestos,
        let cell = sender as? HomeCellWithIcon,
        let indexPath = newsFeedTable.indexPath(for: cell),
            let topRestosVC = segue.destination as? RestoRankViewController{
            let parseResult = parseTopRestos(target: somePost[indexPath.row].target, targetName: somePost[indexPath.row].targetName, initiator: somePost[indexPath.row].initiator)
            
            topRestosVC.currentCity = parseResult.city
            topRestosVC.currentFood = parseResult.food
        }
        //
    }

}

// MARK: Table stuff
extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard somePost.count > 0 else {return 1}
        return somePost.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // If empty, turn spinner
        guard somePost.count > 0 else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Waiting for services"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            
            return cell
        }
        
        // New ranking
        if somePost[indexPath.row].type == TimelineEvents.NewUserRanking.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewUserRanking, for: indexPath) as? HomeCellWithImage {
            cell.titleLabel.text = "New Ranking"
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // User following
        else if somePost[indexPath.row].type == TimelineEvents.NewFollower.rawValue,
        let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineUserFollowing, for: indexPath) as? HomeCellWithImage {
            cell.titleLabel.text = "Following"
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New review
        else if somePost[indexPath.row].type == TimelineEvents.NewUserReview.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewUserReview, for: indexPath) as? HomeCellWithImage  {
            cell.titleLabel.text = "New Review"
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New favorite
        else if somePost[indexPath.row].type == TimelineEvents.NewUserFavorite.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewFavorite, for: indexPath) as? HomeCellWithImage  {
            cell.titleLabel.text = "New Favorite!"
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New best in ranking
        else if somePost[indexPath.row].type == TimelineEvents.NewBestRestoInRanking.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: timelineRankingInfo, for: indexPath) as? HomeCellWithIcon {
            cell.titleLabel.text = "New Best!"
            setIconDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New arrival in ranking
        else if somePost[indexPath.row].type == TimelineEvents.NewArrivalInRanking.rawValue,
        let cell = newsFeedTable.dequeueReusableCell(withIdentifier: timelineRankingInfo, for: indexPath) as? HomeCellWithIcon {
            cell.titleLabel.text = "Let's go taste"
            setIconDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
            
        // Foodz.guru stuff
        else if let postCell = newsFeedTable.dequeueReusableCell(withIdentifier: HomeViewController.timelineCellIdentifier, for: indexPath) as? TimelineCell{
            setupPostCell(cell: postCell,
                          type: somePost[indexPath.row].type,
                          timestamp: somePost[indexPath.row].timestamp,
                          payload: somePost[indexPath.row].payload,
                          icon: "💬")
            
            return postCell
        }else{
            fatalError("Unable to create cell")
        }
    }
}

// MARK: Home cells

extension HomeViewController{
    func setupPostCell(cell: TimelineCell, type:String, timestamp:Double, payload: String, icon:String ){
        
        // Date stuff
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        if (type == TimelineEvents.FoodzGuruPost.rawValue){
            cell.titleLabel.text = "foodz.guru"
            cell.bodyLabel.text = payload
            cell.iconLabel.text = "💬"
        }

    }
    
    // MARK: new cells
    // With icon
    func setIconDateBodyInCell(cell: HomeCellWithIcon, forPost: (key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)){
        // Set icon
        let tmpArray = forPost.targetName.components(separatedBy: "/")
        if tmpArray.count > 3{
            cell.iconLabel.text = tmpArray[2]
        }else{
            cell.iconLabel.text = "💬"
        }
        
        // Set Date
        let date = Date(timeIntervalSince1970: TimeInterval(forPost.timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        // Body
        cell.bodyLabel.text = forPost.payload
    }
    
    // With image
    func setImageDateBodyInCell(cell: HomeCellWithImage, forPost: (key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)){
        // Set Image
        let userRef = SomeApp.dbUserData
        userRef.child(forPost.initiator).observeSingleEvent(of: .value, with: {snapshot in
            if let value = snapshot.value as? [String:Any],
                let photoURL = value["photourl"] as? String{
                cell.cellImage.sd_setImage(
                    with: URL(string: photoURL),
                    placeholderImage: UIImage(named: "userdefault"),
                    options: [],
                    completed: nil)
            }else{
                cell.cellImage.image = UIImage(named: "userdefault")
            }
        })
        
        // Set Date
        let date = Date(timeIntervalSince1970: TimeInterval(forPost.timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        // Body
        cell.bodyLabel.text = forPost.payload
        
    }
}

// MARK: parsing funcs
extension HomeViewController{
    //
    private func getCityFromNewRanking(target: String, targetName: String) -> City{
        let cityArray = target.components(separatedBy: "/")
        let targetArray = targetName.components(separatedBy: "/")
        return City(country: cityArray[0] , state: cityArray[1], key: cityArray[2], name: targetArray[1])
    }
    //
    private func getUserObjectFromNewRanking(post: (key: String, type:String, timestamp:Double, payload: String,initiator: String, target: String, targetName: String)) -> UserDetails{
        let payLoadArray = post.payload.components(separatedBy: " ")
        return UserDetails(nickName: payLoadArray[0], key: post.initiator)
    }
    // Get user object from following post
    private func getUserObjectFromNewFollowing(post: (key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)) -> UserDetails{
        let nick = post.targetName
        let payLoadArray = post.target.components(separatedBy: "/")
        let userKey = payLoadArray[payLoadArray.count-1]
        return UserDetails(nickName: nick, key: userKey)
    }
    // Get city from following post
    private func getCityFromFollowing(target: String) -> City{
        let cityArray = target.components(separatedBy: "/")
        return City(country: cityArray[0] , state: cityArray[1], key: cityArray[2], name: cityArray[3])
    }
    
    // Parse new review post
    private func parseNewReview(target:String, targetName:String, initiator:String) -> (food:FoodType, user: UserDetails, city: City){
        let targetArray = target.components(separatedBy: "/")
        let targetNameArray = targetName.components(separatedBy: "/")
        let tmpUser = UserDetails(nickName: targetNameArray[0], key: initiator)
        let tmpCity = City(country: targetArray[0] , state: targetArray[1], key: targetArray[2], name: targetNameArray[1])
        let tmpFood = FoodType(icon: targetNameArray[3], name: targetNameArray[2], key: targetArray[3])
        return (food: tmpFood, user: tmpUser, city: tmpCity)
    }
    
    // Parse top restos post
    private func parseTopRestos(target:String, targetName:String, initiator:String) -> (food:FoodType, city: City){
        let targetArray = target.components(separatedBy: "/")
        let targetNameArray = targetName.components(separatedBy: "/")
        let tmpCity = City(country: targetArray[0] , state: targetArray[1], key: targetArray[2], name: targetNameArray[0])
        let tmpFood = FoodType(icon: targetNameArray[2], name: targetNameArray[1], key: targetArray[3])
        
        return (food: tmpFood, city: tmpCity)
    }
    
}
