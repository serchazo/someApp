//
//  MyRestoDetail.swift
//  someApp
//
//  Created by Sergio Ortiz on 11.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import SafariServices
import MapKit
import Firebase

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
    var dbMapReference: DatabaseReference!
    
    // Variable to pass to map Segue
    private var currentRestoMapItem : MKMapItem!
    private var OKtoPerformSegue = true

    //For Edit the description swipe-up
    private var transparentView = UIView()
    private var addCommentTableView = UITableView()
    private var addCommentTextView = UITextView()
    
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
            
            // 2. Update the dbReference
            //self.dbCommentsPerUser = SomeApp.dbCommentsPerUser.child(user.uid)
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
        
        // Define the properties for the editDescription TableView
        addCommentTableView.delegate = self
        addCommentTableView.dataSource = self
        addCommentTableView.allowsSelection = false
        addCommentTextView.delegate = self
        
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
        if tableView == self.addCommentTableView {
            return 1
        }else{
            // the normal table
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // test if the table is the Add Comment pop-up
        if tableView == self.addCommentTableView {
            return 1
        }else{
            // the normal table
            switch(section){
            case 0: return 5
            case 1:
                guard commentArray.count > 0 else {return 1}
                return commentArray.count
            default: return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // test if the table is the Add Comment pop-up
        if tableView == self.addCommentTableView {
            return 450
        }else{
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // test if the table is the Add Comment pop-up
        if tableView == self.addCommentTableView {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            editCommentCell(cell: cell)
            return cell
        }else{
            // The normal table
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                    cell.textLabel?.textAlignment = .center
                    cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
                    cell.textLabel?.text = currentResto.name
                    cell.isUserInteractionEnabled = false
                    return cell
                }else if indexPath.row == 1{
                    let cell = restoDetailTable.dequeueReusableCell(withIdentifier: "AddressCell")
                    cell!.textLabel?.textColor = .black
                    cell!.textLabel?.text = "Address"
                    cell!.detailTextLabel?.text = currentResto.address
                    return cell!
                }else if indexPath.row == 2 {
                    let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                    cell.textLabel?.textColor = .black
                    cell.accessoryType = .disclosureIndicator
                    cell.textLabel?.text = "Phone"
                    cell.detailTextLabel?.text = currentResto.phoneNumber
                    return cell
                }else if indexPath.row == 3 {
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
                    // The button
                    let addCommentButton = UIButton(type: .custom)
                    addCommentButton.frame = CGRect(x: cell.frame.width/3, y: 5, width: cell.frame.width/2, height: cell.frame.height-10)
                    addCommentButton.backgroundColor = SomeApp.themeColor
                    addCommentButton.layer.cornerRadius = 20 //0.5 * addCommentButton.bounds.size.width
                    addCommentButton.layer.masksToBounds = true
                    addCommentButton.setTitle("Add Comment", for: .normal)
                    addCommentButton.addTarget(self, action: #selector(addComment), for: .touchUpInside)
                    
                    cell.selectionStyle = .none
                    cell.addSubview(addCommentButton)
                    
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
                    
                    return postCell
                }else{
                    fatalError("Couln't create cell")
                }

            }
        }
    }
    
    // Actions
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         if indexPath.section == 0{
             if indexPath.row == 2{
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
             }else if indexPath.row == 3{
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
}

    // MARK: objc funcs
extension MyRestoDetail{
    @objc
    func addComment(){
        // Create the frame
        let window = UIApplication.shared.keyWindow
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        transparentView.frame = self.view.frame
        window?.addSubview(transparentView)
        
        // Add the table
        addCommentTableView.frame = CGRect(
            x: 0,
            y: MyRestoDetail.screenSize.height,
            width: MyRestoDetail.screenSize.width,
            height: MyRestoDetail.screenSize.height * 0.9)
        window?.addSubview(addCommentTableView)
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickTransparentView))
        transparentView.addGestureRecognizer(tapGesture)
        
        // Cool "slide-up" animation when appearing
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0.7 //Start at 0, go to 0.5
                        self.addCommentTableView.frame = CGRect(
                            x: 0,
                            y: MyRestoDetail.screenSize.height - MyRestoDetail.screenSize.height * 0.9 ,
                            width: MyRestoDetail.screenSize.width,
                            height: MyRestoDetail.screenSize.height * 0.9)
                        self.addCommentTextView.becomeFirstResponder()
                    },
                       completion: nil)
    }
    
    // Update the model when the button is pressed
    @objc
    func doneUpdating(){
        print("todo")
        /*
        let timestamp = NSDate().timeIntervalSince1970
        let comment = Comment(userid: user.uid, restoid: currentResto.key, text: addCommentTextView.text, timestamp: timestamp)
        
        let tempCommentRef = dbCommentReference.childByAutoId()
        tempCommentRef.setValue(comment.toAnyObject())
        let tempRestoCommentRef = dbCommentsPerResto.child(tempCommentRef.key!)
        tempRestoCommentRef.setValue(timestamp)
        let tempUserCommentRef = dbCommentsPerUser.child(tempCommentRef.key!)
        tempUserCommentRef.setValue(timestamp)
        */
        
        //Close the view
        onClickTransparentView()
        getReviewsFromDB()
    }
    
    //Disappear!
    @objc func onClickTransparentView(){
        // Animation when disapearing
        
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0 //Start at value above, go to 0
                        self.addCommentTableView.frame = CGRect(
                            x: 0,
                            y: MyRestoDetail.screenSize.height ,
                            width: MyRestoDetail.screenSize.width,
                            height: MyRestoDetail.screenSize.height * 0.9)
                        self.addCommentTextView.resignFirstResponder()
        },
                       completion: nil)
    }
    
    // MARK: Setup cells
    // The comment cell
    func editCommentCell(cell: UITableViewCell){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: MyRestoDetail.screenSize.width, height: SomeApp.titleFont.lineHeight + 20 ))
        
        //let textColor = UIColor.white
        titleLabel.textColor = SomeApp.themeColor
        titleLabel.font = SomeApp.titleFont
        titleLabel.textAlignment = .center
        titleLabel.text = "My comment for \(currentResto.name)"
        
        // set up the TextField.  This var is defined in the class to take the value later
        addCommentTextView.frame = CGRect(x: 8, y: SomeApp.titleFont.lineHeight + 40, width: cell.frame.width - 16, height: 200)
        addCommentTextView.textColor = UIColor.gray
        addCommentTextView.font = UIFont.preferredFont(forTextStyle: .body)
        addCommentTextView.text = "Write your comment."
        addCommentTextView.isScrollEnabled = true
        addCommentTextView.keyboardType = UIKeyboardType.default
        addCommentTextView.allowsEditingTextAttributes = true
        
        let doneButton = UIButton(type: .custom)
        doneButton.frame = CGRect(x: MyRestoDetail.screenSize.width * 3/4, y: 250, width: 70, height: 70)
        doneButton.backgroundColor = SomeApp.themeColor
        doneButton.layer.cornerRadius = 0.5 * doneButton.bounds.size.width
        doneButton.layer.masksToBounds = true
        doneButton.setTitle("Done!", for: .normal)
        doneButton.addTarget(self, action: #selector(doneUpdating), for: .touchUpInside)
        
        cell.selectionStyle = .none
        cell.addSubview(titleLabel)
        cell.addSubview(addCommentTextView)
        cell.addSubview(doneButton)
    }
    
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
