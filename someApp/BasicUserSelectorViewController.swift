//
//  BasicUserSelectorViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 24.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class BasicUserSelectorViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return basicModel.userList.count
    }
    
    //Set picker values
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return basicModel.userList[row].userName
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var userPicker: UIPickerView!{
        didSet{
            userPicker.dataSource = self
            userPicker.delegate = self
        }
    }
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
