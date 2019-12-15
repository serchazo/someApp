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

protocol MyRestoDelegate: class{
    func myRestoReceiveResto(currentResto: Resto)
}

class MyRestoDetail: UIViewController {
    private static let screenSize = UIScreen.main.bounds.size
    private static let segueToMap = "showMap"
    
    private let addressCellId = "AddressCell"
    private let commentCell = "CommentCell"
    private let commentCellNibId = "CommentCell"
    private let editReviewCell = "EditReviewCell"
    
    private var user:User!
    private var dbRestoReviews:DatabaseReference!
    private var commentArray:[Comment] = []
    private var restoReviewLiked:[Bool] = []
    private var restoReviewsLikeNb:[Int] = []
    private var firstCommentFlag:Bool = false
    private var restoInRankingFlag:Bool = false
    
    // MARK: Broadcast messages
    weak var delegate: MyRestoDelegate?
    
    // Get segue-r
    enum MyRestoSeguer {
        case ThisRankingMy
        case ThisRankingVisitor
        case BestRestos
    }
    
    // We get this var from the preceding ViewController 
    var currentResto: Resto!
    var currentCity: City!
    var currentFood: FoodType!
    var dbMapReference: DatabaseReference!
    var seguer:MyRestoSeguer!
    
    // Variable to pass to map Segue
    private var currentRestoMapItem : MKMapItem!
    private var OKtoPerformSegue = true
    
    //Handles
    private var restoReviewsLikesHandle:[(handle: UInt, dbPath:String)] = []
    private var restoReviewsLikesNbHandle:[(handle: UInt, dbPath:String)]  = []
    private var userRankingDetailsHandle:[(handle: UInt, dbPath:String)]  = []
    
    //For Edit Review swipe-up
    private var editReviewTransparentView = UIView()
    private var editReviewTableView = UITableView()
    
    // MARK: Ad stuff
    private let adsToLoad = 5 //The number of native ads to load
    private var adsLoadedIndex = 0 // to count the ads we are loading
       
    private var nativeAds = [GADUnifiedNativeAd]() /// The native ads.
    private var adLoader: GADAdLoader!  /// The ad loader that loads the native ads.
    private let adFrequency = 5
    
    private var bannerView: GADBannerView!
    
    @IBOutlet weak var restoNameLabel: UILabel!
    @IBOutlet weak var addToRankButton: UIButton!
    
    @IBOutlet weak var foodIcon: UILabel!
    @IBOutlet weak var adView: UIView!
    
    // MARK: Add to ranking action
    @IBAction func addToRankAction(_ sender: Any) {
        addRestoToRanking()
    }
    
