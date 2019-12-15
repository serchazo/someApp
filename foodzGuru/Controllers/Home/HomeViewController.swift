//
//  HomeViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 15.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class HomeViewController: UIViewController {
    
    // Class variables
    private static let timelineCellIdentifier = "TimelineCell"
    private static let timelineCellNibIdentifier = "TimelineCell"
    private let unifiedCellIdentifier = "UnifiedNativeAdCell"
    private let timelineCellWithImage = "TimelineCellWithImage"
    private let timelineCellWithImageNibId = "TimelineCellWithImage"
    
    // Cell identifiers
    private let timelineNewUserRanking = "timelineUserRanking"
    private let timelineUserFollowing = "timelineUserFollowing"
    private let timelineNewUserReview = "timelineUserNewReview"
    private let timelineNewFavorite = "timelineUserFavorite"
    private let timelineRankingInfo = "timelineRankingInfoCell"
    private let timelineNewYum = "timelineNewYum"
    
    // Segue identifiers
    private let segueIDShowUserFromNewRanking = "showUserFromNewRanking"
    private let segueIDShowUserFromFollowing = "showUserFollowing"
    private let segueIDShowUserReview = "showUserReview"
    private let segueIDShowUserFavorite = "showUserFavorite"
    private let segueIDShowTopRestos = "showTopRestos"
    private let segueIDShowYum = "showYum"
    
    // Instance variables
    private var user: User!
    private var somePost: [(key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)] = []
    private var userTimelineReference: DatabaseReference!
    
    // MARK: outlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var adView: UIView!
    
    //Handles
    private var timelineHandle:UInt!
    
    // Ad stuff
    private var bannerView: GADBannerView!
    private let adsToLoad = 5 //The number of native ads to load
    private var adsLoadedIndex = 0 // to count the ads we are loading
    
    private var nativeAds = [GADUnifiedNativeAd]() // The native ads.
    private var adLoader: GADAdLoader!  // The ad loader that loads the native ads.
    private let adFrequency = 7
    
    private let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var newsFeedTable: UITableView!{
        didSet{
            newsFeedTable.delegate = self
            newsFeedTable.dataSource = self
            newsFeedTable.register(TimelineCell.self, forCellReuseIdentifier: HomeViewController.timelineCellIdentifier)
            // register cells
            newsFeedTable.register(UINib(nibName: HomeViewController.timelineCellNibIdentifier, bundle: nil), forCellReuseIdentifier: HomeViewController.timelineCellIdentifier)
            newsFeedTable.register(UINib(nibName: timelineCellWithImageNibId, bundle: nil), forCellReuseIdentifier: timelineCellWithImage)
            
            newsFeedTable.register(UINib(nibName: self.unifiedCellIdentifier, bundle: nil),
                                   forCellReuseIdentifier: self.unifiedCellIdentifier)
            
            newsFeedTable.rowHeight = UITableView.automaticDimension
            newsFeedTable.estimatedRowHeight = 150
            
            newsFeedTable.refreshControl = refreshControl
        }
    }
    
    // MARK: Timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // 1. Get the logged in user - needed for the next step
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // 2. Once we get the user, update!
            self.userTimelineReference = SomeApp.dbUserTimeline.child(user.uid)
            self.updateTimelinefromDB()
        }
        
        // Configure the Ads
        configureBannerAd()
        configureNativeAds()
        
        if let indexPath = newsFeedTable.indexPathForSelectedRow {
            newsFeedTable.deselectRow(at: indexPath, animated: true)
        }

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = FoodzLayout.FoodzStrings.appName.localized()
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SomeApp.dbUserTimeline.child(user.uid).removeObserver(withHandle: timelineHandle)
        
        bannerView.delegate = nil
    }
    
    // MARK: update from DB
    @objc private func refreshData(_ sender: Any) {
        // If pull down the table, then refresh data
        newsFeedTable.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    func updateTimelinefromDB(){
        timelineHandle = userTimelineReference.queryOrdered(byChild: "timestamp").queryLimited(toLast: 30).observe(.value, with: {snapshot in
            var count = 0
            var tmpPosts:[(key: String, type:String, timestamp:Double, payload: String, initiator:String, target: String, targetName: String)] = []
        
            for child in snapshot.children{
                if let timeLineSnap = child as? DataSnapshot,
                    let value = timeLineSnap.value as? [String:AnyObject],
                    let type = value["type"] as? String,
                    let timestamp = value["timestamp"] as? Double,
                    let payload = value["payload"] as? String{
                    // Following could be empty
                    var tmpTarget = ""
                    if let target = value["target"] as? String {tmpTarget = target}
                    var tmpTargetName = ""
                    if let targetName = value["targetName"] as? String {tmpTargetName = targetName}
                    var tmpInitiator = ""
                    if let initiator = value["initiator"] as? String {tmpInitiator = initiator}
                    
                    tmpPosts.append((
                        key: timeLineSnap.key,
                        type: type,
                        timestamp: timestamp,
                        payload: payload,
                        initiator: tmpInitiator,
                        target: tmpTarget,
                        targetName: tmpTargetName))
                    
                    // Use the trick
                    count += 1
                        
                    // ... but first, let me take an ad
                    if count == snapshot.childrenCount{
                        tmpPosts = tmpPosts.reversed()
                        
                        // Then, add the Ads at adFrequency positions
                        for i in 0 ..< tmpPosts.count{
                            if i % self.adFrequency == (self.adFrequency - 1){
                                let placeholderAd = self.placeHolderAd()
                                tmpPosts.insert(placeholderAd, at: i)
                            }
                        }
                        
                        self.somePost = tmpPosts
                        // Then reload
                        self.newsFeedTable.reloadData()
                    }
                }
            }
        })
    }
    
    // Placeholder Ad
    private func placeHolderAd() -> (key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String){
        let tmpKey = "nativeAd"
        let tmpType = TimelineEvents.NativeAd.rawValue
        let tmpTimestamp = NSDate().timeIntervalSince1970
        let tmpPayoload = FoodzLayout.FoodzStrings.adPlaceholderLong.localized()
        let tmpInitiator = FoodzLayout.FoodzStrings.appName.localized()
        let target = "nil"
        let targetName = "nil"
        return (key: tmpKey, type:tmpType, timestamp:tmpTimestamp, payload: tmpPayoload, initiator: tmpInitiator, target: target, targetName: targetName)
        
    }

    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == self.segueIDShowUserFromNewRanking,
            let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let myRanksVC = segue.destination as? MyRanks{
            
            myRanksVC.currentCity = getCityFromNewRanking(target: somePost[indexPath.row].target, targetName:somePost[indexPath.row].targetName)
            myRanksVC.calledUser = getUserObjectFromNewRanking(post: somePost[indexPath.row])
        }
        //Show user ranking details for new following
        else if segue.identifier == self.segueIDShowUserFromFollowing,
        let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let myRanksVC = segue.destination as? MyRanks{
            
            myRanksVC.calledUser = getUserObjectFromNewFollowing(post: somePost[indexPath.row])
            myRanksVC.currentCity = getCityFromFollowing(target: somePost[indexPath.row].target)
        }
        // Show ThisRanking for new review
        else if segue.identifier == self.segueIDShowUserReview,
            let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let thisRankingVC = segue.destination as? ThisRanking{
            // Setup the stuff
            let parseResult = parseNewReview(target: somePost[indexPath.row].target, targetName: somePost[indexPath.row].targetName, initiator: somePost[indexPath.row].initiator)
            
            thisRankingVC.calledUser = parseResult.user
            thisRankingVC.currentCity = parseResult.city
            thisRankingVC.currentFood = parseResult.food
        }
        // Show ThisRanking for new Yum!
        else if segue.identifier == self.segueIDShowYum,
            let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let thisRankingVC = segue.destination as? ThisRanking{
            
            // Setup the stuff
            let parseResult = parseNewReview(target: somePost[indexPath.row].target, targetName: somePost[indexPath.row].targetName, initiator: somePost[indexPath.row].initiator)
            
            thisRankingVC.calledUser = nil
            thisRankingVC.currentCity = parseResult.city
            thisRankingVC.currentFood = parseResult.food
        }
        // Show ThisRanking for new favorite
        else if segue.identifier == self.segueIDShowUserFavorite,
            let cell = sender as? HomeCellWithImage,
            let indexPath = newsFeedTable.indexPath(for: cell),
            let thisRankingVC = segue.destination as? ThisRanking{
            // Setup the stuff
            let parseResult = parseNewReview(target: somePost[indexPath.row].target, targetName: somePost[indexPath.row].targetName, initiator: somePost[indexPath.row].initiator)
            
            thisRankingVC.calledUser = parseResult.user
            thisRankingVC.currentCity = parseResult.city
            thisRankingVC.currentFood = parseResult.food
        }
        // Show resto rank for ranking stuff
        else if segue.identifier == self.segueIDShowTopRestos,
        let cell = sender as? HomeCellWithIcon,
        let indexPath = newsFeedTable.indexPath(for: cell),
            let topRestosVC = segue.destination as? BestRestosViewController{
            let parseResult = parseTopRestos(target: somePost[indexPath.row].target, targetName: somePost[indexPath.row].targetName, initiator: somePost[indexPath.row].initiator)
            
            topRestosVC.currentCity = parseResult.city
            topRestosVC.currentFood = parseResult.food
        }
        //
    }

}

