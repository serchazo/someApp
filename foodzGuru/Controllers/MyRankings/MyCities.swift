//
//  MyCities.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 07.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

protocol MyCitiesDelegate: class{
    func myCitiesChangeCity(_ sender: City)
}

class MyCities: UIViewController {
    
    var calledUser:UserDetails?
    var user:User!
    
    private var cityList: [(city: City, countryName:String, stateName:String)] = []
    private let segueAddCityId = "addCity"
    private let addCityCellId = "addCityCell"
    private var emptyListFlag = false
    
    // MARK: Broadcast messages
    weak var myCitiesDelegate: MyCitiesDelegate!

    @IBOutlet weak var myCitiesTableView: UITableView!{
        didSet{
            myCitiesTableView.delegate = self
            myCitiesTableView.dataSource = self
        }
    }
    
    // MARK: timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // deselect row
        if let indexPath = myCitiesTableView.indexPathForSelectedRow {
            myCitiesTableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // I. Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            var thisUserId:String
            if self.calledUser == nil{
                thisUserId = user.uid
            }else{
                thisUserId = self.calledUser!.key
            }
            
            self.getGeographyPerClient(userId: thisUserId)
        }
        
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == segueAddCityId,
            let seguedCityChooser = segue.destination as? ItemChooserViewController{
            seguedCityChooser.delegate = self
        }
    }
}

// MARK: get cities for user from DB
extension MyCities{
    private func getGeographyPerClient(userId: String){
        let tmpRef = SomeApp.dbUserRankingGeography.child(userId)
        
        // The vars inside so they reset
        tmpRef.observe(.value, with: {snapshot in
            
            if !snapshot.exists(){
                // If we don't have a ranking, mark the empty list flag
                self.emptyListFlag = true
                self.myCitiesTableView.reloadData()
            }else{
                
                self.emptyListFlag = false
                var countryCount = 0
                var stateCount = 0
                var cityCount = 0
                
                var tmpCityList: [(city: City, countryName:String, stateName:String)] = []
                // Get country key
                for child in snapshot.children{
                    if let countrySnap = child as? DataSnapshot{
                        let countryKey = countrySnap.key
                        // Count the countries
                        countryCount += 1
                        // Get the states
                        for countryChild in countrySnap.children{
                            if let stateSnap = countryChild as? DataSnapshot{
                                let stateKey = stateSnap.key
                                // If the last country, count the states
                                if countryCount == snapshot.childrenCount{
                                    stateCount += 1
                                }
                                // Get the cities and the data
                                for stateChild in stateSnap.children{
                                    if let citySnap = stateChild as? DataSnapshot,
                                        let value = citySnap.value as? [String:AnyObject],
                                        let cityName = value["name"] as? String,
                                        let stateName = value["state"] as? String,
                                        let countryName = value["country"] as? String{
                                        // Add the city to the Array
                                        let cityKey = citySnap.key
                                        let tmpCity = City(country: countryKey, state: stateKey, key: cityKey, name: cityName)
                                        tmpCityList.append((city:tmpCity, countryName: countryName, stateName: stateName))
                                        // If the last state in the last country, count the cities
                                        if countryCount == snapshot.childrenCount &&
                                            stateCount == countrySnap.childrenCount{
                                            cityCount += 1
                                            if cityCount == stateSnap.childrenCount{
                                                self.cityList = tmpCityList
                                                self.myCitiesTableView.reloadData()
                                            }
                                        }
                                    }
                                } // End for
                            }
                        }
                    }
                }
            }// End verification of snapshot.exists()
        })
    }
}

// MARK: table stuff
extension MyCities: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        if calledUser == nil{
            return 2
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1{
            return 1
        }else{
            guard cityList.count > 0 else{return 1}
            if emptyListFlag == true{
                return 1
            }else{
                return cityList.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1{
            let cell = myCitiesTableView.dequeueReusableCell(withIdentifier: addCityCellId, for: indexPath)
            
            return cell
        }else{
            // The cities list
            guard cityList.count > 0 || emptyListFlag else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Getting cities for user"
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            // Verify if the city list is empty
            if emptyListFlag{
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "No rankings in yet!"
                cell.detailTextLabel?.text = "Click on + and tell the world your favorite places to grab a bite !"
                cell.selectionStyle = .none
                return cell
            }
            // If it's not, then
            else{
                
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                let cellText = cityList[indexPath.row].city.name + ", " + cityList[indexPath.row].stateName + ", " + cityList[indexPath.row].countryName
                cell.textLabel?.text = cellText
                return cell
            }
        }
    }
    
    // Selected city
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get city and send to delegate - only for the section containing the cities
        if tableView == myCitiesTableView && indexPath.section == 0 && !emptyListFlag{
            let chosenCity = cityList[indexPath.row].city
            self.myCitiesDelegate?.myCitiesChangeCity(chosenCity)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: city choser extension
extension MyCities: ItemChooserViewDelegate{
    func itemChooserReceiveCity(city: City, countryName: String, stateName: String) {
        if (cityList.filter {$0.city.key == city.key}).count == 0{
            // Add to user ranking
            SomeApp.addUserCity(userId: user.uid, city: city, countryName: countryName, stateName: stateName)
        }else{
            // Ranking already in list
            let alert = UIAlertController(
                title: "Duplicate City",
                message: "You already have rankings in \(city.name).",
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: {
                    (action: UIAlertAction)->Void in
                    // deselect row
                    
                    if let indexPath = self.myCitiesTableView.indexPathForSelectedRow {
                        self.myCitiesTableView.deselectRow(at: indexPath, animated: true)
                    }
                    //
            }))
            present(alert, animated: false, completion: nil)
        }
    }
}
