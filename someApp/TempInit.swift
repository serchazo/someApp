//
//  tempInit.swift
//  someApp
//
//  Created by Sergio Ortiz on 29.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import UIKit

class TempInit : NSObject, CLLocationManagerDelegate {
    var restoList = [MKMapItem]()
    private var boundingRegion: MKCoordinateRegion?
    var matchingMapItems = [MKMapItem](){
        didSet{
            restoList.append(matchingMapItems[0])
            print("here")
        }
    }
    
    private var locationManager = CLLocationManager()
    
    override init(){
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        let location = locationManager.location
        boundingRegion = MKCoordinateRegion(center: location!.coordinate, latitudinalMeters: 12_000, longitudinalMeters: 12_000)
        
        //giveMeTheRestoList(for: ["Shake Shack","Black Tap", "Burger Joint"])
    }
    
    func giveMeTheRestoList(for restoListArray: [String])->[MKMapItem]{
        let tempQueue = DispatchQueue(label: "test")
        tempQueue.async {
            for resto in restoListArray{
                self.searchForResto(for: resto)
            }
        }
        /*
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                for resto in restoListArray{
                    self?.searchForResto(for: resto)
                }
                print("how?")
                DispatchQueue.main.async {
                    print(self?.matchingMapItems.count)
                }
                print("asdf")
            }*/
        print("how?")
        return restoList
    }
    
    //

    
    /// - Parameter queryString: A search string from the text the user entered into `UISearchBar`
    func searchForResto(for queryString: String) {
        print("temp \(queryString)")
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        searchRequest.region = boundingRegion!
        //
        let search = MKLocalSearch(request: searchRequest)
                search.start { response, _ in
                    guard let response = response else {
                        return
                    }
                    self.matchingMapItems.append(response.mapItems[0])
                }
    }
    
    private func displaySearchError(_ error: Error?) {
        if let error = error as NSError?, let errorString = error.userInfo[NSLocalizedDescriptionKey] as? String {
            print("Could not find any places: \(errorString)")
            }
    }
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        /*
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            
            let region = MKCoordinateRegion(
                center: location.coordinate, //The center of the region
                span: span) // The zoom level
            mapView.setRegion(region, animated: true)
        }*/
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
    
}
