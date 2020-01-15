//
//  MyRanksHeader.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 14.01.20.
//  Copyright © 2020 sergioortiz.com. All rights reserved.
//

import UIKit
import SDWebImage
import GoogleMobileAds

class MyRanksHeader: UICollectionReusableView {
    
    var photoURL: URL!{
        didSet{
            fetchImage()
        }
    }
    // Ad stuff
    private var bannerView: GADBannerView!
    
    @IBOutlet weak var profilePictureImage: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!{
        didSet{
            followButton.isHidden = true
            followButton.isEnabled = false
        }
    }
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var changeCityButton: UIButton!
    
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
}

extension MyRanksHeader{
    //
    private func fetchImage(){
        FoodzLayout.configureProfilePicture(imageView: profilePictureImage)
        
        profilePictureImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
        profilePictureImage.sd_setImage(
        with: photoURL,
        placeholderImage: UIImage(named: "userdefault"),
        options: [],
        completed: nil)
        
        
    }
}

// MARK: Ad Stuff
extension MyRanksHeader: GADBannerViewDelegate{
    // Initial configuration
    func configureBannerAd(){
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self.window?.rootViewController
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
