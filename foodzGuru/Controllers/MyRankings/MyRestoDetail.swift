//
//  MyRestoDetail.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 11.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import SafariServices
import MapKit
import Firebase
import NotificationBannerSwift

class MyRestoDetail: UIViewController {
    private static let screenSize = UIScreen.main.bounds.size
    private static let segueToMap = "showMap"
    
    private let commentCell = "CommentCell"
    private let commentCellNibId = "CommentCell"
    
    private var user:User!
    private var dbRestoReviews:DatabaseReference!
    private var commentArray:[Comment] = []
    private var firstCommentFlag:Bool = false
    
    // We get this var from the preceding ViewController 
    var currentResto: Resto!
    var currentCity: City!
    var currentFood: FoodType!
    var dbMapReference: DatabaseReference!
    
    // Variable to pass to map Segue
    private var currentRestoMapItem : MKMapItem!
    private var OKtoPerformSegue = true
    
    @IBOutlet weak var restoNameLabel: UILabel!
    @IBOutlet weak var addToRankButton: UIButton!
    
    // MARK: Add to ranking action
    @IBAction func addToRankAction(_ sender: Any) {
        // Check if the user has this food already
        let dbPath = user.uid + "/" + currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/" + currentFood.key
        
        SomeApp.dbUserRankings.child(dbPath).observeSingleEvent(of: .value, with: {snapshot in
            // Le ranking doesn't exist
            if !snapshot.exists(){
                let alert = UIAlertController(title: "Create ranking",
                                              message: "You don't have this ranking, create and add restorant?",
                                              preferredStyle: .alert)
                let createAction = UIAlertAction(title: "Create", style: .default){ _ in
                    // If we don't have the ranking, we add it to Firebase
                    SomeApp.newUserRanking(userId: self.user.uid, city: self.currentCity, food: self.currentFood)
                    // then add to ranking
                    SomeApp.addRestoToRanking(userId: self.user.uid,
                                              resto: self.currentResto,
                                              mapItem: self.currentRestoMapItem,
                                              forFood: self.currentFood,
                                              foodId: self.currentFood.key,
                                              city: self.currentCity)
                    // Show confirmation banner
                    self.bannerStuff()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(createAction)
                alert.addAction(cancelAction)
                
            }
            // The ranking exists
            else{
                // Add to ranking sans autre
                SomeApp.addRestoToRanking(userId: self.user.uid,
                                          resto: self.currentResto,
                                          mapItem: self.currentRestoMapItem,
                                          forFood: self.currentFood,
                                          foodId: self.currentFood.key,
                                          city: self.currentCity)
                self.bannerStuff()
            }
        })
    }
    
    private func bannerStuff(){
        // Show confirmation banner
        let tmpView = UILabel(frame: CGRect(x: 0, y: 0, width: FoodzLayout.screenSize.width, height: 120))
        tmpView.backgroundColor = .white
        tmpView.textAlignment = .center
        tmpView.textColor = SomeApp.themeColor
        tmpView.font = UIFont.preferredFont(forTextStyle: .headline)
        tmpView.text = "\(self.currentFood.icon) \(self.currentResto.name) added to your \(self.currentFood.name) places!"
        
        let banner = NotificationBanner(customView: tmpView)
        banner.show()
        
        // clean up
        addToRankButton.isHidden = true
        addToRankButton.isEnabled = false
    }
    
    
    @IBOutlet weak var restoDetailTable: UITableView!{
        didSet{
            restoDetailTable.delegate = self
            restoDetailTable.dataSource = self
            restoDetailTable.register(UINib(nibName: commentCellNibId, bundle: nil), forCellReuseIdentifier: commentCell)
            restoDetailTable.rowHeight = UITableView.automaticDimension
            restoDetailTable.estimatedRowHeight = 150
            
        }
    }
    
    // MARK: Timeline funcs
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = restoDetailTable.indexPathForSelectedRow {
            restoDetailTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dbPath = currentCity.country+"/"+currentCity.state+"/"+currentCity.key+"/"+currentResto.key
        dbMapReference = SomeApp.dbRestoAddress.child(dbPath)
        dbRestoReviews = SomeApp.dbRestoReviews.child(dbPath)
        
        // 1. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // 2. Once we have the user we configure the header
            self.configureHeader()
        }
        
        // Get the comments from the DB
        getReviewsFromDB()
        
        // Get the map from the database
        self.dbMapReference.observeSingleEvent(of: .value, with: {snapshot in
            if let value = snapshot.value as? [String: String],
                let mapString = value["address"]{
                
                let decoder = JSONDecoder()
                do{
                    let tempMapArray = try decoder.decode(RestoMapArray.self, from: mapString.data(using: String.Encoding.utf8)!)
                    self.currentRestoMapItem = tempMapArray.restoMapItem
                }catch{
                    self.OKtoPerformSegue = false
                    print(error.localizedDescription)
                }
                
            }else{
                self.OKtoPerformSegue = false
            }
        })
    }
    
    // Configure header
    private func configureHeader(){
        restoNameLabel.text = currentResto.name
        
        
        let dbPath = user.uid + "/" + currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/" + currentFood.key + "/" + currentResto.key
        // Check if the user has this resto in his/her ranking already
        SomeApp.dbUserRankingDetails.child(dbPath).observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.exists(){
                self.addToRankButton.isEnabled = false
                self.addToRankButton.isHidden = true
                self.addToRankButton = nil
            }else{
                FoodzLayout.configureButton(button: self.addToRankButton)
                self.addToRankButton.setTitle("Add to my Foodz", for: .normal)
            }
        })
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch(segue.identifier){
        case MyRestoDetail.segueToMap:
            if let seguedVC = segue.destination as? MyRestoMap{
                seguedVC.mapItems = [currentRestoMapItem]
            }
        default:break
        }
    }
    
    //
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return OKtoPerformSegue
    }
}

