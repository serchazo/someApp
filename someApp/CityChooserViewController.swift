//
//  CityChooserViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class CityChooserViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        print("test")
    }
    
    @IBOutlet weak var picker: UIPickerView!{
        didSet{
            picker.dataSource = self
            picker.delegate = self
        }
    }
    
    
    /* UIPicker stuff */
    var pickerData = ["",""]
    var selectedRow = 0
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func setPickerValue(withData: BasicSelection){
        switch(withData){
        case .City: pickerData = BasicCity.allCases.map {$0.rawValue}
        case .Food: pickerData = BasicFood.allCases.map {$0.rawValue}
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
        print("test \(selectedRow)")
    }
    

}
