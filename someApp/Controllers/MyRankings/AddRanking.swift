//
//  AddRanking.swift
//  someApp
//
//  Created by Sergio Ortiz on 07.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

protocol AddRankingDelegate: class{
    func addRankingReceiveInfoToCreate(city: City, withFood: FoodType)
}

class AddRanking: UIViewController {
    
    //Constants
    private let chooseFoodCellId = "ChooseFoodCell"
    private let segueCityChoser = "cityChoser"
    
    // Get from segue-r
    var currentCity: City!
    
    // The delagate
    weak var delegate: AddRankingDelegate!
    
    // Class variables
    private var foodList:[FoodType] = []
    
    // Table header
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var changeCityButton: UIButton!
    
    @IBOutlet weak var currentCityLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var addRankingTableView: UITableView!{
        didSet{
            addRankingTableView.delegate = self
            addRankingTableView.dataSource = self
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureHeader()
        // The data
        loadFoodTypesFromDB()
        
    }
    

    /*
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == self.segueCityChoser,
            let cityChoserMVC = segue.destination as? ItemChooserViewController{
            cityChoserMVC.delegate = self
        }
        
    }
    */
    

}

// MARK: configure header
extension AddRanking{
    private func configureHeader(){
        // Navigation bar
        self.navigationItem.title = "Add a ranking"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // title
        headerTitle.text = "Choose food type"
        
        // current city
        currentCityLabel.text = "City: \(currentCity.name)"
        
    }
}

// MARK: Get stuff from DB
extension AddRanking{
    // Get the stuff from the DB
    func loadFoodTypesFromDB(){
        // Get the list from the Database (an observer)
        SomeApp.dbFoodTypeRoot.child(currentCity.country).observeSingleEvent(of: .value, with: {snapshot in
            var tmpFoodList: [FoodType] = []
            var count = 0
            
            for child in snapshot.children{
                if let childSnapshot = child as? DataSnapshot,
                    let foodItem = FoodType(snapshot: childSnapshot){
                    tmpFoodList.append(foodItem)
                }
                // Use the trick
                count += 1
                if count == snapshot.childrenCount{
                    self.foodList = tmpFoodList
                    self.addRankingTableView.reloadData()
                }
            }
            
        })
    }
}

// MARK: Table stuff
extension AddRanking: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard foodList.count > 0 else {
            return 1
        }
        return foodList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard foodList.count > 0 else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Loading food types for \(currentCity.country)"
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            cell.accessoryView = spinner
            return cell
        }
        let cell = addRankingTableView.dequeueReusableCell(withIdentifier: chooseFoodCellId, for: indexPath)
        cell.textLabel?.text = foodList[indexPath.row].icon
        cell.detailTextLabel?.text = foodList[indexPath.row].name
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.addRankingReceiveInfoToCreate(city: currentCity, withFood: foodList[indexPath.row])
        
        self.navigationController?.popViewController(animated: true)
    }
}


