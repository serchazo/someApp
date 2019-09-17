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
    
    // Instance variables
    private var user:User!
    private var somePost: [(key: String, type:String, timestamp:Int, payload: String )] = []
    private var userTimelineReference: DatabaseReference!
    
    
    @IBOutlet weak var newsFeedTable: UITableView!{
        didSet{
            newsFeedTable.delegate = self
            newsFeedTable.dataSource = self
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            var tmpPosts:[(key: String, type:String, timestamp:Int, payload: String )] = []
        
            for child in snapshot.children{
                if let timeLineSnap = child as? DataSnapshot,
                    let value = timeLineSnap.value as? [String:AnyObject],
                    let type = value["type"] as? String,
                    let timestamp = value["timestamp"] as? Int,
                    let payload = value["payload"] as? String{
                    tmpPosts.append((key: timeLineSnap.key, type: type, timestamp: timestamp, payload: payload))
                    
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
        let postCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        postCell.textLabel?.text = somePost[indexPath.row].payload
        return postCell
    }
    
    
}