    private func bannerStuff(){
        // Show confirmation banner
        let tmpView = UILabel(frame: CGRect(x: 0, y: 0, width: FoodzLayout.screenSize.width, height: 120))
        tmpView.backgroundColor = .white
        tmpView.textAlignment = .center
        tmpView.textColor = SomeApp.themeColor
        tmpView.font = UIFont.preferredFont(forTextStyle: .headline)
        tmpView.text = MyStrings.bannerTitle.localized(arguments: self.currentFood.icon, self.currentResto.name, self.currentFood.name)
        
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
            restoDetailTable.register(UINib(nibName: "UnifiedNativeAdCell", bundle: nil),
            forCellReuseIdentifier: "UnifiedNativeAdCell")
        }
    }
    
    // MARK: Timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // 2. Verify if the current resto is in the users ranking
            let dbPath = user.uid + "/" + self.currentCity.country + "/" + self.currentCity.state + "/" + self.currentCity.key + "/" + self.currentFood.key + "/" + self.currentResto.key
            
            self.userRankingDetailsHandle.append((handle: SomeApp.dbUserRankingDetails.child(dbPath).observe(.value, with: {snapshot in
                self.restoInRankingFlag = snapshot.exists()
                // Configure the header
                self.configureHeader()
            }),dbPath: dbPath))
            
            // Get the comments from the DB
            self.getReviewsFromDB()
        }
        
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
        
        if let indexPath = restoDetailTable.indexPathForSelectedRow {
            restoDetailTable.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dbPath = currentCity.country+"/"+currentCity.state+"/"+currentCity.key+"/"+currentResto.key
        dbMapReference = SomeApp.dbRestoAddress.child(dbPath)
        let dbReviewsPath = currentCity.country+"/"+currentCity.state + "/" + currentCity.key + "/" + currentFood.key + "/" + currentResto.key
        dbRestoReviews = SomeApp.dbRestoReviews.child(dbReviewsPath)
        
        // Configure ads
        configureNativeAds()
        
        // Configure the banner ad
        configureBannerAd()
        
        // The editReviewTableView needs to be loaded only if it's my data
        editReviewTableView.delegate = self
        editReviewTableView.dataSource = self
        editReviewTableView.register(UINib(nibName: editReviewCell, bundle: nil), forCellReuseIdentifier: editReviewCell)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        for (handle,dbPath) in restoReviewsLikesHandle{
            SomeApp.dbRestoReviewsLikes.child(dbPath).removeObserver(withHandle: handle)
        }
        // Remove handles
        for (handle,dbPath) in restoReviewsLikesNbHandle{
            SomeApp.dbRestoReviewsLikesNb.child(dbPath).removeObserver(withHandle: handle)
        }
        for (handle,dbPath) in userRankingDetailsHandle{
            SomeApp.dbUserRankingDetails.child(dbPath).removeObserver(withHandle: handle)
        }
    }
    
    //Dynamic header height.  Snippet from : https://useyourloaf.com/blog/variable-height-table-view-header/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = restoDetailTable.tableHeaderView else {
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
            restoDetailTable.tableHeaderView = headerView

            // Now that the table view header is sized correctly have
            // the table view redo its layout so that the cells are
            // correcly positioned for the new header size.
            // This only seems to be necessary on iOS 9.
            restoDetailTable.layoutIfNeeded()
        }
    }
    
    // MARK: Configure header
    private func configureHeader(){
        restoNameLabel.text = currentResto.name
        
        // Food Icon
        foodIcon.layer.cornerRadius = 0.5 * foodIcon.frame.width
        foodIcon.layer.borderColor = SomeApp.themeColor.cgColor
        foodIcon.layer.borderWidth = 1.0
        foodIcon.layer.masksToBounds = true
        foodIcon.font = UIFont.preferredFont(forTextStyle: .largeTitle).withSize(50)
        foodIcon.text = currentFood.icon
        
        // Add to my foodz button
        if restoInRankingFlag {
            self.addToRankButton.isEnabled = false
            self.addToRankButton.isHidden = true
        }else{
            self.addToRankButton.isEnabled = true
            self.addToRankButton.isHidden = false
            FoodzLayout.configureButtonNoBorder(button: self.addToRankButton)
            self.addToRankButton.setTitle(MyStrings.buttonAddResto.localized(), for: .normal)
        }
        
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
        if tableView == self.editReviewTableView{
            return 1
        }else{
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Edit review pop-up
        if tableView == editReviewTableView{
            return 1
        }
        // the normal table
        else{
            switch(section){
                   case 0: return 4
                   case 1:
                       guard commentArray.count > 0 else {return 1}
                       return commentArray.count
                   default: return 0
                   }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Edit Review pop-up
        if tableView == editReviewTableView,
            let editReviewCell = editReviewTableView.dequeueReusableCell(withIdentifier: editReviewCell) as? EditReviewCell{
            configureEditReviewCell(cell: editReviewCell)
            
            return editReviewCell
        }
        
        // The normal table
        else if indexPath.section == 0 {
            if indexPath.row == 0{
                let cell = restoDetailTable.dequeueReusableCell(withIdentifier: self.addressCellId)
                cell!.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell!.textLabel?.textColor = .label
                cell!.textLabel?.text = MyStrings.address.localized()
                cell!.detailTextLabel?.text = currentResto.address
                return cell!
            }else if indexPath.row == 1 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.textColor = .label
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = MyStrings.phone.localized()
                cell.detailTextLabel?.text = currentResto.phoneNumber
                return cell
            }else if indexPath.row == 2 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.textColor = .label
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = MyStrings.url.localized()
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
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = SomeApp.themeColor
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.text = MyStrings.reviews.localized()
                
                return cell
            }
        }else{
            guard commentArray.count > 0 else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = FoodzLayout.FoodzStrings.loading.localized()
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            // If it is an Ad cell, we have two options: load one or placeholder
            if (indexPath.row % adFrequency == (adFrequency - 1) ) {
                // If we have loaded Ads
                if nativeAds.count > 0{
                    // Ad Cell
                    let nativeAdCell = tableView.dequeueReusableCell(
                        withIdentifier: "UnifiedNativeAdCell", for: indexPath)
                    configureAddCell(nativeAdCell: nativeAdCell, index: adsLoadedIndex)
                    adsLoadedIndex += 1
                    if adsLoadedIndex == (adsToLoad - 1) {
                        adsLoadedIndex = 0
                    }
                    
                    return(nativeAdCell)
                }
                // If not : placeholder
                else{
                    if let postCell = restoDetailTable.dequeueReusableCell(withIdentifier: commentCell, for: indexPath) as? CommentCell{
                        postCell.dateLabel.isHidden = true
                        postCell.likeButton.isHidden = true
                        postCell.moreButton.isHidden = true
                        
                        return postCell
                    }
                    else{fatalError("Can't create cell")}
                }
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
                
                // Stack View border
                postCell.stackView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
                postCell.stackView.layer.borderWidth = 0.8
                postCell.stackView.layer.cornerRadius = 10
                postCell.stackView.layer.masksToBounds = true
                
                // If it is the firstComment, we do a different processing
                guard !firstCommentFlag else{
                    
                    postCell.stackView.isHidden = true
                    
                    postCell.likeButton.isEnabled = false
                    postCell.nbLikesButton.setTitle(MyStrings.buttonYumsEmpty.localized(), for: .normal)
                    postCell.nbLikesButton.isEnabled = true
                    postCell.moreButton.setTitle("", for: .normal)
                    postCell.moreButton.isEnabled = false
                    
                    if !restoInRankingFlag{
                        postCell.moreAction = {_ in
                            self.addRestoToRanking()
                        }
                    }else if seguer != nil{
                        switch seguer! {
                        // From ThisRanking when I'm the caller I pop back
                        case MyRestoSeguer.ThisRankingMy:
                            postCell.moreAction = {_ in
                                self.delegate?.myRestoReceiveResto(currentResto: self.currentResto!)
                                self.navigationController?.popViewController(animated: true)
                            }
                        case MyRestoSeguer.ThisRankingVisitor:
                            postCell.moreAction = {_ in
                                self.editReview()
                            }
                        // From Best Restos
                        case MyRestoSeguer.BestRestos:
                            postCell.moreAction = {_ in
                                self.editReview()
                            }
                        }
                    }
                    
                    
                    postCell.selectionStyle = .none
                    return postCell
                }
                
                
                // Like button
                postCell.likeButton.setTitle(MyStrings.buttonYum.localized(), for: .normal)
                if restoReviewLiked[indexPath.row]{
                    postCell.likeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
                    postCell.likeButton.setTitleColor(SomeApp.selectionColor , for: .normal)
                    postCell.likeButton.setTitle(MyStrings.buttonYummed.localized(), for: .normal)
                }else{
                    postCell.likeButton.setTitleColor(SomeApp.themeColor, for: .normal)
                }
                
                // NbLikes label
                postCell.nbLikesButton.setTitleColor(.systemGray, for: .normal)
                postCell.nbLikesButton.setTitle(MyStrings.buttonYum.localized(arguments: restoReviewsLikeNb[indexPath.row]),for: .normal)
                
                // Report button
                // [START] If it's not the first comment, then we can add some actions
                if !firstCommentFlag{
                    // We can Like
                    if !restoReviewLiked[indexPath.row]{
                        postCell.likeAction = {(cell) in
                            let tmpIndexPath = self.restoDetailTable.indexPath(for: cell)
                            SomeApp.likeReview(userid: self.user.uid,
                                               resto: self.currentResto,
                                               city: self.currentCity,
                                               foodId: self.currentFood.key,
                                               reviewerId: self.commentArray[tmpIndexPath!.row].key)
                        }
                    }
                    // if we already liked
                    else{
                        postCell.likeAction = {(cell) in
                            let tmpIndexPath = self.restoDetailTable.indexPath(for: cell)
                            SomeApp.dislikeReview(userid: self.user.uid,
                                               resto: self.currentResto,
                                               city: self.currentCity,
                                               foodId: self.currentFood.key,
                                               reviewerId: self.commentArray[tmpIndexPath!.row].key)
                        }
                    }
                    
                    // More (report) button
                    postCell.moreButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
                    postCell.moreButton.setTitleColor(.darkGray, for: .normal)
                    postCell.moreButton.setTitle("...", for: .normal)
                    postCell.moreButton.isHidden = false
                    postCell.moreButton.isEnabled = true
                    
                    postCell.moreAction = {(cell) in
                        let tmpIndexPath = self.restoDetailTable.indexPath(for: cell)
                        let moreAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        let reportAction = UIAlertAction(title: "Report", style: .destructive, handler: {_ in
                            // [START] Inner Alert
                            let innerAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                            let inappropriateAction = UIAlertAction(title: "It's inappropriate", style: .destructive, handler: {_ in
                                
                                SomeApp.reportReview(userid: self.commentArray[tmpIndexPath!.row].key,
                                                     resto: self.currentResto,
                                                     city: self.currentCity,
                                                     foodId: self.currentFood.key,
                                                     text: self.commentArray[tmpIndexPath!.row].text,
                                                     reportReason: "Inappropriate",
                                                     postTimestamp: self.commentArray[tmpIndexPath!.row].timestamp,
                                                     reporterId: self.user.uid)
                                
                                self.navigationController?.popViewController(animated: true)
                            })
                            let spamAction = UIAlertAction(title: "It's spam", style: .destructive, handler: {_ in
                                SomeApp.reportReview(userid: self.commentArray[tmpIndexPath!.row].key,
                                resto: self.currentResto,
                                city: self.currentCity,
                                foodId: self.currentFood.key,
                                text: self.commentArray[tmpIndexPath!.row].text,
                                reportReason: "Spam",
                                postTimestamp: self.commentArray[tmpIndexPath!.row].timestamp,
                                reporterId: self.user.uid)
                                
                                self.navigationController?.popViewController(animated: true)
                            })
                            let cancelAction = UIAlertAction(
                                title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                                style: .cancel, handler: nil)
                            innerAlert.addAction(inappropriateAction)
                            innerAlert.addAction(spamAction)
                            innerAlert.addAction(cancelAction)
                            self.present(innerAlert,animated: true)
                            // [END] Inner alert
                        })
                        let cancelAction = UIAlertAction(
                            title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                            style: .cancel, handler: nil)
                        
                        moreAlert.addAction(reportAction)
                        moreAlert.addAction(cancelAction)
                        self.present(moreAlert,animated: true)
                    }
                } // [END] Add actions
                
                postCell.selectionStyle = .none
                
                return postCell
            }else{
                fatalError("Couln't create cell")
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == editReviewTableView{
            return 450
        }
        //
        else{
            return UITableView.automaticDimension
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
                         title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                         style: .default,
                         handler: {
                             (action: UIAlertAction)->Void in
                             //do nothing
                     }))
                     present(alert, animated: false, completion: nil)
                     
                 }
             }else if indexPath.row == 2{
                // URL clicked, open the web page
                if currentResto.url != nil{
                    let config = SFSafariViewController.Configuration()
                    config.entersReaderIfAvailable = true
                    
                    let vc = SFSafariViewController(url: currentResto.url, configuration: config)
                    vc.preferredBarTintColor = UIColor.systemBackground
                    
                    present(vc, animated: true)
                }
                // No valid URL
                else{
                    let alert = UIAlertController(title: "Invalid URL", message: "This place has an invalid URL.", preferredStyle: .alert)
                    let OKaction = UIAlertAction(
                        title: FoodzLayout.FoodzStrings.buttonOK.localized(),
                        style: .default, handler:nil)
                    alert.addAction(OKaction)
                    self.present(alert, animated:true)
                    // Deselect row
                    if let indexPath = restoDetailTable.indexPathForSelectedRow {
                        restoDetailTable.deselectRow(at: indexPath, animated: true)
                    }
                }
                //
             }
         }
     }
    
    // MARK: Edit review cell
    func configureEditReviewCell(cell: EditReviewCell){
        FoodzLayout.configureEditTextCell(cell: cell)
        
        //title
        cell.titleLabel.text = "My review for \(currentResto.name)"
        cell.warningLabel.text = "Tell the world your honest opinion."
        
        cell.editReviewTextView.text = "Write your Review here."
        
        cell.editReviewTextView.becomeFirstResponder()
        cell.editReviewTextView.tag = 200
        cell.editReviewTextView.delegate = self
        
        
        // Done Button
        cell.doneButton.setTitle("Done!", for: .normal)
        cell.updateReviewAction = { (cell) in
            self.doneUpdating(resto: self.currentResto,
                              commentText: cell.editReviewTextView.text)
        }
    }
}

