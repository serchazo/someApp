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
    
    private var user:User!
    private var friendsSearchController: UISearchController!
    private var filteredFoodies: [String] = []
    private var myFoodiesList: [UserDetails] = []
    
    // The user to be passed on
    private var visitedUserData: UserDetails!

    @IBOutlet weak var myFoodies: UITableView!{
        didSet{
            myFoodies.delegate = self
            myFoodies.dataSource = self
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    
    // MARK: Ad stuff
    @IBOutlet weak var adView: UIView!
    private var bannerView: GADBannerView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if let indexPath = myFoodies.indexPathForSelectedRow {
            myFoodies.deselectRow(at: indexPath, animated: true)
        }        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            self.getRecommendedUsers()
        }
        
        // Setup the search controller
        friendsSearchController = UISearchController(searchResultsController: nil) //to be modified for final
        friendsSearchController.searchResultsUpdater = self
        friendsSearchController.hidesNavigationBarDuringPresentation = false
        friendsSearchController.obscuresBackgroundDuringPresentation = false
        friendsSearchController.searchBar.placeholder = "Search for More Foodies"
        navigationItem.titleView = friendsSearchController.searchBar
        definesPresentationContext = true
        
        // Configure the banner ad
        configureBannerAd()

    }
    
    // MARK : the recommended list
    func getRecommendedUsers(){
        // Outer : get the top users from the app
        SomeApp.dbUserFollowing.child(user.uid).observe(.value, with: {snapshot in
            var tmpUserDetails:[UserDetails] = []
            var count = 0
            
            // Inner: get the user data
            for child in snapshot.children{
                if let childSnapshot = child as? DataSnapshot{
                    SomeApp.dbUserData.child(childSnapshot.key).observe(.value, with: { userDataSnap in
                        // We don't add ourselve to the suggested
                        if userDataSnap.exists(){
                            if(childSnapshot.key != self.user.uid){
                                // No for current user
                                tmpUserDetails.append(UserDetails(snapshot: userDataSnap)!)
                            }
                        }
                        // Use the trick
                        count += 1
                        if count == snapshot.childrenCount {
                            self.myFoodiesList = tmpUserDetails
                            self.myFoodies.reloadData()
                        }
                    })
                    
                    //
                    
                    
                }
            }
        })
    }
    
    
    // MARK : methods
    func searchBarIsEmpty() -> Bool {
        //Returns true if the search text is empty or nil
        return friendsSearchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText:String, scope: String = "ALL"){
        print(searchText)
        SomeApp.dbUserData.queryOrdered(byChild: "nickname").queryStarting(atValue: searchText).queryLimited(toFirst: 30).observeSingleEvent(of: .value, with: {snapshot in
            var count = 0
            for child in snapshot.children{
                if let userDataSnapshot = child as? DataSnapshot{
                    
                    print(userDataSnapshot)
                    // Use the trick
                    count += 1
                    if count == snapshot.childrenCount{
                        self.myFoodies.reloadData()
                    }
                }
            }
        })
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Segue
        switch segue.identifier {
        case Foodies.segueToFoodie:
            if let seguedController = segue.destination as? MyRanks,
                let senderCell = sender as? HomeCellWithImage,
                let indexNumber = myFoodies.indexPath(for: senderCell){
                seguedController.calledUser = myFoodiesList[indexNumber.row]
            }
        default: break
        }
    }


}

// MARK: table stuff

extension Foodies:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard myFoodiesList.count > 0 else { return 1}
        return myFoodiesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard myFoodiesList.count > 0 else{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Getting Foodies' data"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            return cell
        }
        
        if let cell = myFoodies.dequeueReusableCell(withIdentifier: Foodies.foodieCell) as? HomeCellWithImage{
            cell.titleLabel.text = myFoodiesList[indexPath.row].nickName
            cell.bodyLabel.text = myFoodiesList[indexPath.row].bio
            cell.cellImage.sd_setImage(
                with: URL(string: myFoodiesList[indexPath.row].photoURLString),
                placeholderImage: UIImage(named: "userdefault"),
                options: [],
                completed: nil)
            cell.dateLabel.text = ""
            
            return cell
        }else{
            fatalError("Can't create cell")
        }
        
    }
}


// MARK : search results updating, to allow the View controller to respond to the search bar
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
