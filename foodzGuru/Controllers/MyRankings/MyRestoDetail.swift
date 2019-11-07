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
    private var restoReviewLiked:[Bool] = []
    private var restoReviewsLikeNb:[Int] = []
    private var firstCommentFlag:Bool = false
    
    // We get this var from the preceding ViewController 
    var currentResto: Resto!
    var currentCity: City!
    var currentFood: FoodType!
    var dbMapReference: DatabaseReference!
    
    // Variable to pass to map Segue
    private var currentRestoMapItem : MKMapItem!
    private var OKtoPerformSegue = true
    
    // MARK: Ad stuff
    private let adsToLoad = 5 //The number of native ads to load
    private var adsLoadedIndex = 0 // to count the ads we are loading
       
    private var nativeAds = [GADUnifiedNativeAd]() /// The native ads.
    private var adLoader: GADAdLoader!  /// The ad loader that loads the native ads.
    private let adFrequency = 5
    
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
            restoDetailTable.register(UINib(nibName: "UnifiedNativeAdCell", bundle: nil),
            forCellReuseIdentifier: "UnifiedNativeAdCell")
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
        let dbReviewsPath = currentCity.country+"/"+currentCity.state + "/" + currentCity.key + "/" + currentFood.key + "/" + currentResto.key
        dbRestoReviews = SomeApp.dbRestoReviews.child(dbReviewsPath)
        
        // 1. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // 2. Once we have the user we configure the header
            self.configureHeader()
        }
        
        // Get the comments from the DB
        getReviewsFromDB()
        
        // Configure ads
        configureNativeAds()
        
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
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
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
                
                // If it is the firstComment, we don't activate the buttons
                guard !firstCommentFlag else{
                    postCell.likeButton.isEnabled = false
                    postCell.nbLikesButton.setTitle("Get Yums!", for: .normal)
                    postCell.moreButton.setTitle("", for: .normal)
                    postCell.moreButton.isEnabled = false
                    postCell.selectionStyle = .none
                    return postCell
                }
                
                
                // Like button
                postCell.likeButton.setTitle("Yum!", for: .normal)
                if restoReviewLiked[indexPath.row]{
                    postCell.likeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                    postCell.likeButton.setTitleColor(SomeApp.selectionColor, for: .normal)
                }else{
                    postCell.likeButton.setTitleColor(SomeApp.themeColor, for: .normal)
                }
                
                // NbLikes label
                postCell.nbLikesButton.setTitle("Yums! (\(restoReviewsLikeNb[indexPath.row]))", for: .normal)
                
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
                    // if we aleready liked
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
                    postCell.moreButton.setTitleColor(.lightGray, for: .normal)
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
                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                            innerAlert.addAction(inappropriateAction)
                            innerAlert.addAction(spamAction)
                            innerAlert.addAction(cancelAction)
                            self.present(innerAlert,animated: true)
                            // [END] Inner alert
                        })
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        
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
                // URL clicked, open the web page
                if currentResto.url != nil{
                    let config = SFSafariViewController.Configuration()
                    config.entersReaderIfAvailable = true
                    
                    let vc = SFSafariViewController(url: currentResto.url, configuration: config)
                    vc.navigationController?.navigationBar.titleTextAttributes = [
                    NSAttributedString.Key.foregroundColor: SomeApp.themeColor]
                    vc.preferredControlTintColor = SomeApp.themeColor
                    vc.preferredBarTintColor = UIColor.white
                    
                    present(vc, animated: true)
                 }
             }
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
                let tmpText = "Be the first to add a comment of \(self.currentResto.name)!"
                tmpCommentArray.append(Comment(username: "This could be you!", restoname: self.currentResto.name, text: tmpText, timestamp:  tmpTimestamp, title: "No comments yet"))
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
            let dbPath = restoLikesDBPath + "/" + commentArray[i].key
            // 1. Verify if the user has liked
            SomeApp.dbRestoReviewsLikes.child(dbPath + "/" + user.uid).observe(.value, with: {snapshot in
                self.restoReviewLiked[i] = snapshot.exists()
                
                //2. Get the numb of likes
                SomeApp.dbRestoReviewsLikesNb.child(dbPath).observe(.value, with: {likesNbSnap in
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
                    
                })
            })
            
            
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
