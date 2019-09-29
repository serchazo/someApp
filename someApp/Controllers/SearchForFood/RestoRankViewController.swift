//
//  RestoRankViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class RestoRankViewController: UIViewController {
    private static var showRestoDetailSegue = "showRestoDetail"
    private static let screenSize = UIScreen.main.bounds.size
    
    var restoDatabaseReference: DatabaseReference!
    var restoPointsDatabaseReference: DatabaseReference!
    var thisRanking: [Resto] = []
    
    // Class Variables
    var currentCity: City!
    var currentFood: FoodType!
    let refreshControl = UIRefreshControl()

    /// Adds part
    private let numAdsToLoad = 5 //The number of native ads to load (between 1 and 5 for this example).
    private var nativeAds = [GADUnifiedNativeAd]() /// The native ads.
    private var adLoader: GADAdLoader!  /// The ad loader that loads the native ads.
    
    // MARK: outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var restoRankTableView: UITableView!{
        didSet{
            restoRankTableView.dataSource = self
            restoRankTableView.delegate = self
            restoRankTableView.refreshControl = refreshControl
        }
    }
    
    @IBOutlet weak var restoRankTableHeader: UIView!
    @IBOutlet weak var tableHeaderFoodIcon: UILabel!
    @IBOutlet weak var tableHeaderFoodName: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    // MARK: Selection stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize the references
        restoPointsDatabaseReference = SomeApp.dbRestoPoints.child(currentCity.country).child(currentCity.state).child(currentCity.key).child(currentFood.key)
        restoDatabaseReference = SomeApp.dbResto
        
        // Initialize the adds
        let options = GADMultipleAdsAdLoaderOptions()
        options.numberOfAds = numAdsToLoad
        
        // Prepare the ad loader and start loading ads.
        adLoader = GADAdLoader(adUnitID: SomeApp.adNativeUnitID,
                               rootViewController: self,
                               adTypes: [.unifiedNative],
                               options: [options])
        adLoader.delegate = self
        adLoader.load(GADRequest())
        
        //Some setup
        restoRankTableView.register(UINib(nibName: "UnifiedNativeAdCell", bundle: nil),
                                    forCellReuseIdentifier: "UnifiedNativeAdCell")
        restoRankTableView.tableHeaderView = restoRankTableHeader
        tableHeaderFoodIcon.text = currentFood.icon
        tableHeaderFoodName.text = "Best \(currentFood.name) restaurants in \(currentCity.name)"
        followButton.backgroundColor = SomeApp.themeColor
        followButton.setTitleColor(.white, for: .normal)
        followButton.setTitle("Follow", for: .normal)
        //followButton.addTarget(self, action: #selector(self.follow), for: .touchUpInside)
    
        //
        navigationItem.title = currentFood.icon
        
        updateTableFromDatabase()
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    ///
    func updateTableFromDatabase(){
        restoPointsDatabaseReference.observeSingleEvent(of: .value, with: { snapshot in
            var count = 0
            var tmpRestoList:[Resto] = []
            // I. Get the values
            for child in snapshot.children{
                if let snapChild = child as? DataSnapshot,
                    let points = snapChild.value as? Int{
                    // II. Get the restaurants
                    let dbPathForResto = self.currentCity.country + "/" + self.currentCity.state + "/" + self.currentCity.key + "/" + snapChild.key
                    self.restoDatabaseReference.child(dbPathForResto).observeSingleEvent(of: .value, with: {shot in
                        let tmpResto = Resto(snapshot: shot)
                        if tmpResto != nil {
                            tmpResto!.nbPoints = points
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
        })
    }
    
    
    ///
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when segued pops
        if let indexPath = restoRankTableView.indexPathForSelectedRow {
            restoRankTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        // If pull down the table, then refresh data
        updateTableFromDatabase()
        self.refreshControl.endRefreshing()
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case RestoRankViewController.showRestoDetailSegue:
                if let cell = sender as? RestoRankTableViewCell,
                    let indexPath = tableView.indexPath(for: cell),
                    let seguedToResto = segue.destination as? MyRestoDetail{
                    // Segue
                    seguedToResto.currentResto = thisRanking[indexPath.row]
                    seguedToResto.currentCity = currentCity
                }
            default: break
            }
        }
    }
}

// MARK: Table stuff
extension RestoRankViewController : UITableViewDelegate, UITableViewDataSource  {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }else{
            return thisRanking.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            guard nativeAds.count > 0 else{
                let spinnerCell = UITableViewCell(style: .default, reuseIdentifier: nil)
                spinnerCell.textLabel?.text = "Something good will appear here"
                spinnerCell.backgroundColor = #colorLiteral(red: 0.9983033538, green: 0.9953654408, blue: 0.8939318061, alpha: 1)
                
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                
                spinnerCell.accessoryView = spinner
                
                return spinnerCell
            }
            let nativeAdCell = tableView.dequeueReusableCell(
                withIdentifier: "UnifiedNativeAdCell", for: indexPath)
            configureAddCell(nativeAdCell: nativeAdCell)
            return(nativeAdCell)
        }else{
            if let cell = tableView.dequeueReusableCell(withIdentifier: "RestoRankCell", for: indexPath) as? RestoRankTableViewCell {
                //Configure the cell
                let thisResto = thisRanking[indexPath.row]
                cell.restoNameLabel.attributedText = NSAttributedString(string: thisResto.name, attributes: [.font : restorantNameFont])
                cell.restoPointsLabel.attributedText = NSAttributedString(string: "Points: \(thisResto.nbPoints)", attributes: [.font : restorantPointsFont])
                cell.restoOtherInfoLabel.attributedText = NSAttributedString(string: thisResto.city, attributes: [.font : restorantAddressFont])
                
                cell.decorateCell()
                
                return cell
            
            }else{
                fatalError("Marche pas.")
            }
        }
    }
    
    // MARK: Ad Cell
    func configureAddCell(nativeAdCell: UITableViewCell){
        guard nativeAds.count > 0 else {return}
        var nativeAd = nativeAds[0] // GADUnifiedNativeAd()
        /// Set the native ad's rootViewController to the current view controller.
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


// MARK: Some view stuff
extension RestoRankViewController{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = restorantNameFont.lineHeight + restorantAddressFont.lineHeight + restorantPointsFont.lineHeight + 65.0
        return CGFloat(cellHeight)
    }
    
    // MARK : Fonts
    private var restorantNameFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .title3).withSize(23.0))
    }
    
    private var restorantPointsFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
    
    private var restorantAddressFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
}

// MARK : Adds extension
extension RestoRankViewController: GADUnifiedNativeAdLoaderDelegate{
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        print("Received native ad: \(nativeAd)")
        
        // Add the native ad to the list of native ads.
        nativeAds.append(nativeAd)
        
        //
        let adIndexPath = IndexPath(row: 0, section: 0)
        restoRankTableView.beginUpdates()
        restoRankTableView.reloadRows(at: [adIndexPath], with: .automatic)
        restoRankTableView.endUpdates()
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
    
    
}
