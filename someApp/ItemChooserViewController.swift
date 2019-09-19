//
//  CityChooserViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

protocol ItemChooserViewDelegate: class{
    func itemChooserReceiveCity(_ sender: City)
}

class ItemChooserViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource {
    //var pickerData = ["",""]
    var selectedRow = 0
    var pickerData: [City] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        updatePickerDataFromDB()
        
        
    }
    
    private func updatePickerDataFromDB(){
        var count = 0
        var tmpCities:[City] = []
        //I. top level is countries
        SomeApp.dbGeography.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                if let countrySnap = child as? DataSnapshot{
                    let country = countrySnap.key
                    // II. Now look for States
                    for countryChild in countrySnap.children{
                        if let stateSnap = countryChild as? DataSnapshot{
                            let state = stateSnap.key
                            // Finally, look for cities
                            for stateChild in stateSnap.children{
                                if let citySnap = stateChild as? DataSnapshot{
                                    let cityKey = citySnap.key
                                    if let cityDetails = citySnap.value as? [String:AnyObject],
                                        let cityName = cityDetails["name"] as? String {
                                        tmpCities.append(City(name: cityName, state: state, country: country, key: cityKey))
                                    }

                                }
                            }
                        }
                    }
                }
                count += 1
                if count == snapshot.childrenCount{
                    self.pickerData = tmpCities
                    self.picker.reloadAllComponents()
                }
            }
        })
    }
    
    // Broadcast messages
    weak var delegate: ItemChooserViewDelegate?
    
    // MARK: UIPicker stuff
    @IBOutlet weak var picker: UIPickerView!{
        didSet{
            picker.dataSource = self
            picker.delegate = self
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // Set picker values
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
        let possibleCity = pickerData[row]
        self.delegate?.itemChooserReceiveCity(possibleCity)
    }
}
