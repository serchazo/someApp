//
//  HomeViewController.swift
//  someApp
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
    
    // Segue identifiers
    private let segueIDShowUserFromNewRanking = "showUserFromNewRanking"
    
    // Instance variables
    private var user: User!
    private var somePost: [(key: String, type:String, timestamp:Double, payload: String, icon: String, initiator: String, target: String)] = []
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
            var tmpPosts:[(key: String, type:String, timestamp:Double, payload: String, icon:String, initiator:String, target: String )] = []
        
            for child in snapshot.children{
                if let timeLineSnap = child as? DataSnapshot,
                    let value = timeLineSnap.value as? [String:AnyObject],
                    let type = value["type"] as? String,
                    let timestamp = value["timestamp"] as? Double,
                    let payload = value["payload"] as? String{
                    // Icon could be empty
                    var tmpIcon = ""
                    if let icon = value["icon"] as? String{tmpIcon = icon}
                    var tmpTarget = ""
                    if let target = value["target"] as? String {tmpTarget = target}
                    var tmpInitiator = ""
                    if let initiator = value["initiator"] as? String {tmpInitiator = initiator}
                    
                    tmpPosts.append((key: timeLineSnap.key, type: type, timestamp: timestamp, payload: payload, icon: tmpIcon, initiator: tmpInitiator, target: tmpTarget))
                    
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
            
            myRanksVC.currentCity = getCityFromTarget(target: somePost[indexPath.row].target)
            myRanksVC.calledUser = getUserObjectFromPost(post: somePost[indexPath.row])
        }
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
        
        if somePost[indexPath.row].type == TimelineEvents.NewUserRanking.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewUserRanking, for: indexPath) as? HomeCellWithImage {
            cell.titleLabel.text = "New Ranking"
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        
        
        // OLD CELLS: User initiated events in timeline
        else if [TimelineEvents.NewFollower.rawValue,
            TimelineEvents.NewUserFavorite.rawValue,
            TimelineEvents.NewUserReview.rawValue].contains(somePost[indexPath.row].type),
            let postCell = newsFeedTable.dequeueReusableCell(withIdentifier: timelineCellWithImage, for: indexPath) as? TimelineCellWithImage{
            
            setupPostCellWithImage(cell: postCell,
                                   type: somePost[indexPath.row].type,
                                   timestamp: somePost[indexPath.row].timestamp,
                                   payload: somePost[indexPath.row].payload,
                                   icon: somePost[indexPath.row].icon,
                                   initiator: somePost[indexPath.row].initiator,
                                   target: somePost[indexPath.row].target)
            
            return postCell
        }else if let postCell = newsFeedTable.dequeueReusableCell(withIdentifier: HomeViewController.timelineCellIdentifier, for: indexPath) as? TimelineCell{
            setupPostCell(cell: postCell,
                          type: somePost[indexPath.row].type,
                          timestamp: somePost[indexPath.row].timestamp,
                          payload: somePost[indexPath.row].payload,
                          icon: somePost[indexPath.row].icon)
            
            return postCell
        }else{
            fatalError("Unable to create cell")
        }
    }
}

////////////
// MARK : Home cells
////////////

extension HomeViewController{
    func setupPostCell(cell: TimelineCell, type:String, timestamp:Double, payload: String, icon:String ){
        
        // Date stuff
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        if (type == TimelineEvents.NewFollower.rawValue){
            cell.titleLabel.text = "Following"
            cell.bodyLabel.text = payload
            cell.iconLabel.text = "👤"
        }else if (type == TimelineEvents.NewUserRanking.rawValue){
            cell.titleLabel.text = "New Ranking"
            cell.bodyLabel.text  = payload
            cell.iconLabel.text = icon
            //cell.iconLabel.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4))
        }else if (type == TimelineEvents.NewUserFavorite.rawValue){
            cell.titleLabel.text = "New Favorite"
            cell.bodyLabel.text = payload
            cell.iconLabel.text = icon
            //cell.iconLabel.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4))
        }else if (type == TimelineEvents.NewBestRestoInRanking.rawValue){
            cell.titleLabel.text = "New Best!"
            cell.bodyLabel.text = payload
            cell.iconLabel.text = icon
        }else if (type == TimelineEvents.NewArrivalInRanking.rawValue){
            cell.titleLabel.text = "Among the best"
            cell.bodyLabel.text = payload
            cell.iconLabel.text = icon
        }else if (type == TimelineEvents.FoodzGuruPost.rawValue){
            cell.titleLabel.text = "foodz.guru"
            cell.bodyLabel.text = payload
            cell.iconLabel.text = "💬"
        }

    }
    
    // MARK: Old cells: Same but with Image
    func setupPostCellWithImage(cell: TimelineCellWithImage, type:String, timestamp:Double, payload: String, icon:String, initiator:String, target: String){
        
        // Date
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        // Body
        cell.bodyLabel.text = payload
        
        // Title
        if (type == TimelineEvents.NewFollower.rawValue){
            cell.titleLabel.text = "Following"
        }else if (type == TimelineEvents.NewUserRanking.rawValue){
            cell.titleLabel.text = "New Ranking"
            //cell.iconLabel.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4))
        }else if (type == TimelineEvents.NewUserFavorite.rawValue){
            cell.titleLabel.text = "New Favorite"
        }else if type == TimelineEvents.NewUserReview.rawValue{
            cell.titleLabel.text = "New Review"
        }
        
        // Picture
        let userRef = SomeApp.dbUserData
        userRef.child(initiator).observeSingleEvent(of: .value, with: {snapshot in
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
    }
    
    // MARK: new cells
    func setImageDateBodyInCell(cell: HomeCellWithImage, forPost: (key: String, type:String, timestamp:Double, payload: String, icon: String, initiator: String, target: String)){
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
    private func getCityFromTarget(target: String) -> City{
        let cityArray = target.components(separatedBy: "/")
        return City(country: cityArray[0] , state: cityArray[1], key: cityArray[2])
    }
    
    private func getUserObjectFromPost(post: (key: String, type:String, timestamp:Double, payload: String, icon: String, initiator: String, target: String)) -> UserDetails{
        let payLoadArray = post.payload.components(separatedBy: " ")
        return UserDetails(nickName: payLoadArray[0], key: post.initiator)
    }
}