// MARK: Table stuff
extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard somePost.count > 0 else {return 1}
        return somePost.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // If empty, turn spinner
        guard somePost.count > 0 else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = FoodzLayout.FoodzStrings.loading.localized()
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            cell.accessoryView = spinner
            
            return cell
        }
        // New ranking
        if somePost[indexPath.row].type == TimelineEvents.NewUserRanking.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewUserRanking, for: indexPath) as? HomeCellWithImage {
            cell.titleLabel.text = MyStrings.postNewRanking.localized()
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // User following
        else if somePost[indexPath.row].type == TimelineEvents.NewFollower.rawValue,
        let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineUserFollowing, for: indexPath) as? HomeCellWithImage {
            cell.titleLabel.text = MyStrings.postNewFollower.localized()
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New Yum!
        else if somePost[indexPath.row].type == TimelineEvents.NewYum.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewYum, for: indexPath) as? HomeCellWithImage {
            cell.titleLabel.text = MyStrings.postNewYum.localized()
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New review
        else if somePost[indexPath.row].type == TimelineEvents.NewUserReview.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewUserReview, for: indexPath) as? HomeCellWithImage  {
            cell.titleLabel.text = MyStrings.postNewReview.localized()
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New favorite
        else if somePost[indexPath.row].type == TimelineEvents.NewUserFavorite.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: self.timelineNewFavorite, for: indexPath) as? HomeCellWithImage  {
            cell.titleLabel.text = MyStrings.postNewFavorite.localized()
            setImageDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New best in ranking
        else if somePost[indexPath.row].type == TimelineEvents.NewBestRestoInRanking.rawValue,
            let cell = newsFeedTable.dequeueReusableCell(withIdentifier: timelineRankingInfo, for: indexPath) as? HomeCellWithIcon {
            cell.titleLabel.text = MyStrings.postNewBestInRank.localized()
            setIconDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // New arrival in ranking
        else if somePost[indexPath.row].type == TimelineEvents.NewArrivalInRanking.rawValue,
        let cell = newsFeedTable.dequeueReusableCell(withIdentifier: timelineRankingInfo, for: indexPath) as? HomeCellWithIcon {
            cell.titleLabel.text = MyStrings.postNewInTopRank.localized()
            setIconDateBodyInCell(cell: cell, forPost:somePost[indexPath.row])
            return cell
        }
        // If it is an Ad, we have two options: load one or placeholder
        else if somePost[indexPath.row].type == TimelineEvents.NativeAd.rawValue{
            // If we have loaded Ads
            if nativeAds.count > 0{
                // Ad Cell
                let nativeAdCell = tableView.dequeueReusableCell(
                    withIdentifier: self.unifiedCellIdentifier, for: indexPath)
                configureAddCell(nativeAdCell: nativeAdCell, index: adsLoadedIndex)
                adsLoadedIndex += 1
                if adsLoadedIndex == (adsToLoad - 1) {
                    adsLoadedIndex = 0
                }
                
                return(nativeAdCell)
            }
                // If we don't have loaded Ads, we put a placeholder
            else{
                let spinnerCell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                spinnerCell.textLabel?.textColor = .label
                spinnerCell.textLabel?.text = FoodzLayout.FoodzStrings.adPlaceholderShortTitle.localized()
                spinnerCell.detailTextLabel?.textColor = .label
                spinnerCell.detailTextLabel?.text = FoodzLayout.FoodzStrings.adPlaceholderShortMsg.localized()
                spinnerCell.imageView?.image = UIImage(named: "idea")
                spinnerCell.selectionStyle = .none
                return spinnerCell
            }
        }
            
        // Foodz.guru stuff
        else if let postCell = newsFeedTable.dequeueReusableCell(withIdentifier: HomeViewController.timelineCellIdentifier, for: indexPath) as? TimelineCell{
            setupPostCell(cell: postCell,
                          type: somePost[indexPath.row].type,
                          timestamp: somePost[indexPath.row].timestamp,
                          payload: somePost[indexPath.row].payload,
                          icon: "💬")
            
            return postCell
        }else{
            fatalError("Unable to create cell")
        }
    }
}

