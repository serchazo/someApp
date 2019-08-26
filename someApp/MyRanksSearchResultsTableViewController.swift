//
//  MyRanksSearchResultsTableViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 26.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit

class MyRanksSearchResultsTableViewController: UITableViewController {

    var matchingMapItems: [MKMapItem] = []
    var mapView: MKMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source
    //override func numberOfSections(in tableView: UITableView) -> Int {
    //    return 1
    //}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingMapItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier")!
     let selectedItem = matchingMapItems[indexPath.row].placemark
     cell.textLabel?.text = selectedItem.name
     //cell.detailTextLabel?.text = ""
     cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
     return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingMapItems[indexPath.row].placemark
        print("\(matchingMapItems[indexPath.row].phoneNumber!)")
        print("\(matchingMapItems[indexPath.row].description)")
        print("\(matchingMapItems[indexPath.row].name!)")
        print("\(matchingMapItems[indexPath.row].url!)")
        print("\(matchingMapItems[indexPath.row].placemark)")
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

extension MyRanksSearchResultsTableViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else { return }
        
        //TODO: Point of Interst filter should be here
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
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
