//
//  CityChooserViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

protocol ItemChooserViewDelegate: class{
    func itemChooserReceiveCity(city: City, countryName: String, stateName: String)
}

class ItemChooserViewController: UIViewController {
    
    // Control var
    var firstLoginFlag = false
    
    private var screenSize = UIScreen.main.bounds.size
    private var selectedCountryName: String!
    private var cityList: [(city: City, stateName: String)] = []
    private var countryList: [(key:String, name:String)] = []
    
    // MARK: Broadcast messages
    weak var delegate: ItemChooserViewDelegate?
    
    @IBOutlet weak var countryTable: UITableView!{
        didSet{
            countryTable.delegate = self
            countryTable.dataSource = self
        }
    }
    // City chooser
    private var transparentView = UIView()
    private var cityTable = UITableView()
    
    // MARK: timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cityTable.delegate = self
        cityTable.dataSource = self
        
        getCountryListFromDB()
        if firstLoginFlag{
            setCountryTableHeader()
        }
        
    }
    
    
    // MARK: Get values from DB
    private func getCountryListFromDB(){
        // Get the list of countries
        var count = 0
        var tmpCountries: [(key:String, name:String)] = []
        SomeApp.dbGeographyCountry.observeSingleEvent(of: .value, with: {snapshot in
            for child in snapshot.children{
                if let countrySnap = child as? DataSnapshot,
                    let countryName = countrySnap.value as? String {
                    let countryKey = countrySnap.key
                    tmpCountries.append((key: countryKey,name:countryName))
                    count += 1
                    if count == snapshot.childrenCount{
                        self.countryList = tmpCountries
                        self.countryTable.reloadData()
                    }
                }
            }
        })
        
    }
    
    private func getCityListFromDB(countryKey: String){
        var count = 0
        var tmpCities:[(city:City, stateName: String)] = []
        //I. top level is states
        SomeApp.dbGeographyStates.child(countryKey).observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                if let stateSnap = child as? DataSnapshot{
                    let state = stateSnap.key
                    let stateName = stateSnap.value
        
                    // II. Now look for Cities
                    SomeApp.dbGeography.child(countryKey).child(state).observeSingleEvent(of: .value, with: {snap in
                        for cityChild in snap.children{
                            if let citySnap = cityChild as? DataSnapshot{
                                let cityKey = citySnap.key
                                if let cityDetails = citySnap.value as? [String:AnyObject],
                                    let cityName = cityDetails["name"] as? String {
                                    tmpCities.append((city: City(name: cityName, state: state, country: countryKey, key: cityKey), stateName: stateName as! String))
                                }
                            }
                        }
                        count += 1
                        if count == snapshot.childrenCount{
                            self.cityList = tmpCities
                            self.cityTable.reloadData()
                        }
                    })
                }
                
            }
        })
    }
    
}
// MARK: Other funcs
extension ItemChooserViewController{
    func setCountryTableHeader(){
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = SomeApp.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        labelView.text = "Choose your country"
        
        headerView.addSubview(labelView)
        
        countryTable.tableHeaderView = headerView
    }
    // Same for cities
    func setCityTableHeader(){
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = SomeApp.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        labelView.text = "Choose your city"
        
        headerView.addSubview(labelView)
        
        cityTable.tableHeaderView = headerView
    }
    
    
    // Set the city view
    func showCityTable(){
        // Create the frame
        let window = UIApplication.shared.keyWindow
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        transparentView.frame = self.view.frame
        window?.addSubview(transparentView)
        
        // Add the table
        cityTable.frame = CGRect(
            x: 0,
            y: screenSize.height,
            width: screenSize.width,
            height: screenSize.height)
        window?.addSubview(cityTable)
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickTransparentView))
        transparentView.addGestureRecognizer(tapGesture)
        
        // Cool "slide-up" animation when appearing
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0.7 //Start at 0, go to 0.5
                        self.cityTable.frame = CGRect(
                            x: 0,
                            y: self.screenSize.height * 0.1,
                            width: self.screenSize.width,
                            height: self.screenSize.height)
        },
                       completion: nil)
    }
    
    //Disappear!
    @objc func onClickTransparentView(){
        // Animation when disapearing
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0 //Start at value above, go to 0
                        self.cityTable.frame = CGRect(
                            x: 0,
                            y: self.screenSize.height ,
                            width: self.screenSize.width * 0.9,
                            height: self.screenSize.height * 0.9)
                        
        },
                       completion: nil)
        
        // Deselect the row to go back to normal
        if let indexPath = countryTable.indexPathForSelectedRow {
            countryTable.deselectRow(at: indexPath, animated: true)
        }

    }
}


// MARK: Table stuff
extension ItemChooserViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == countryTable{
        guard countryList.count > 0 else{
            return 1
        }
        return countryList.count
        }else{
            // City Table
            guard cityList.count > 0 else{
                return 1
            }
            return cityList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // If country Table
        if tableView == countryTable{
            guard countryList.count > 0 else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Loading country list"
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = countryList[indexPath.row].name
            return cell
            // If city table
        }else{
            guard cityList.count > 0 else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Loading cities"
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let tmpCellText = cityList[indexPath.row].city.name + ", " + cityList[indexPath.row].stateName
            cell.textLabel?.text = tmpCellText
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // First choose your country
        if tableView == countryTable{
            selectedCountryName = countryList[indexPath.row].name
            getCityListFromDB(countryKey: countryList[indexPath.row].key)
            setCityTableHeader()
            showCityTable()
        }else{
            // Then choose your city
            let chosenCity = cityList[indexPath.row].city
            self.delegate?.itemChooserReceiveCity(city: chosenCity, countryName: selectedCountryName, stateName: cityList[indexPath.row].stateName)
            
            onClickTransparentView()
            
            if firstLoginFlag{
                self.dismiss(animated: true, completion: nil)
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    
}