// MARK: Home cells

extension HomeViewController{
    func setupPostCell(cell: TimelineCell, type:String, timestamp:Double, payload: String, icon:String ){
        
        // Date stuff
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        if (type == TimelineEvents.FoodzGuruPost.rawValue){
            cell.titleLabel.text = FoodzLayout.FoodzStrings.appName.localized()
            cell.bodyLabel.text = payload
            cell.iconLabel.text = "💬"
        }
        else if (type == TimelineEvents.NativeAd.rawValue){
            cell.titleLabel.text = FoodzLayout.FoodzStrings.adPlaceholderShortTitle.localized()
            cell.bodyLabel.text = payload
            cell.iconLabel.text = "💡"
        }

    }
    
    // MARK: new cells
    // With icon
    func setIconDateBodyInCell(cell: HomeCellWithIcon, forPost: (key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)){
        // Set icon
        let tmpArray = forPost.targetName.components(separatedBy: "/")
        if tmpArray.count >= 3{
            cell.iconLabel.text = tmpArray[2]
        }else{
            cell.iconLabel.text = "💬"
        }
        
        // Set Date
        let date = Date(timeIntervalSince1970: TimeInterval(forPost.timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        // Body
        cell.bodyLabel.text = forPost.payload
    }
    
    // With image
    func setImageDateBodyInCell(cell: HomeCellWithImage, forPost: (key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)){
        // Set Image
        let userRef = SomeApp.dbUserData
        userRef.child(forPost.initiator).observeSingleEvent(of: .value, with: {snapshot in
            if let value = snapshot.value as? [String:Any],
                let photoURL = value["photourl"] as? String{
                cell.cellImage.sd_setImage(
                    with: URL(string: photoURL),
                    placeholderImage: UIImage(named: "userdefault"),
                    options: [],
                    completed: nil)
            }else{
                cell.cellImage.image = UIImage(named: "userdefault")
            }
        })
        
        // Set Date
        let date = Date(timeIntervalSince1970: TimeInterval(forPost.timestamp/1000)) // in milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: date)
        cell.dateLabel.text = localDate
        
        // Body
        cell.bodyLabel.text = forPost.payload
        
    }
}

// MARK: parsing funcs
extension HomeViewController{
    //
    private func getCityFromNewRanking(target: String, targetName: String) -> City{
        let cityArray = target.components(separatedBy: "/")
        let targetArray = targetName.components(separatedBy: "/")
        return City(country: cityArray[0] , state: cityArray[1], key: cityArray[2], name: targetArray[1])
    }
    //
    private func getUserObjectFromNewRanking(post: (key: String, type:String, timestamp:Double, payload: String,initiator: String, target: String, targetName: String)) -> UserDetails{
        let payLoadArray = post.payload.components(separatedBy: " ")
        return UserDetails(nickName: payLoadArray[0], key: post.initiator)
    }
    // Get user object from following post
    private func getUserObjectFromNewFollowing(post: (key: String, type:String, timestamp:Double, payload: String, initiator: String, target: String, targetName: String)) -> UserDetails{
        let nick = post.targetName
        let payLoadArray = post.target.components(separatedBy: "/")
        let userKey = payLoadArray[payLoadArray.count-1]
        return UserDetails(nickName: nick, key: userKey)
    }
    // Get city from following post
    private func getCityFromFollowing(target: String) -> City{
        let cityArray = target.components(separatedBy: "/")
        return City(country: cityArray[0] , state: cityArray[1], key: cityArray[2], name: cityArray[3])
    }
    
    // Parse new review post
    private func parseNewReview(target:String, targetName:String, initiator:String) -> (food:FoodType, user: UserDetails, city: City){
        let targetArray = target.components(separatedBy: "/")
        let targetNameArray = targetName.components(separatedBy: "/")
        let tmpUser = UserDetails(nickName: targetNameArray[0], key: initiator)
        let tmpCity = City(country: targetArray[0] , state: targetArray[1], key: targetArray[2], name: targetNameArray[1])
        let tmpFood = FoodType(icon: targetNameArray[3], name: targetNameArray[2], key: targetArray[3])
        return (food: tmpFood, user: tmpUser, city: tmpCity)
    }
    
    // Parse top restos post
    private func parseTopRestos(target:String, targetName:String, initiator:String) -> (food:FoodType, city: City){
        let targetArray = target.components(separatedBy: "/")
        let targetNameArray = targetName.components(separatedBy: "/")
        let tmpCity = City(country: targetArray[0] , state: targetArray[1], key: targetArray[2], name: targetNameArray[0])
        let tmpFood = FoodType(icon: targetNameArray[2], name: targetNameArray[1], key: targetArray[3])
        
        return (food: tmpFood, city: tmpCity)
    }
    
}

// MARK: Ad stuff
extension HomeViewController: GADBannerViewDelegate{
    // My func
    private func configureBannerAd(){
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
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
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        //print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        //print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        //print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        //print("adViewWillLeaveApplication")
    }
}

// MARK: ad Loader delegate
extension HomeViewController: GADUnifiedNativeAdLoaderDelegate{
    // Ad adds to table
    func addNativeAdds(){
        if nativeAds.count <= 0 {
          return
        }
        var index = adFrequency - 1
        
        for i in 0 ..< somePost.count{
            if i == index{
                newsFeedTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
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

// MARK: Localized Strings
extension HomeViewController{
    private enum MyStrings {
        case postNewRanking
        case postNewFollower
        case postNewYum
        case postNewReview
        case postNewFavorite
        case postNewBestInRank
        case postNewInTopRank
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .postNewRanking:
                return String(
                format: NSLocalizedString("HOME_POST_NEWRANKING", comment: "Ranking"),
                locale: .current,
                arguments: arguments)
            case .postNewFollower:
                return String(
                format: NSLocalizedString("HOME_POST_NEWFOLLOWER", comment: "Following"),
                locale: .current,
                arguments: arguments)
            case .postNewYum:
                return String(
                format: NSLocalizedString("HOME_POST_NEWYUM", comment: "yummy"),
                locale: .current,
                arguments: arguments)
            case .postNewReview:
                return String(
                format: NSLocalizedString("HOME_POST_NEWREVIEW", comment: "Comment"),
                locale: .current,
                arguments: arguments)
            case .postNewFavorite:
                return String(
                format: NSLocalizedString("HOME_POST_NEWFAVORITE", comment: "Favorite"),
                locale: .current,
                arguments: arguments)
            case .postNewBestInRank:
                return String(
                format: NSLocalizedString("HOME_POST_NEWBEST", comment: "Best one"),
                locale: .current,
                arguments: arguments)
            case .postNewInTopRank:
                return String(
                format: NSLocalizedString("HOME_POST_NEWINTOP", comment: "Top"),
                locale: .current,
                arguments: arguments)
                
            }
        }
    }
}
