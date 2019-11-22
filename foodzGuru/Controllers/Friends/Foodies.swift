//
//  Friends.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 12.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class Foodies: UIViewController {
    private static let segueToFoodie = "showFoodie"
    private static let foodieCell = "foodieCell"
    private let timelineCellIdentifier = "TimelineCell"
    private let timelineCellNibIdentifier = "TimelineCell"
    
    private var user:User!
    private var friendsSearchController: UISearchController!
    private var filteredFoodies: [UserDetails] = []
    private var myFoodiesList: [UserDetails] = []
    private var emptyListFlag = false
    
    // Handles
    private var userFollowingHandle: UInt!
    private var userDataHandle:[(handle: UInt, dbPath:String)] = []
    
    var isSearchBarEmpty: Bool {
      return friendsSearchController.searchBar.text?.isEmpty ?? true
    }
    var isFiltering: Bool {
      return friendsSearchController.isActive && !isSearchBarEmpty
    }
    
    // The user to be passed on
    private var visitedUserData: UserDetails!

    @IBOutlet weak var myFoodies: UITableView!{
        didSet{
            myFoodies.delegate = self
            myFoodies.dataSource = self
            // register cells
            myFoodies.register(UINib(nibName: self.timelineCellNibIdentifier, bundle: nil), forCellReuseIdentifier: self.timelineCellNibIdentifier)
            
            myFoodies.rowHeight = UITableView.automaticDimension
            myFoodies.estimatedRowHeight = 150
            
            // For avoiding drawing the extra lines
            myFoodies.tableFooterView = UIView()
            
            
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    
    // MARK: Ad stuff
    @IBOutlet weak var adView: UIView!
    private var bannerView: GADBannerView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            self.getFriends()
        }
        
        // Configure the banner ad
        configureBannerAd()
        
        if let indexPath = myFoodies.indexPathForSelectedRow {
            myFoodies.deselectRow(at: indexPath, animated: true)
        }        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the search controller
        friendsSearchController = UISearchController(searchResultsController: nil)
        friendsSearchController.delegate = self
        friendsSearchController.searchResultsUpdater = self
        friendsSearchController.hidesNavigationBarDuringPresentation = false
        friendsSearchController.obscuresBackgroundDuringPresentation = false
        friendsSearchController.searchBar.placeholder = "Search for More Foodies"
        friendsSearchController.searchBar.autocapitalizationType = .none
        navigationItem.titleView = friendsSearchController.searchBar
        definesPresentationContext = true

        myFoodies.separatorColor = SomeApp.themeColor
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SomeApp.dbUserFollowing.child(user.uid).removeObserver(withHandle: userFollowingHandle)
        
        // Destroy banner
        bannerView.delegate = nil
        
        for (handle,dbPath) in userDataHandle{
            SomeApp.dbUserData.child(dbPath).removeObserver(withHandle: handle)
        }
        
    }
    
    //Dynamic header height.  Snippet from : https://useyourloaf.com/blog/variable-height-table-view-header/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = myFoodies.tableHeaderView else {
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
            myFoodies.tableHeaderView = headerView

            // Now that the table view header is sized correctly have
            // the table view redo its layout so that the cells are
            // correcly positioned for the new header size.
            // This only seems to be necessary on iOS 9.
            myFoodies.layoutIfNeeded()
        }
    }
    
    // MARK: Initial: get my friends
    func getFriends(){
        // Outer : get the top users from the app
        userFollowingHandle = SomeApp.dbUserFollowing.child(user.uid).observe(.value, with: {snapshot in
            var tmpUserDetails:[UserDetails] = []
            var count = 0
            
            if !snapshot.exists(){
                // If we don't have friends, mark the empty list flag
                self.emptyListFlag = true
                self.myFoodies.reloadData()
            }else{
                // [Start] if the snapshot exists, then read!
                self.emptyListFlag = false
                for child in snapshot.children{
                    if let childSnapshot = child as? DataSnapshot{
                        self.userDataHandle.append((handle:
                            SomeApp.dbUserData.child(childSnapshot.key).observe(.value, with: { userDataSnap in
                            tmpUserDetails.append(UserDetails(snapshot: userDataSnap)!)
                            
                            // Use the trick
                            count += 1
                            if count == snapshot.childrenCount {
                                self.myFoodiesList = tmpUserDetails
                                self.myFoodies.reloadData()
                            }
                            }), dbPath:childSnapshot.key))
                    }
                }
                // [End] if the snapshot exists, then read!
            }
        })
    }
    
    
    // MARK: Search
    func filterContentForSearchText(_ searchText:String, scope: String = "ALL"){
        print(searchText)
        SomeApp.dbUserData.queryOrdered(byChild: "nickname").queryStarting(atValue: searchText).queryLimited(toFirst: 30).observeSingleEvent(of: .value, with: {snapshot in
            var tmpUserDetails:[UserDetails] = []
            var count = 0
            
            for child in snapshot.children{
                if let userDataSnapshot = child as? DataSnapshot{
                    
                    tmpUserDetails.append(UserDetails(snapshot: userDataSnapshot)!)
                    //print(userDataSnapshot)
                    // Use the trick
                    count += 1
                    if count == snapshot.childrenCount{
                        self.filteredFoodies = tmpUserDetails
                        self.myFoodies.reloadData()
                    }
                }
            }
        })
    }

    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier{
        case Foodies.segueToFoodie:
            if isFiltering && filteredFoodies.count > 0{
                return true
            }
            if !isFiltering && myFoodiesList.count > 0{
                return true
            }
            else{
                return false
            }
        default: return false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Segue
        switch segue.identifier {
        case Foodies.segueToFoodie:
            if let seguedController = segue.destination as? MyRanks,
                let senderCell = sender as? HomeCellWithImage,
                let indexNumber = myFoodies.indexPath(for: senderCell){
                if isFiltering{
                    seguedController.calledUser = filteredFoodies[indexNumber.row]
                }
                else{
                    seguedController.calledUser = myFoodiesList[indexNumber.row]
                }
                
            }
        default: break
        }
    }


}