// MARK: Table stuff

extension MyRestoDetail : UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        // test if the table is the Add Comment pop-up
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // the normal table
        switch(section){
        case 0: return 4
        case 1:
            guard commentArray.count > 0 else {return 1}
            return commentArray.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // The normal table
        if indexPath.section == 0 {
            if indexPath.row == 0{
                let cell = restoDetailTable.dequeueReusableCell(withIdentifier: "AddressCell")
                cell!.textLabel?.textColor = .black
                cell!.textLabel?.text = "Address"
                cell!.detailTextLabel?.text = currentResto.address
                return cell!
            }else if indexPath.row == 1 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.textColor = .black
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Phone"
                cell.detailTextLabel?.text = currentResto.phoneNumber
                return cell
            }else if indexPath.row == 2 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.textColor = .black
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "URL"
                if currentResto.url != nil{
                    cell.detailTextLabel?.text = currentResto.url!.absoluteString
                }else{
                    cell.detailTextLabel?.text = ""
                }
                return cell
            }else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                // Title
                cell.selectionStyle = .none
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = SomeApp.themeColor
                cell.textLabel?.text = "Reviews"
                
                return cell
            }
        }else{
            guard commentArray.count > 0 else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Loading comments"
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            
            // Comment cell
            if let postCell = restoDetailTable.dequeueReusableCell(withIdentifier: commentCell, for: indexPath) as? CommentCell{
                
                // Date stuff
                let date = Date(timeIntervalSince1970: TimeInterval(commentArray[indexPath.row].timestamp/1000)) // in milliseconds
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
                dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
                let localDate = dateFormatter.string(from: date)
                
                // Then
                postCell.dateLabel.text = localDate
                postCell.titleLabel.text = commentArray[indexPath.row].username
                postCell.bodyLabel.text = commentArray[indexPath.row].text
                
                // Buttons
                postCell.likeButton.setTitleColor(SomeApp.themeColor, for: .normal)
                postCell.likeButton.setTitle("Like", for: .normal)
                postCell.dislikeButton.setTitleColor(SomeApp.themeColor, for: .normal)
                postCell.dislikeButton.setTitle("Dislike", for: .normal)
                
                // If it's not the first comment, then we can add some actions
                if !firstCommentFlag{
                    postCell.likeAction = {(cell) in
                        print("Like!")
                    }
                    // Dislike
                    postCell.dislikeAction = {(cell) in
                        print("Dislike!")
                    }
                }
                postCell.selectionStyle = .none
                
                return postCell
            }else{
                fatalError("Couln't create cell")
            }
            
        }
    }
    
    // MARK: Actions
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         if indexPath.section == 0{
             if indexPath.row == 1{
                 let tmpModifiedPhone = "tel://" + currentResto.phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                 if let number = URL(string: tmpModifiedPhone){
                     UIApplication.shared.open(number)
                 }else{
                     // Can't call
                     let alert = UIAlertController(
                         title: "Can't call",
                         message: "Please try another restaurant.",
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
             }else if indexPath.row == 2{
                 // URL clicket, open the web page
                 if currentResto.url != nil{
                     let config = SFSafariViewController.Configuration()
                     config.entersReaderIfAvailable = true
                     let vc = SFSafariViewController(url: currentResto.url, configuration: config)
                     vc.preferredControlTintColor = UIColor.white
                     vc.preferredBarTintColor = SomeApp.themeColorOpaque
                     present(vc, animated: true)
                 }
             }
         }
     }
    
    //
    
    
    

}

    // MARK: objc funcs
extension MyRestoDetail{
    // MARK: Get comments from DB
    func getReviewsFromDB(){
        var tmpCommentArray:[Comment] = []
        var count = 0
       
        // Get from database
        dbRestoReviews.observeSingleEvent(of: .value, with: {snapshot in
            // If there are no comments for the restaurant, create a dummy comment
            guard snapshot.exists() else{
                let tmpTimestamp = NSDate().timeIntervalSince1970 * 1000
                self.firstCommentFlag = true
                let tmpText = "Be the first to add a comment of \(self.currentResto.name)!"
                tmpCommentArray.append(Comment(username: "This could be you!", restoname: self.currentResto.name, text: tmpText, timestamp:  tmpTimestamp, title: "No comments yet"))
                self.commentArray = tmpCommentArray
                self.restoDetailTable.reloadData()
                return
            }
            
            for child in snapshot.children{
                if let commentRestoSnapshot = child as? DataSnapshot,
                    let value = commentRestoSnapshot.value as? [String:Any],
                    let body = value["text"] as? String,
                    let timestamp = value["timestamp"] as? Double,
                    let username = value["username"] as? String {
                    
                    var tmpTitle = "Comment"
                    if let title = value["title"] as? String,
                        title != ""{
                        tmpTitle = title
                    }
                    
                    tmpCommentArray.append(Comment(username: username, restoname: self.currentResto.name, text: body, timestamp: timestamp, title: tmpTitle))
                    //Use the trick
                    count += 1
                    if count == snapshot.childrenCount{
                        self.commentArray = tmpCommentArray
                        self.restoDetailTable.reloadData()
                    }
                    
                    
                }
            }
        })
    }
}

// MARK: UITextViewDelegate

extension MyRestoDetail: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 2500
    }
    
}
