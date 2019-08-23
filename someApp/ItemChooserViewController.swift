//
//  CityChooserViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

protocol ItemChooserViewDelegate: class{
    func itemChooserReceiveItem(_ sender: Int)
}

class ItemChooserViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        self.delegate?.itemChooserReceiveItem(selectedRow)
        print("test \(selectedRow)")
    }
}
