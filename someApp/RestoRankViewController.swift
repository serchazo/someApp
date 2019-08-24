//
//  RestoRankViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class RestoRankViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ItemChooserViewDelegate {
    
    // Class Variables
    var currentCity: BasicCity = .Singapore{
        didSet{
            restoRankTableView.reloadData()
        }
    }
    var currentRestoList: [BasicResto]{
        get{
           return basicModel.getSomeRestoList(fromCity: currentCity)
        }
    }
    var currentFood: BasicFood!
    
    /* Table View Stuff */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentRestoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "RestoRankCell", for: indexPath) as? RestoRankTableViewCell {
            //Configure the cell
            let thisResto = currentRestoList[indexPath.row]
            cell.restoNameLabel.text = thisResto.restoName
            cell.restoShortDescLabel.text = thisResto.shortDescription
            cell.restoPointsLabel.text = "Points: \(thisResto.numberOfPoints)"
            cell.restoOtherInfoLabel.text = thisResto.otherInfo
            
            return cell
        }else{
            fatalError("Marche pas.")
        }
    }
    
    // MARK: outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var restoRankTableView: UITableView!{
        didSet{
            restoRankTableView.dataSource = self
            restoRankTableView.delegate = self
        }
    }
    
    @IBOutlet weak var restoRankTableHeader: UIView!
    
    // MARK: Selection stuff
    @IBOutlet weak var cityButton: UIButton!
    
    @IBAction func someSelector(_ sender: UIButton) {
        // TBD
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Some setup
        restoRankTableView.tableHeaderView = restoRankTableHeader
        print(currentFood.rawValue)
        print(currentCity)
        

    }
    
    //Broadcasting stuff
    func itemChooserReceiveItem(_ sender: Int, withType: BasicSelection) {
        print("hoa \(sender)")
    }
    func itemChooserReceiveCity(_ sender: BasicCity) {
        currentCity = sender
    }
    func itemChooserReceiveFood(_ sender: BasicFood) {
        print(sender.rawValue)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case "showRestoDetail":
                if let cell = sender as? RestoRankTableViewCell,
                    let indexPath = tableView.indexPath(for: cell),
                    let seguedToResto = segue.destination as? RestoDetailViewController{
                    //tmp
                    let text = currentRestoList[indexPath.row].restoName
                    // Segue
                    seguedToResto.titleCell = text
                }
            case "cityChoser":
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.setPickerValue(withData: .City)
                    seguedToCityChooser.delegate = self
                    
                }
            case "FoodChoser":
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.setPickerValue(withData: .Food)
                    seguedToCityChooser.delegate = self
                }
                
            default: break
            }
        }
    }


}
