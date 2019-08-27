//
//  MyRanksEditRankingViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class MyRanksEditRankingViewController: UIViewController {
    
    var currentCity: BasicCity!
    var currentFood: BasicFood!
    var currentRanking: BasicRanking?
    
    //Map vars
    //var locationManager = CLLocationManager()
    var resultSearchController:UISearchController? = nil
    var selectedPin: MKPlacemark? = nil
    
    //@IBOutlet weak var mapView: MKMapView!
    
    
    // Outlets
    @IBOutlet weak var editRankingTable: UITableView!{
        didSet{
            editRankingTable.dataSource = self
            editRankingTable.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MapKit stuff
        /*
         locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        // Permission dialog
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        */
        
        // Instantiate the search bar
        //let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! MyRanksSearchResultsTableViewController
        //resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        //resultSearchController?.searchResultsUpdater = locationSearchTable
        
        //searchViewController
        let locationSearchView = storyboard!.instantiateViewController(withIdentifier: "searchViewController") as! MyRanksMapSearchViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchView)
        resultSearchController?.searchResultsUpdater = locationSearchView
        
        //Set up the search bar
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        
        //Configure the search controller appearance
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        //link to the mapView
        //locationSearchTable.mapView = mapView
        //locationSearchView.mapView = mapView
        
        //for the pin
        //locationSearchTable.handleMapSearchDelegate = self
    }

}

// MARK: Extension for the Table stuff
extension MyRanksEditRankingViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentRanking != nil {
            return currentRanking!.restoList.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath) as? MyRanksEditRankingTableViewCell,
            currentRanking != nil {
            cell.restoImage.text = "Pic"
            cell.restoName.text = currentRanking!.restoList[indexPath.row].restoName
            cell.restoImage.text = "Some info."
            
            return cell
        }else{
            fatalError("Marche pas.")
        }
    }
}

/*
// MARK: Extension for the CLLocationManagerDelegate
extension MyRanksEditRankingViewController : CLLocationManagerDelegate{
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            
            let region = MKCoordinateRegion(
                center: location.coordinate, //The center of the region
                span: span) // The zoom level
            mapView.setRegion(region, animated: false)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
    
}
*/
