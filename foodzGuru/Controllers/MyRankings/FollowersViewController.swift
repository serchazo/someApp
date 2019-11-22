//
//  FollowersViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 22.11.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds
import SDWebImage

enum listType{
    case Following
    case Followers
}

class FollowersViewController: UIViewController {
    
    var calledUser:UserDetails?
    var whatList:listType!
    
    private let timelineCellIdentifier = "TimelineCell"
    private let timelineCellNibIdentifier = "TimelineCell"
    private let foodieCell = "foodieCell"
    private let segueFoodie = "segueShowFoodie"
    
    private var user:User!
    private var follows: [UserDetails] = []
    private var emptyListFlag = false
    
    // Outlets
    @IBOutlet weak var followTableView: UITableView!{
        didSet{
            followTableView.delegate = self
            followTableView.dataSource = self
            
            // register cells
            followTableView.register(UINib(nibName: self.timelineCellNibIdentifier, bundle: nil), forCellReuseIdentifier: self.timelineCellIdentifier)
            
            followTableView.rowHeight = UITableView.automaticDimension
            followTableView.estimatedRowHeight = 150
            
            // For avoiding drawing the extra lines
            followTableView.tableFooterView = UIView()
        }
    }
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.text = nil
        }
    }
    
    
    // MARK: Timeline funcs
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            //
            if self.calledUser == nil{
                self.getFriends(userId: user.uid)
            }else{
                self.getFriends(userId: self.calledUser!.key)
            }
            
        }
        
        // Configure the banner ad
        //configureBannerAd()
        
        if let indexPath = followTableView.indexPathForSelectedRow {
            followTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        followTableView.separatorColor = SomeApp.themeColor
        
        switch whatList{
        case .Followers:
            self.navigationItem.title = "followers"
        case .Following:
            self.navigationItem.title = "following"
        default: break
        }
        
    }
    
    //Dynamic header height.  Snippet from : https://useyourloaf.com/blog/variable-height-table-view-header/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = followTableView.tableHeaderView else {
            return
        }

        // The table view header is created with the frame size set in
        // the Storyboard. Calculate the new size and reset the header
        // view to trigger the layout.
        // Calculate the minimum height of the header view that allows
        // the text label to fit its preferred width.
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height

            // Need to set the header view property of the table view
            // to trigger the new layout. Be careful to only do this
            // once when the height changes or we get stuck in a layout loop.
            followTableView.tableHeaderView = headerView

            // Now that the table view header is sized correctly have
            // the table view redo its layout so that the cells are
            // correcly positioned for the new header size.
            // This only seems to be necessary on iOS 9.
            followTableView.layoutIfNeeded()
        }
    }
    
    // MARK: Get my friends
    private func getFriends(userId: String){
        var dbRef = DatabaseReference()
        switch whatList {
        case .Followers:
            dbRef = SomeApp.dbUserFollowers
        case .Following:
            dbRef = SomeApp.dbUserFollowing
        default: break
        }
        
        var tmpUserDetails:[UserDetails] = []
        var count = 0
        
        dbRef.child(userId).observeSingleEvent(of: .value, with: {snapshot in
            // If we don't have friends, mark the empty list flag
            if !snapshot.exists(){
                self.emptyListFlag = true
                self.followTableView.reloadData()
            }
            // If I have friends
            self.emptyListFlag = false
            for child in snapshot.children{
                if let childSnapshot = child as? DataSnapshot{
                    SomeApp.dbUserData.child(childSnapshot.key).observe(.value, with: { userDataSnap in
                        tmpUserDetails.append(UserDetails(snapshot: userDataSnap)!)
                        
                        // Use the trick
                        count += 1
                        if count == snapshot.childrenCount {
                            self.follows = tmpUserDetails
                            self.followTableView.reloadData()
                        }
                    })
                }
            }
            //
        })
    }
    
    //
    private func emptyFollowTitle() -> String{
        var returnText = ""
        switch whatList{
        case .Followers:
            returnText = "You don't have any followers yet."
            if calledUser != nil{
                returnText = "\(calledUser!.nickName) doesn't have any followers yet."
            }
        case .Following:
            returnText = "You are not following anyone yet."
            if calledUser != nil{
                returnText = "\(calledUser!.nickName) is not following anyone yet."
            }
        default: break
        }
        return returnText
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        //Segue
        switch segue.identifier {
        case self.segueFoodie:
            if let seguedController = segue.destination as? MyRanks,
                let senderCell = sender as? HomeCellWithImage,
                let indexNumber = followTableView.indexPath(for: senderCell){
                seguedController.calledUser = follows[indexNumber.row]
            }
        default: break
        }
    }
}

// MARK: Table stuff
extension FollowersViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard follows.count > 0 else { return 1}
        
        if emptyListFlag == true {
            return 1
        }else{
            return follows.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard follows.count > 0 || emptyListFlag else{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Getting Foodies' data"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            return cell
        }
        
        // Start] Empty table
        if emptyListFlag,
            let postCell = followTableView.dequeueReusableCell(withIdentifier: self.timelineCellIdentifier, for: indexPath) as? TimelineCell{
            postCell.dateLabel.text = ""
            postCell.titleLabel.text = emptyFollowTitle()
            postCell.bodyLabel.text =  "Come back soon to see the list!"
            postCell.iconLabel.text = "💬"
            
            return postCell
        }
        // [End] Empty table
        
        // [Start] Normal table
        else if let cell = followTableView.dequeueReusableCell(withIdentifier: foodieCell) as? HomeCellWithImage{
            cell.titleLabel.text = follows[indexPath.row].nickName
            cell.bodyLabel.text = follows[indexPath.row].bio + " " // the extra space is important!
            cell.cellImage.sd_setImage(
                with: URL(string: follows[indexPath.row].photoURLString),
                placeholderImage: UIImage(named: "userdefault"),
                options: [],
                completed: nil)
            
            cell.dateLabel.text = ""
            
            return cell
        }// [End] Normal table
        else{
            fatalError("Can't create cell")
        }
    }
    
}