// MARK: table stuff
extension Foodies:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard myFoodiesList.count > 0 else { return 1}
        
        if isFiltering{
            return filteredFoodies.count
        }
        else if emptyListFlag == true {
            return 1
        }else{
            return myFoodiesList.count
        }
        
       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard myFoodiesList.count > 0 || emptyListFlag else{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Getting Foodies' data"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            return cell
        }
        
        // Filtering
        if isFiltering,
            let cell = myFoodies.dequeueReusableCell(withIdentifier: Foodies.foodieCell) as? HomeCellWithImage{
            cell.titleLabel.text = filteredFoodies[indexPath.row].nickName
            cell.bodyLabel.text = filteredFoodies[indexPath.row].bio + " " //The space is important
            cell.cellImage.sd_setImage(
                with: URL(string: filteredFoodies[indexPath.row].photoURLString),
                placeholderImage: UIImage(named: "userdefault"),
                options: [],
                completed: nil)
            cell.dateLabel.text = ""
            
            return cell
        }
            // Start] Empty table
            
        else if emptyListFlag,
            let postCell = myFoodies.dequeueReusableCell(withIdentifier: self.timelineCellIdentifier, for: indexPath) as? TimelineCell{
            postCell.dateLabel.text = ""
            postCell.titleLabel.text = "You are not following anyone yet!"
            postCell.bodyLabel.text =  "Use the search bar to find foodies."
            postCell.iconLabel.text = "💬"
            
            return postCell
        }// [End] Empty table
        
        // [Start] Normal table
        else if let cell = myFoodies.dequeueReusableCell(withIdentifier: Foodies.foodieCell) as? HomeCellWithImage{
            cell.titleLabel.text = myFoodiesList[indexPath.row].nickName
            cell.bodyLabel.text = myFoodiesList[indexPath.row].bio + " " // the extra space is important!
            cell.cellImage.sd_setImage(
                with: URL(string: myFoodiesList[indexPath.row].photoURLString),
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


// MARK: Search stuff
// This extension will go to the new view controller
extension Foodies: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        
        let barText = friendsSearchController.searchBar.text!
        // Filter for alphanumeric characters
        let pattern = "[^A-Za-z0-9]+"
        let textToSearch = barText.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        guard textToSearch.count >= 3 else { return }
        filterContentForSearchText(textToSearch.lowercased())
    }
}

extension Foodies: UISearchControllerDelegate{
    func didDismissSearchController(_ searchController: UISearchController) {
        myFoodies.reloadData()
    }
}


// MARK: Ad stuff
extension Foodies: GADBannerViewDelegate{
    // My func
    private func configureBannerAd(){
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
    }
    
    // delegate funcs
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
    
    // Tells the delegate an ad request failed.
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
