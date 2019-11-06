//
//  AppDelegate.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let locationManagerT = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase config
        FirebaseApp.configure()
        
        // Facebook login config
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    
        // Set the colors of navigation bar
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.tintColor = SomeApp.themeColor // Butons color
        navigationBarAppearace.barTintColor = .white //Background color
        navigationBarAppearace.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: SomeApp.themeColor,
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)]
        
        // Location stuff
        locationManagerT.requestWhenInUseAuthorization()
        locationManagerT.delegate = self
        locationManagerT.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManagerT.requestLocation()
        
        return true
    }
    
    // For Facebook login
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        //guard let urlScheme = url.scheme else { return false }
        //if urlScheme.hasPrefix("fb") {
            return ApplicationDelegate.shared.application(app, open: url, options: options)
        //}
        //return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}


// MARK: Location stuff
extension AppDelegate: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // We assign to the SomeApp location
        SomeApp.currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //
        print("Can't get location.")
    }
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .authorizedWhenInUse || status != .authorizedAlways {
            locationManagerT.requestLocation()
        }
    }
}
