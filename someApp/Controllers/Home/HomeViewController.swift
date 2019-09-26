//
//  HomeViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 15.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase 

class HomeViewController: UIViewController {
    
    // Class variables
    private static let timelineCellIdentifier = "TimelineCell"
    private static let timelineCellNibIdentifier = "TimelineCell"
    
    // Instance variables
    private var user: User!
    private var somePost: [(key: String, type:String, timestamp:Double, payload: String, icon: String )] = []
    private var userTimelineReference: DatabaseReference!
    
    
    @IBOutlet weak var newsFeedTable: UITableView!{
        didSet{
            newsFeedTable.delegate = self
            newsFeedTable.dataSource = self
            newsFeedTable.register(TimelineCell.self, forCellReuseIdentifier: HomeViewController.timelineCellIdentifier)
            
            newsFeedTable.register(UINib(nibName: HomeViewController.timelineCellNibIdentifier, bundle: nil), forCellReuseIdentifier: HomeViewController.timelineCellIdentifier)
            
            newsFeedTable.rowHeight = UITableView.automaticDimension
            newsFeedTable.estimatedRowHeight = 150
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Home"
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
    
    //
    func updateTimelinefromDB(){
        userTimelineReference.queryOrdered(byChild: "timestamp").observeSingleEvent(of: .value, with: {snapshot in
            var count = 0
            var tmpPosts:[(key: String, type:String, timestamp:Double, payload: String, icon:String )] = []
        
            for child in snapshot.children{
                if let timeLineSnap = child as? DataSnapshot,
                    let value = timeLineSnap.value as? [String:AnyObject],
                    let type = value["type"] as? String,
                    let timestamp = value["timestamp"] as? Double,
                    let payload = value["payload"] as? String{
                    // Icon could be empty
                    var tmpIcon = ""
                    if let icon = value["icon"] as? String{tmpIcon = icon}
                    
                    tmpPosts.append((key: timeLineSnap.key, type: type, timestamp: timestamp, payload: payload, icon: tmpIcon))
                    
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK : Table stuff
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
        if let postCell = newsFeedTable.dequeueReusableCell(withIdentifier: HomeViewController.timelineCellIdentifier, for: indexPath) as? TimelineCell{
            setupPostCell(cell: postCell, type: somePost[indexPath.row].type, timestamp: somePost[indexPath.row].timestamp, payload: somePost[indexPath.row].payload, icon: somePost[indexPath.row].icon)
            
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
        // Reseting the angle before reuse
        //cell.iconLabel.transform = CGAffineTransform(rotationAngle: CGFloat(0.0))
        
        // Date stuff
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short //Set time style
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
}