// MARK: Get reviews from DB
extension MyRestoDetail{
    
    func getReviewsFromDB(){
        var tmpCommentArray:[Comment] = []
        var count = 0
        
        // Get from database
        dbRestoReviews.observeSingleEvent(of: .value, with: {snapshot in
            // If there are no comments for the restaurant, create a dummy comment
            guard snapshot.exists() else{
                let tmpTimestamp = NSDate().timeIntervalSince1970 * 1000
                self.firstCommentFlag = true
                let tmpText = "Be the first to add a comment of \(self.currentResto.name)! Go to your \(self.currentFood.name) ranking and start being an influencer."
                tmpCommentArray.append(Comment(username: "There are no reviews!", restoname: self.currentResto.name, text: tmpText, timestamp:  tmpTimestamp, title: "No comments yet"))
                self.commentArray = tmpCommentArray
                self.restoDetailTable.reloadData()
                return
            }
            // Initialize the arrays
            self.restoReviewLiked = self.initializeBoolArray(withElements: Int(snapshot.childrenCount))
            self.restoReviewsLikeNb = self.initializeIntArray(withElements: Int(snapshot.childrenCount))
            
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
                    let userId = commentRestoSnapshot.key

                    tmpCommentArray.append(Comment(username: username, restoname: self.currentResto.name, text: body, timestamp: timestamp, title: tmpTitle,key: userId))
                    
                    //Use the trick
                    count += 1
                    if count == snapshot.childrenCount{
                        // Then, add the Ads at adFrequency positions
                        for i in 0 ..< tmpCommentArray.count{
                            if i % self.adFrequency == (self.adFrequency - 1){
                                //
                                let placeholderAd = Comment(username: "foodz.guru", restoname: "Placeholder", text: "Advertise here! Contact support@foodz.guru", timestamp: NSDate().timeIntervalSince1970, title: "Advertise here!")
                                tmpCommentArray.insert(placeholderAd, at: i)
                            }
                        }
                        self.commentArray = tmpCommentArray
                        self.restoDetailTable.reloadData()
                        self.getLikes()
                    }
                }
            }
        })
    }
    
    private func getLikes(){
        let restoLikesDBPath = currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/" + currentFood.key + "/" + currentResto.key
        
        for i in 0 ..< commentArray.count{
            let dbPath = restoLikesDBPath + "/" + commentArray[i].key + "/" + user.uid
            // 1. Verify if the user has liked
            restoReviewsLikesHandle.append((handle: SomeApp.dbRestoReviewsLikes.child(dbPath ).observe(.value, with: {snapshot in
                self.restoReviewLiked[i] = snapshot.exists()
                
                //2. Get the numb of likes
                self.restoReviewsLikesNbHandle.append((handle: SomeApp.dbRestoReviewsLikesNb.child(dbPath).observe(.value, with: {likesNbSnap in
                    if likesNbSnap.exists(),
                        let nbLikes = likesNbSnap.value as? Int{
                        self.restoReviewsLikeNb[i] = nbLikes
                    }else{
                        self.restoReviewsLikeNb[i] = 0
                    }
                    // Update by row, section 1 (comments)
                    self.restoDetailTable.reloadRows(
                    at: [IndexPath(row: i, section: 1)],
                    with: .none)
                    
                }),dbPath:dbPath))
            }), dbPath:dbPath))
        }
        
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

// MARK: helper funcs
extension MyRestoDetail {
    
    func initializeIntArray(withElements: Int) -> [Int]{
        var tmpArray: [Int] = []
        for _ in 0..<withElements {
            tmpArray.append(0)
        }
        return tmpArray
    }
    
    func initializeBoolArray(withElements: Int) -> [Bool]{
        var tmpArray: [Bool] = []
        for _ in 0..<withElements {
            tmpArray.append(false)
        }
        return tmpArray
    }
    
    // Done Writing Review
    func doneUpdating(resto: Resto, commentText: String){
        // Write to model
        if ![""," ","Write your Review here","Write your Review here."].contains(commentText){
            SomeApp.updateUserReview(userid: user.uid, resto: resto, city: currentCity, foodId: currentFood.key ,text: commentText)
        }
        //Close the view
        onClickEditReviewTransparentView()
        self.getReviewsFromDB()
    }
    
    //Disappear!
    @objc func onClickEditReviewTransparentView(){
        // Animation when disapearing
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.editReviewTransparentView.alpha = 0 //Start at value above, go to 0
                        self.editReviewTableView.frame = CGRect(
                            x: 0,
                            y: FoodzLayout.screenSize.height ,
                            width: FoodzLayout.screenSize.width,
                            height: FoodzLayout.screenSize.height * 0.9)
                        self.editReviewTableView.endEditing(true)
        },
                       completion: nil)
    }
    
    // MARK: Popup the Edit Review table
    @objc func editReview(){
        editReviewTableView.reloadData()
        
        FoodzLayout.popupTable(viewController: self,
                               transparentView: editReviewTransparentView,
                               tableView: editReviewTableView)
        
        // Set the first responder
        if let cell = editReviewTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditReviewCell{
            cell.editReviewTextView.becomeFirstResponder()
        }
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickEditReviewTransparentView))
        editReviewTransparentView.addGestureRecognizer(tapGesture)
    }
    
    //Add resto to Ranking
    func addRestoToRanking(){
        // Check if the user has this food already
        let dbPath = user.uid + "/" + currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/" + currentFood.key
        
        SomeApp.dbUserRankings.child(dbPath).observeSingleEvent(of: .value, with: {snapshot in
            // Le ranking doesn't exist
            if !snapshot.exists(){
                let alert = UIAlertController(title: "Create ranking",
                                              message: "You don't have a \(self.currentFood.name), create and add restorant?",
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
                    // Need to update cell and header
                    //asdfasf
                    
                    
                    // Show confirmation banner
                    self.bannerStuff()
                }
                let cancelAction = UIAlertAction(
                    title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                    style: .cancel, handler: nil)
                alert.addAction(createAction)
                alert.addAction(cancelAction)
                
                self.present(alert, animated: true, completion: nil)
                
            }
            // The ranking exists: add resto sans autre
            else{
                SomeApp.addRestoToRanking(userId: self.user.uid,
                                          resto: self.currentResto,
                                          mapItem: self.currentRestoMapItem,
                                          forFood: self.currentFood,
                                          foodId: self.currentFood.key,
                                          city: self.currentCity)
                self.bannerStuff()
            }
            
            // If it's the first comment, reload the row
            if self.firstCommentFlag{
                self.restoInRankingFlag = true // the observer might be too slow
                self.restoDetailTable.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            }
        })
    }
}

