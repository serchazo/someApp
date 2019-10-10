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
    private var recommendedFoodies: [UserDetails] = []
    
    // The user to be passed on
    private var visitedUserData: UserDetails!

    @IBOutlet weak var someTable: UITableView!{
        didSet{
            someTable.delegate = self
            someTable.dataSource = self
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
        friendsSearchController.searchBar.placeholder = "Search for Foodies"
        navigationItem.titleView = friendsSearchController.searchBar
        definesPresentationContext = true

    }
    
    // MARK : the recommended list
    func getRecommendedUsers(){
        // Outer : get the top users from the app
        SomeApp.dbUserNbFollowers.queryOrderedByValue().queryLimited(toFirst: 20).observeSingleEvent(of: .value, with: {snapshot in
            var tmpUserDetails:[UserDetails] = []
            var count = 0
            
            // Inner: get the user data
            for child in snapshot.children{
                if let childSnapshot = child as? DataSnapshot{
                    SomeApp.dbUserData.child(childSnapshot.key).observeSingleEvent(of: .value, with: { userDataSnap in
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
                            self.recommendedFoodies = tmpUserDetails
                            self.someTable.reloadData()
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
                        self.someTable.reloadData()
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
                let senderCell = sender as? UITableViewCell,
                let indexNumber = someTable.indexPath(for: senderCell){
                seguedController.calledUser = recommendedFoodies[indexNumber.row]
            }
        default: break
        }
    }


}

// MARK : table stuff

extension Foodies:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard recommendedFoodies.count > 0 else { return 1}
        return recommendedFoodies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard recommendedFoodies.count > 0 else{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Loading recommendations"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            return cell
        }
        let cell = someTable.dequeueReusableCell(withIdentifier: Foodies.foodieCell)
        cell?.textLabel?.text = recommendedFoodies[indexPath.row].nickName
        return cell!
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
