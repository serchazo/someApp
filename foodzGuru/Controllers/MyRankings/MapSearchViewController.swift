//
//  MyRanksMapSearchViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 27.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

protocol MyRanksMapSearchViewDelegate: class{
    func restaurantChosenFromMap(someMapItem: MKMapItem)
}

class MapSearchViewController: UIViewController {
    var matchingMapItems: [MKMapItem]? {
        didSet {
            tableView.reloadData()
            //viewAllButton.isEnabled = matchingMapItems != nil
        }
    }
    
    var currentLocation = CLLocation()
    var selectedPin: MKPlacemark? = nil
    var resultSearchController:UISearchController!
    private var suggestionController: SuggestionsTableTableViewController!
    //private var locationManagerObserver: NSKeyValueObservation?
    private var foregroundRestorationObserver: NSObjectProtocol?
    
    //Delegate var
    weak var delegate: MyRanksMapSearchViewDelegate!
    
    private var boundingRegion: MKCoordinateRegion?
    private var localSearch: MKLocalSearch? {
        willSet {
            // Clear the results and cancel the currently running local search before starting a new search.
            matchingMapItems = nil
            localSearch?.cancel()
        }
    }
    
    //@IBOutlet private var locationManager: LocationManager!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var searchResultsTable: UITableView!{
        didSet{
            searchResultsTable.dataSource = self
            searchResultsTable.delegate = self
        }
    }
    @IBOutlet weak var coolMap: MKMapView!
    
    //MARK: timeline funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        suggestionController = SuggestionsTableTableViewController()
        suggestionController.tableView.delegate = self
        
        resultSearchController = UISearchController(searchResultsController: suggestionController)
        resultSearchController.searchResultsUpdater = suggestionController
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for your fav restorant"
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.titleView = resultSearchController?.searchBar
        definesPresentationContext = true
        
        // If we have a location, then we only search for nearby locations
        if let location = SomeApp.currentLocation {
            
            //let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 12_000, longitudinalMeters: 12_000)
            coolMap.setRegion(region, animated: true)
            suggestionController.searchCompleter.region = region
            boundingRegion = region
            
            resultSearchController.searchBar.isUserInteractionEnabled = true
            resultSearchController.searchBar.alpha = 1.0
            
            tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: Some search functions
    private func search(for suggestedCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        search(using: searchRequest)
    }
    
    /// - Parameter queryString: A search string from the text the user entered into `UISearchBar`
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        // Confine the map search area to an area around the user's current location.
        if boundingRegion != nil {
            searchRequest.region = boundingRegion!
        }
        
        // Use the network activity indicator as a hint to the user that a search is in progress.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [weak self] (response, error) in
            guard error == nil else {
                self?.displaySearchError(error)
                return
            }
            
            self?.matchingMapItems = response?.mapItems
            
            //coolMap
            let tmpPlacemark = self?.matchingMapItems?[0].placemark
            var region = self?.boundingRegion
            region?.center = (tmpPlacemark?.coordinate)!
            self?.coolMap.region = region!
            self?.dropPinZoomIn(placemark: tmpPlacemark!)
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    private func displaySearchError(_ error: Error?) {
        if let error = error as NSError?, let errorString = error.userInfo[NSLocalizedDescriptionKey] as? String {
            let alertController = UIAlertController(title: "Could not find any places.", message: errorString, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: table stuff
extension MapSearchViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard SomeApp.currentLocation != nil else { return 1 }
        return matchingMapItems?.count ?? 0
        //return matchingMapItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //If we are waiting^^
        guard SomeApp.currentLocation != nil else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("LOCATION_SERVICES_WAITING", comment: "Waiting for location table cell")
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell")!
        let selectedItem = matchingMapItems?[indexPath.row].placemark
        cell.textLabel?.text = selectedItem?.name
        cell.detailTextLabel?.text = selectedItem!.formattedAddress
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView == suggestionController.tableView, let suggestion = suggestionController.completerResults?[indexPath.row] {
            resultSearchController.isActive = false
            resultSearchController.searchBar.text = suggestion.title
            search(for: suggestion)
            
        }else if tableView == self.tableView{
            let selectedItem = matchingMapItems?[indexPath.row]
            self.delegate?.restaurantChosenFromMap(someMapItem: selectedItem!)
            self.navigationController?.popViewController(animated: true)
        }
        
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

// MARK: Location stuff
extension MapSearchViewController: CLLocationManagerDelegate{
    
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

extension MapSearchViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        coolMap.removeAnnotations(coolMap.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        coolMap.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        coolMap.setRegion(region, animated: true)
    }
}

// MARK: search bar delegate stuff
extension MapSearchViewController: UISearchBarDelegate{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        // The user tapped search on the `UISearchBar` or on the keyboard. Since they didn't
        // select a row with a suggested completion, run the search with the query text in the search field.
        search(for: searchBar.text)
    }
}