// MARK: ad Loader delegate
extension MyRestoDetail: GADUnifiedNativeAdLoaderDelegate{
    // Ad adds to table
    func addNativeAdds(){
        if nativeAds.count <= 0 {
          return
        }
        var index = adFrequency - 1
        
        for i in 0 ..< commentArray.count{
            if i == index{
                restoDetailTable.reloadRows(at: [IndexPath(row: index, section: 1)], with: .automatic)
                index += adFrequency
            }
        }
    }
    
    
    // My cell
    func configureAddCell(nativeAdCell: UITableViewCell, index: Int){
        guard nativeAds.count > 0 else {return}
        let nativeAd = nativeAds[index] // GADUnifiedNativeAd()
        
        // Set the native ad's rootViewController to the current view controller.
        nativeAd.rootViewController = self
        
        // Get the ad view from the Cell. The view hierarchy for this cell is defined in
        // UnifiedNativeAdCell.xib.
        let adView : GADUnifiedNativeAdView = nativeAdCell.contentView.subviews.first as! GADUnifiedNativeAdView
        
        // Associate the ad view with the ad object.
        // This is required to make the ad clickable.
        adView.nativeAd = nativeAd
        
        // Populate the ad view with the ad assets.
        (adView.headlineView as! UILabel).text = nativeAd.headline
        (adView.priceView as! UILabel).text = nativeAd.price
        if let starRating = nativeAd.starRating {
            (adView.starRatingView as! UILabel).text =
                starRating.description + "\u{2605}"
        } else {
            (adView.starRatingView as! UILabel).text = nil
        }
        (adView.bodyView as! UILabel).text = nativeAd.body
        (adView.advertiserView as! UILabel).text = nativeAd.advertiser
        // The SDK automatically turns off user interaction for assets that are part of the ad, but
        // it is still good to be explicit.
        (adView.callToActionView as! UIButton).isUserInteractionEnabled = false
        (adView.callToActionView as! UIButton).setTitle(
            nativeAd.callToAction, for: UIControl.State.normal)
    }
    
