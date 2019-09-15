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
    private var posts:[String] = []
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
        userTimelineReference.observeSingleEvent(of: .value, with: {snapshot in
            for child in snapshot.children{
                print(child)
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = "Some news"
        return cell
    }
    
    
}
