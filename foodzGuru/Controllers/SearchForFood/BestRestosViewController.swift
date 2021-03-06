//
//  RestoRankViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class BestRestosViewController: UIViewController {
    private static var showRestoDetailSegue = "showRestoDetail"
    private static let screenSize = UIScreen.main.bounds.size
    
    var thisRanking: [Resto] = []
    
    // To get from Segue-r
    var currentCity: City!
    var currentFood: FoodType!
    
    // Class Variables
    private let refreshControl = UIRefreshControl()
    private var emptyListFlag: Bool = false
    private var userFollowingRankingFlag: Bool = false
    private var user:User!
    
    //Handlers
    private var rankingFollowersHandle:[(handle:UInt, dbPath:String)]=[]
    private var restoPointsHandle:[(handle:UInt, dbPath:String)]=[]
    private var restoFollowersNbHandle:[(handle:UInt, dbPath:String)]=[]

    // Ad stuff
    private var bannerView: GADBannerView!
    private let adsToLoad = 1 //The number of native ads to load
    private var nativeAds = [GADUnifiedNativeAd]() // The native ads.
    private var adLoader: GADAdLoader!  // The ad loader that loads the native ads.
    //private let adFrequency = 5
    
    // MARK: outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var restoRankTableView: UITableView!{
        didSet{
            restoRankTableView.dataSource = self
            restoRankTableView.delegate = self
            restoRankTableView.refreshControl = refreshControl
            restoRankTableView.rowHeight = UITableView.automaticDimension
            restoRankTableView.estimatedRowHeight = 110
            restoRankTableView.tableFooterView = UIView()
        }
    }
    
    @IBOutlet weak var restoRankTableHeader: UIView!
    private var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    @IBOutlet weak var foodImageView: UIImageView!
    @IBOutlet weak var tableHeaderFoodName: UILabel!
    @IBOutlet weak var tableHeaderDescription: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followersButton: UIButton!
    
    @IBOutlet weak var adView: UIView!
    
    // MARK: Cool Strings
    let rankingDescription:[String] =
        [MyStrings.coolPhrase1.localized(),
         MyStrings.coolPhrase2.localized(),
         MyStrings.coolPhrase3.localized(),
         MyStrings.coolPhrase4.localized()]
    
    func getPhrase() -> String{
        let number = Int.random(in: 0 ..< rankingDescription.count)
        return rankingDescription[number]
    }
    
    // MARK: Timeline stuff
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let cityDBPath = currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/"  + currentFood.key
        
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // II. Update the food name in local
            let foodDBPath = self.currentCity.country + "/" + self.currentFood.key + "/name"
            SomeApp.dbFoodTypeRoot.child(foodDBPath).observeSingleEvent(of: .value, with: {foodSnap in
                if let foodName = foodSnap.value as? String{
                    self.currentFood.name = foodName
                    
                    // III. Go
                    self.configureHeader()
                    self.updateTableFromDatabase(cityDBPath: cityDBPath)
                }
            })
            
            
        }
        
        // Configure ads
        configureNativeAds()
        configureBannerAd()
        
        // Deselect the row when segued pops
        if let indexPath = restoRankTableView.indexPathForSelectedRow {
            restoRankTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        //Some setup
        restoRankTableView.register(UINib(nibName: "UnifiedNativeAdCell", bundle: nil),
                                    forCellReuseIdentifier: "UnifiedNativeAdCell")
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    //
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for (handle,dbPath) in rankingFollowersHandle{
            SomeApp.dbRankingFollowers.child(dbPath).removeObserver(withHandle: handle)
        }
        //restoFollowersHandle
        for (handle,dbPath) in restoFollowersNbHandle{
            SomeApp.dbRankingFollowersNb.child(dbPath).removeObserver(withHandle: handle)
        }
        
        
        bannerView.delegate = nil
    }
    
    /*
    //Dynamic header height.  Snippet from : https://useyourloaf.com/blog/variable-height-table-view-header/
       
       override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()

           guard let headerView = restoRankTableView.tableHeaderView else {
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
               restoRankTableView.tableHeaderView = headerView

               // Now that the table view header is sized correctly have
               // the table view redo its layout so that the cells are
               // correcly positioned for the new header size.
               // This only seems to be necessary on iOS 9.
               restoRankTableView.layoutIfNeeded()
           }
       }*/
    
    // MARK: configure header
    func configureHeader(){
        // Navigation title
        self.navigationItem.title = FoodzLayout.FoodzStrings.appName.localized()
        //self.navigationController?.hidesBarsOnSwipe = true
        
        // Title and description
        tableHeaderFoodName.font = UIFont.preferredFont(forTextStyle: .title1)
        tableHeaderFoodName.text = MyStrings.headerTitle.localized(arguments: currentFood.name, currentCity.name)
        tableHeaderDescription.font = UIFont.preferredFont(forTextStyle: .footnote)
        tableHeaderDescription.text = getPhrase()
        
        // Prepare the file first
        let storagePath = currentCity.country + "/" + currentFood.key + ".png"
        let imageRef = SomeApp.storageFoodRef.child(storagePath)
        // Fetch the download URL
        imageRef.downloadURL { url, error in
          if let error = error {
            self.foodImageView.image = UIImage(named: "defaultBest")
            print(error.localizedDescription)
          } else {
            self.photoURL = url
          }
        }
        
        // Configure follow button
        followButton.setTitleColor(SomeApp.themeColor, for: .normal)
        
        // We need to verify if the user is already following the ranking
        let dbPath = currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/" + currentFood.key + "/" + user.uid
        rankingFollowersHandle.append((handle: SomeApp.dbRankingFollowers.child(dbPath).observe(.value, with: {snapshot in
            
            if snapshot.exists() {
                self.userFollowingRankingFlag = true
            }
            self.configureFollowButton()
        }), dbPath:dbPath))
        
        // Followers button
        let dbPathNb = currentCity.country + "/" + currentCity.state + "/" + currentCity.key + "/" + currentFood.key
        var followersString = MyStrings.followers.localized() + ": 0"
        followersButton.setTitle(followersString, for: .normal)
        restoFollowersNbHandle.append((handle: SomeApp.dbRankingFollowersNb.child(dbPathNb).observe(.value, with: {snapshot in
            if snapshot.exists(),
                let followers = snapshot.value as? Int {
                followersString = MyStrings.followers.localized() + ": " + String(followers)
                self.followersButton.setTitle(followersString, for: .normal)
            }
        }),dbPath: dbPathNb))
    }
    
    private func configureFollowButton(){
        if userFollowingRankingFlag{
            self.followButton.setTitle(MyStrings.unfollow.localized(), for: .normal)
            followButton.removeTarget(self, action: #selector(self.followRanking), for: .touchUpInside)
            self.followButton.addTarget(self, action: #selector(self.unfollowRanking), for: .touchUpInside)
            
        }else{
            self.followButton.setTitle(MyStrings.follow.localized(), for: .normal)
            followButton.removeTarget(self, action: #selector(self.unfollowRanking), for: .touchUpInside)
            self.followButton.addTarget(self, action: #selector(self.followRanking), for: .touchUpInside)
        }
    }
    
    // MARK: Fetch image from URL
    private func fetchImage(){
        foodImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        foodImageView.sd_setImage(
        with: photoURL,
        placeholderImage: nil,//UIImage(named: "defaultBest"),
        options: [],
            completed: nil)

    }
    
    // MARK: update from database
    func updateTableFromDatabase(cityDBPath: String){
        restoPointsHandle.append((handle: SomeApp.dbRestoPoints.child(cityDBPath).observe(.value, with: { snapshot in
            // What to do if the list is empty
            guard snapshot.exists() else {
                self.thisRanking.append(Resto(key: "0",name: "placeholder"))
                self.restoRankTableView.reloadData()
                self.emptyListFlag = true
                return
            }
            var count = 0
            var tmpRestoList:[Resto] = []
            // I. Get the values
            for child in snapshot.children{
                if let snapChild = child as? DataSnapshot,
                    let value = snapChild.value as? [String:Any],
                    let points = value["points"] as? Int{
                    
                    var tmpReviewsNb = 0
                    if let reviewsNb = value ["reviews"] as? Int{
                        tmpReviewsNb = reviewsNb
                    }
                    // II. Get the restaurants
                    let dbPathForResto = self.currentCity.country + "/" + self.currentCity.state + "/" + self.currentCity.key + "/" + snapChild.key
                    SomeApp.dbResto.child(dbPathForResto).observeSingleEvent(of: .value, with: {shot in
                        let tmpResto = Resto(snapshot: shot)
                        if tmpResto != nil {
                            tmpResto!.nbPoints = points
                            tmpResto!.nbReviews = tmpReviewsNb
                            tmpRestoList.append(tmpResto!)
                        }
                        // Trick! If we have processed all children then we reload the Data
                        count += 1
                        if count == snapshot.childrenCount {
                            self.thisRanking = tmpRestoList
                            self.thisRanking.sort(by: {$0.nbPoints > $1.nbPoints})
                            self.restoRankTableView.reloadData()
                        }
                        
                    })
                    
                }
                
            }
            //
        }), dbPath: cityDBPath))
    }
    
    
    // MARK: Navigation
    @objc private func refreshData(_ sender: Any) {
        // If pull down the table, then refresh data
        restoRankTableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case BestRestosViewController.showRestoDetailSegue:
                if let cell = sender as? RestoRankTableViewCell,
                    let indexPath = tableView.indexPath(for: cell),
                    let seguedToResto = segue.destination as? MyRestoDetail{
                    // Segue
                    seguedToResto.currentResto = thisRanking[indexPath.row]
                    seguedToResto.currentCity = currentCity
                    seguedToResto.currentFood = currentFood
                    seguedToResto.seguer = MyRestoDetail.MyRestoSeguer.BestRestos
                }
            default: break
            }
        }
    }
}

// MARK: objc funcs
extension BestRestosViewController{
    
    @objc func followRanking(){
        SomeApp.followRanking(userId: user.uid, city: currentCity, foodId: currentFood.key)
        self.userFollowingRankingFlag = true
        configureFollowButton()
    }
    
    @objc func unfollowRanking(){
        let alert = UIAlertController(
            title: MyStrings.unfollow.localized() + "?",
            message: MyStrings.unfollowMsg.localized(),
            preferredStyle: .alert)
        // OK
        alert.addAction(UIAlertAction(
            title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
            style: .default,
            handler: {
                (action: UIAlertAction)->Void in
                //do nothing
        }))
        // Unfollow
        alert.addAction(UIAlertAction(
            title: MyStrings.unfollow.localized(),
            style: .destructive,
            handler: {
                (action: UIAlertAction)->Void in
                //Unfollow
                SomeApp.unfollowRanking(userId: self.user.uid, city: self.currentCity, foodId: self.currentFood.key)
                self.userFollowingRankingFlag = false
                self.configureFollowButton()
        }))
        present(alert, animated: false, completion: nil)
    }
}

// MARK: Table stuff
extension BestRestosViewController : UITableViewDelegate, UITableViewDataSource  {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            guard thisRanking.count > 0 else {return 1}
            if emptyListFlag{
                return 1
            }else{
                return thisRanking.count
            }
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            guard thisRanking.count > 0 else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = FoodzLayout.FoodzStrings.loading.localized()
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            guard !emptyListFlag else {
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = MyStrings.emptyTitle.localized()
                cell.detailTextLabel?.text = MyStrings.emptyMsg.localized()
                cell.selectionStyle = .none
                return cell
            }
            
            // Then go
            if let cell = tableView.dequeueReusableCell(withIdentifier: "RestoRankCell", for: indexPath) as? RestoRankTableViewCell {
 
                //Configure the cell
                let thisResto = thisRanking[indexPath.row]
                let tmpPosition = indexPath.row + 1
                
                // The position label
                cell.restoPositionLabel.layer.cornerRadius = 0.5 * cell.restoPositionLabel.bounds.width
                cell.restoPositionLabel.layer.borderColor = SomeApp.themeColor.cgColor
                cell.restoPositionLabel.layer.borderWidth = 1.0
                cell.restoPositionLabel.layer.masksToBounds = true
                cell.restoPositionLabel.text = String(tmpPosition)
                
                cell.restoNameLabel.text = thisResto.name
                
                cell.restoAddressLabel.text = thisResto.address
                let tmpPointsString = MyStrings.points.localized(arguments: thisResto.nbPoints)
                cell.restoPointsLabel.text = tmpPointsString
                let tmpReviewsString = MyStrings.reviews.localized(arguments: thisResto.nbReviews)
                cell.restoOtherInfoLabel.text = tmpReviewsString
                
                return cell
            }else{
                fatalError("BestRestos: cannot create cell")
            }
        }else if indexPath.section == 1{
                guard nativeAds.count > 0 else{
                    let spinnerCell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                    
                    spinnerCell.textLabel?.text = FoodzLayout.FoodzStrings.adPlaceholderShortTitle.localized()
                    spinnerCell.detailTextLabel?.text = FoodzLayout.FoodzStrings.adPlaceholderShortMsg.localized()
                    //spinnerCell.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
                    spinnerCell.imageView?.image = UIImage(named: "idea")
                    spinnerCell.selectionStyle = .none
                    return spinnerCell
                }
            
                let nativeAdCell = tableView.dequeueReusableCell(
                    withIdentifier: "UnifiedNativeAdCell", for: indexPath)
                configureAddCell(nativeAdCell: nativeAdCell)
                return(nativeAdCell)
            }else{
                fatalError("Cannot create cell")
            }
        }
    
    // MARK: Ad Cell
    func configureAddCell(nativeAdCell: UITableViewCell){
        guard nativeAds.count > 0 else {return}
        let nativeAd = nativeAds[0] // GADUnifiedNativeAd()
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
}