    func configureNativeAds(){
        let options = GADMultipleAdsAdLoaderOptions()
        options.numberOfAds = adsToLoad

        // Prepare the ad loader and start loading ads.
        adLoader = GADAdLoader(adUnitID: SomeApp.adNativeUnitID,
                               rootViewController: self,
                               adTypes: [.unifiedNative],
                               options: [options])
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
    // Delegate funcs
    func adLoader(_ adLoader: GADAdLoader,
                  didFailToReceiveAdWithError error: GADRequestError) {
      print("\(adLoader) failed with error: \(error.localizedDescription)")

    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
      //print("Received native ad: \(nativeAd)")

      // Add the native ad to the list of native ads.
      nativeAds.append(nativeAd)
    }
    
    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        //When we finish loading Ads, we update the table view
        addNativeAdds()
        
        
    }
}

// MARK: Banner Ad Stuff
extension MyRestoDetail: GADBannerViewDelegate{
    // My funcs
    private func configureBannerAd(){
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
    }
    
    // Ad delegate
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
    
    /// Tells the delegate an ad request failed.
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

// MARK: Localized Strings
extension MyRestoDetail{
    private enum MyStrings {
        case bannerTitle
        case buttonAddResto
        case address
        case phone
        case url
        case reviews
        case buttonYumsEmpty
        case buttonYum
        case buttonYummed
        case buttonYumNb
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .bannerTitle:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BANNER", comment: "Added"),
                locale: .current,
                arguments: arguments)
            case .buttonAddResto:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_ADDRESTO", comment: "Add"),
                locale: .current,
                arguments: arguments)
            case .address:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_ADDRESS", comment: "address"),
                locale: .current,
                arguments: arguments)
            case .phone:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_PHONE", comment: "phone"),
                locale: .current,
                arguments: arguments)
            case .url:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_URL", comment: "url"),
                locale: .current,
                arguments: arguments)
            case .reviews:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_REVIEWS", comment: "reviews"),
                locale: .current,
                arguments: arguments)
            case .buttonYumsEmpty:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_YUMS_EMPTY", comment: "get more"),
                locale: .current,
                arguments: arguments)
            case .buttonYum:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_YUM", comment: "yum"),
                locale: .current,
                arguments: arguments)
            case .buttonYummed:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_YUMMED", comment: "yum"),
                locale: .current,
                arguments: arguments)
            case .buttonYumNb:
                return String(
                format: NSLocalizedString("MYRESTODETAIL_BUTTON_YUMNB", comment: "yum"),
                locale: .current,
                arguments: arguments)
            }
        }
    }
}
