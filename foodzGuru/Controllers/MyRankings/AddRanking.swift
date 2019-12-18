//
//  AddRanking.swift
//  foodzGuru
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
    
    //Dynamic header height.  Snippet from : https://useyourloaf.com/blog/variable-height-table-view-header/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = addRankingTableView.tableHeaderView else {
            return
        }

        // The table view header is created with the frame size set in
        // the Storyboard. Calculate the new size and reset the header
        // view to trigger the layout.
        // Calculate the minimum height of the header view that allows
        // the text label to fit its preferred width.
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height

            // Need to set the header view property of the table view
            // to trigger the new layout. Be careful to only do this
            // once when the height changes or we get stuck in a layout loop.
            addRankingTableView.tableHeaderView = headerView

            // Now that the table view header is sized correctly have
            // the table view redo its layout so that the cells are
            // correcly positioned for the new header size.
            // This only seems to be necessary on iOS 9.
            addRankingTableView.layoutIfNeeded()
        }
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
        self.navigationItem.title = MyStrings.navbarTitle.localized()
        
        // title
        headerTitle.text = MyStrings.headerTitle.localized()
        
        // current city
        currentCityLabel.text = MyStrings.headerCity.localized(arguments:currentCity.name)
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
            cell.textLabel?.text = FoodzLayout.FoodzStrings.loading.localized()
            let spinner = UIActivityIndicatorView(style: .medium)
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

// MARK: Localized Strings
extension AddRanking{
    private enum MyStrings {
        case navbarTitle
        case headerTitle
        case headerCity
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .navbarTitle:
                return String(
                    format: NSLocalizedString("ADDRANKING_NAVBAR_TITLE", comment: "Add"),
                    locale: .current,
                    arguments: arguments)
            case .headerTitle:
                return String(
                    format: NSLocalizedString("ADDRANKING_HEADER_TITLE", comment: "Add"),
                    locale: .current,
                    arguments: arguments)
            case .headerCity:
                return String(
                    format: NSLocalizedString("ADDRANKING_HEADER_CITY", comment: "city"),
                    locale: .current,
                    arguments: arguments)
            }
        }
    }
}