// MARK: Ad stuff
extension BestRestosViewController: GADBannerViewDelegate{
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

// MARK: ad Loader delegate
extension BestRestosViewController: GADUnifiedNativeAdLoaderDelegate{
    // Ad adds to table
    func addNativeAdds(){
        if nativeAds.count <= 0 {
          return
        }
        restoRankTableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
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


// MARK: Localized Strings
extension BestRestosViewController{
    private enum MyStrings {
        case headerTitle
        case follow
        case unfollow
        case followers
        case unfollowMsg
        case emptyTitle
        case emptyMsg
        case points
        case reviews
        case coolPhrase1
        case coolPhrase2
        case coolPhrase3
        case coolPhrase4
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .headerTitle:
                return String(
                format: NSLocalizedString("BESTRESTOS_HEADER_TITLE", comment: "Best"),
                locale: .current,
                arguments: arguments)
            case .follow:
                return String(
                format: NSLocalizedString("BESTRESTOS_FOLLOW", comment: "Follow"),
                locale: .current,
                arguments: arguments)
            case .unfollow:
                return String(
                format: NSLocalizedString("BESTRESTOS_UNFOLLOW", comment: "Unfollow"),
                locale: .current,
                arguments: arguments)
            case .followers:
                return String(
                format: NSLocalizedString("BESTRESTOS_FOLLOWERS", comment: "Followers"),
                locale: .current,
                arguments: arguments)
            case .unfollowMsg:
                return String(
                format: NSLocalizedString("BESTRESTOS_UNFOLLOW_MSG", comment: "Are you sure"),
                locale: .current,
                arguments: arguments)
            case .emptyTitle:
                return String(
                format: NSLocalizedString("BESTRESTOS_EMPTY_TITLE", comment: "Empty"),
                locale: .current,
                arguments: arguments)
            case .emptyMsg:
                return String(
                format: NSLocalizedString("BESTRESTOS_EMPTY_MSG", comment: "Can add"),
                locale: .current,
                arguments: arguments)
            case .points:
                return String(
                format: NSLocalizedString("BESTRESTOS_POINTS", comment: "Points"),
                locale: .current,
                arguments: arguments)
            case .reviews:
                return String(
                format: NSLocalizedString("BESTRESTOS_REVIEWS", comment: "Comments"),
                locale: .current,
                arguments: arguments)
            case .coolPhrase1:
                return String(
                    format: NSLocalizedString("BESTRESTOS_COOLPHRASE_1", comment: "Comments"),
                    locale: .current,
                    arguments: arguments)
            case .coolPhrase2:
                return String(
                    format: NSLocalizedString("BESTRESTOS_COOLPHRASE_2", comment: "Comments"),
                    locale: .current,
                    arguments: arguments)
            case .coolPhrase3:
                return String(
                    format: NSLocalizedString("BESTRESTOS_COOLPHRASE_3", comment: "Comments"),
                    locale: .current,
                    arguments: arguments)
            case .coolPhrase4:
                return String(
                    format: NSLocalizedString("BESTRESTOS_COOLPHRASE_4", comment: "Comments"),
                    locale: .current,
                    arguments: arguments)
            }
        }
    }
}
