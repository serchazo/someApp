//
//  MyRanksMapSearchViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 27.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit

class MyRanksMapSearchViewController: UIViewController {
    var matchingMapItems: [MKMapItem] = []
    //var mapView: MKMapView?
    var locationManager = CLLocationManager()
    
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var searchResultsTable: UITableView!{
        didSet{
            searchResultsTable.dataSource = self
            searchResultsTable.delegate = self
        }
    }
    @IBOutlet weak var coolMap: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        // Permission dialog
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}

// MARK : table stuff
extension MyRanksMapSearchViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingMapItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell")!
        let selectedItem = matchingMapItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        //cell.detailTextLabel?.text = ""
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingMapItems[indexPath.row].placemark
        //print("\(selectedItem.phoneNumber!)")
        //print("\(selectedItem.description)")
        //print("\(selectedItem.name!)")
        //print("\(selectedItem.url!)")
        print("\(selectedItem)")
        //handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
        dismiss(animated: true, completion: nil)
    }
    
    //TODO: Improve this one
    func parseAddress(selectedItem:MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil &&
            selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) &&
            (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil &&
            selectedItem.administrativeArea != nil) ? ", " : " "
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
}

extension MyRanksMapSearchViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let coolMap = coolMap,
            let searchBarText = searchController.searchBar.text else { return }
        
        //TODO: Point of Interst filter should be here
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = coolMap.region
        //request.pointOfInterestFilter = MKPointsOfInterestFilter(including: [.restaurant])
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingMapItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

// MARK: Location stuff
extension MyRanksMapSearchViewController: CLLocationManagerDelegate{
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
            coolMap.setRegion(region, animated: false)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
}
