//
//  FirstLoginThirdScreen.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 11.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class FirstLoginThirdScreen: UIViewController {
    private let segueCityOK = "segueCityOK"
    private let cityChooserSegueID = "chooseCity"
    
    private var cityChosenFlag = false
    private var currentCity: City!
    private var currentCountryName: String!
    private var currentStateName: String!
    
    // Get from segue-r
    var username:String!
    var photoURL: URL!

    @IBOutlet weak var titleLabel: UILabel!{
        didSet{
            titleLabel.text = MyStrings.title.localized()
        }
    }
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var cityTextField: UITextField!{
        didSet{
            cityTextField.isEnabled = true
            cityTextField.delegate = self
        }
    }
    @IBOutlet weak var selectCityButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        // Do any additional setup after loading the view.
        
    }
    
    //
    private func configureButtons(){
        FoodzLayout.configureButtonNoBorder(button: selectCityButton)
        FoodzLayout.configureButton(button: goButton)
        goButton.setTitle(MyStrings.buttonGo.localized(), for: .normal)
        goButton.addTarget(self, action: #selector(goButtonPressed), for: .touchUpInside)
        
        if !cityChosenFlag{
            selectCityButton.setTitle(MyStrings.buttonSelect.localized(), for: .normal)
        }else{
            selectCityButton.setTitle(MyStrings.buttonChange.localized(), for: .normal)
        }
    }
    
    //MARK: objc func
    // If the Go button is pressed,
    @objc func goButtonPressed(){
        if cityChosenFlag{
            self.performSegue(withIdentifier: self.segueCityOK, sender: nil)
        }else{
            let alert = UIAlertController(
                title: MyStrings.popupTitle.localized(),
                message: MyStrings.popupMsg.localized(),
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonOK.localized(), style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert,animated: true)
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if segue.identifier == self.cityChooserSegueID,
        let destinationSegueVC = segue.destination as? ItemChooserViewController {
            destinationSegueVC.firstLoginFlag = true
            destinationSegueVC.delegate = self
            
        }else if segue.identifier == self.segueCityOK,
            let seguedVC = segue.destination as? FirstLoginFourthScreen{
            seguedVC.currentCity = currentCity
            seguedVC.currentCountryName = currentCountryName
            seguedVC.currentStateName = currentStateName
            seguedVC.userName = username
            seguedVC.photoURL = photoURL
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == cityChooserSegueID{
            return true
        }else{
            return false
        }
    }
}

// MARK: Edit text field delegate
extension FirstLoginThirdScreen: UITextFieldDelegate{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == cityTextField{
            self.performSegue(withIdentifier: self.cityChooserSegueID, sender: nil)
            return false
        }else{
            return true
        }
    }
}

// MARK: Get the city from the City Chooser
extension FirstLoginThirdScreen: ItemChooserViewDelegate {
    func itemChooserReceiveCity(city: City, countryName: String, stateName: String) {
        currentCity = city
        currentCountryName = countryName
        currentStateName = stateName
        cityTextField.text = city.name + ", " + countryName
        cityTextField.placeholder = city.name
        cityChosenFlag = true
        configureButtons()
    }
}


// MARK: Localized Strings
extension FirstLoginThirdScreen{
    private enum MyStrings {
        case title
        case buttonGo
        case buttonSelect
        case buttonChange
        case popupTitle
        case popupMsg
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .title:
                return String(
                format: NSLocalizedString("FIRSTLOG3_TITLE", comment: "Configure"),
                locale: .current,
                arguments: arguments)
            case .buttonGo:
                return String(
                format: NSLocalizedString("FIRSTLOG3_BUTTON_GO", comment: "OK"),
                locale: .current,
                arguments: arguments)
            case .buttonSelect:
                return String(
                format: NSLocalizedString("FIRSTLOG3_BUTTON_SELECT", comment: "Select"),
                locale: .current,
                arguments: arguments)
            case .buttonChange:
                return String(
                format: NSLocalizedString("FIRSTLOG3_BUTTON_CHANGE", comment: "Change"),
                locale: .current,
                arguments: arguments)
            case .popupTitle:
                return String(
                format: NSLocalizedString("FIRSTLOG3_POPUP_TITLE", comment: "Nothing"),
                locale: .current,
                arguments: arguments)
            case .popupMsg:
                return String(
                format: NSLocalizedString("FIRSTLOG3_POPUP_MSG", comment: "Can change"),
                locale: .current,
                arguments: arguments)
            }
        }
    }
}
