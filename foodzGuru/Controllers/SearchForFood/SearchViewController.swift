//
//  SearchViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 24.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class SearchViewController: UIViewController {
    // TODO : to change later on.  Current city should be read from properties
    private var currentCity:City!
    
    private static let screenSize = UIScreen.main.bounds.size
    private let cityChooserSegueID = "cityChooser"
    private let foodChosen = "GoNinjaGo"
    
    private let defaults = UserDefaults.standard
    //Instance vars
    private var foodList:[FoodType] = []
    private var user: User!
    

    // MARK: Timeline funcs    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
        }
        
        currentCity = self.getCurrentCityFromDefaults()
        
        cityNavBarButton.title = currentCity.name
        
        // Do any additional setup after loading the view.
        let layout = foodSelectorCollection.collectionViewLayout as? CustomCollectionViewLayout
        layout?.delegate = self
        
        loadFoodTypesFromDB()
    }

    //
    private func getCurrentCityFromDefaults() -> City{
        if let currentCityString = defaults.object(forKey: SomeApp.currentCityDefault) as? String{
            let cityArray = currentCityString.components(separatedBy: "/")
            return City(country: cityArray[0], state: cityArray[1], key: cityArray[2], name: cityArray[3])
        }else{
            return City(country: "singapore", state: "singapore", key: "singapore", name: "Singapore")
        }
    }

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
                    self.foodSelectorCollection.reloadData()
                    self.foodSelectorCollection.collectionViewLayout.invalidateLayout()
                    
                }
            }
            
        })
    }
    
    
    //Do this to avoid the "ambiguous reference" in the prepare to Segue
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var foodSelectorCollection: UICollectionView!{
        didSet{
            foodSelectorCollection.dataSource = self
            foodSelectorCollection.delegate = self
        }
    }
    
    // MARK: - Navigation

    @IBOutlet weak var cityNavBarButton: UIBarButtonItem!
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch(identifier){
            case foodChosen:
                if let cell = sender as? SearchFoodCell,
                    //Don't forget the outlet colllectionView to avoid the ambiguous ref
                    let indexPath = collectionView.indexPath(for: cell),
                    let seguedDestinationVC = segue.destination as? BestRestosViewController{
                    seguedDestinationVC.currentFood = foodList[indexPath.row]
                    seguedDestinationVC.currentCity = currentCity!
                }
            case cityChooserSegueID :
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.delegate = self
                    seguedToCityChooser.firstLoginFlag = false
                }
            default: break
            }
        }
    }
}


// MARK: Extension for the property observer
extension SearchViewController: ItemChooserViewDelegate{
    func itemChooserReceiveCity(city: City, countryName: String, stateName: String) {
        currentCity = city
        cityNavBarButton.title = city.name
        loadFoodTypesFromDB()
    }
}

// MARK: Collection stuff

extension SearchViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard foodList.count > 0 else { return 1 }
        return foodList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // TODO: while loading display a spinner
        guard foodList.count > 0 else {
            // then go
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodCell", for: indexPath) as? SearchFoodCell {
                cell.cellIcon.text = ""
                cell.cellLabel.text = "waiting"
                return cell
            }else{
                fatalError("No cell")
            }
        }
        // then go
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodCell", for: indexPath) as? SearchFoodCell {
            
            // Decorate first
            cell.layer.borderColor = SomeApp.themeColor.cgColor
            cell.layer.borderWidth = 1.0
            cell.layer.cornerRadius = cell.frame.width / 2
            cell.clipsToBounds = true
            
            cell.cellIcon.text = foodList[indexPath.row].icon
            
            let foodTitleText = NSAttributedString(string: foodList[indexPath.row].name , attributes: [.strokeColor: SomeApp.themeColor, .font: cellTitleFont])
            cell.cellLabel.attributedText = foodTitleText
            
            
            return cell
        }else{
            fatalError("No cell")
        }
    }
    
    // Animation for appearing
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        
        cell.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
            cell.transform = .identity
        }, completion: nil)
        
    }
    
}

// MARK: Fonts
extension SearchViewController{
    private var iconFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(40.0))
    }
    
    private var cellTitleFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
    
    private var titleFont: UIFont{
        return UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(23.0))
    }
    
}

//MARK: Layout Delegate
extension SearchViewController: CustomCollectionViewDelegate {
    func theNumberOfItemsInCollectionView() -> Int {
        guard foodList.count > 0 else {
            return 1
        }
        return foodList.count
    }
    
}
