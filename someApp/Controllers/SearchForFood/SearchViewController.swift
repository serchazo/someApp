//
//  SearchViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 24.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class SearchViewController: UIViewController {
    // TODO : to change later on.  Current city should be read from properties
    private var currentCity = City(name: "Singapore", state: "singapore", country: "singapore", key: "singapore")
    
    private static let screenSize = UIScreen.main.bounds.size
    private let cityChooserSegueID = "cityChooser"
    
    //Instance vars
    private var foodList:[FoodType] = []
    private var user: User!
    
    // Extension can't have stored vars, so we define here
    private let sectionInsets = UIEdgeInsets(top: 20.0,
                                             left: 10.0,
                                             bottom: 40.0,
                                             right: 10.0)

    //Listen for changes in the Accessibility font
    private var accessibilityPropertyObserver: NSObjectProtocol?

    // MARK: Timeline funcs    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        accessibilityPropertyObserver = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { notification in
                //self.loadFoodTypesFromDB()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFoodTypesFromDB()
        
        // Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
        }
    }
     
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let observer = self.accessibilityPropertyObserver{
            NotificationCenter.default.removeObserver(observer)
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
                    //self.loadLocalFoodFromDB()
                }
            }
            
        })
    }
    
    func loadLocalFoodFromDB(){
        // Get the local food from DB
        SomeApp.dbFoodTypeRoot.child(currentCity.country).observeSingleEvent(of: .value, with: {snapshot in
            var tmpLocalFoodList: [FoodType] = []
            var count = 0
            for child in snapshot.children{
                if let childSnapshot = child as? DataSnapshot,
                    let foodItem = FoodType(snapshot: childSnapshot){
                    tmpLocalFoodList.append(foodItem)
                }
                // Use the trick
                count += 1
                if count == snapshot.childrenCount{
                    self.foodList.append(contentsOf: tmpLocalFoodList)
                    self.foodSelectorCollection.reloadData()
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
            case "GoNinjaGo":
                if let cell = sender as? SearchFoodCell,
                    //Don't forget the outlet colllectionView to avoid the ambiguous ref
                    let indexPath = collectionView.indexPath(for: cell),
                    let seguedDestinationVC = segue.destination as? RestoRankViewController{
                    seguedDestinationVC.currentFood = foodList[indexPath.row]
                    seguedDestinationVC.currentCity = currentCity
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

/////////
// MARK : Extension for the property observer
/////////

extension SearchViewController: ItemChooserViewDelegate{
    // MARK: Broadcasting stuff
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
            let tmpCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Spinner", for: indexPath)
            if let cell = tmpCell as? SpinnerCollectionViewCell{
                cell.spinner.style = .gray
                cell.spinner.sizeThatFits(CGSize(width: SearchViewController.screenSize.width-150, height: 200))
                cell.spinner.startAnimating()
                
                return cell
            }else{
                return tmpCell
            }
        }
        // then go
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodCell", for: indexPath) as? SearchFoodCell {
            
            // The position label
            let foodIconText = NSAttributedString(string: foodList[indexPath.row].icon, attributes: [.font: iconFont])
            //cell.cellIcon.attributedText = foodIconText
            cell.cellIcon.text = foodList[indexPath.row].icon
            cell.cellIcon.layer.cornerRadius = 0.5 * cell.cellIcon.frame.width
            cell.cellIcon.layer.borderColor = SomeApp.themeColor.cgColor
            cell.cellIcon.layer.borderWidth = 1.0
            cell.cellIcon.layer.masksToBounds = true
            print(cell.frame.width)
            
            let foodTitleText = NSAttributedString(string: foodList[indexPath.row].name , attributes: [.strokeColor: SomeApp.themeColor, .font: cellTitleFont])
            cell.cellLabel.attributedText = foodTitleText
            
            //cell.decorateCell()
            
            return cell
        }else{
            fatalError("No cell")
        }
    }
    
}

// MARK: Layout stuff

extension SearchViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // If the food list is empty, the only cell is the spinner
        guard foodList.count > 0 else{
            let size = CGSize(width: SearchViewController.screenSize.width-50, height: 180)
            return size
        }
        // Else, we calculate the size
        let paddingSpace = sectionInsets.left * 3
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / 2
        
        let tmpHeight = CGFloat(iconFont.lineHeight + 40.0)
        print("here: \(widthPerItem)")
        
        // Height is calculated in the font section
        return CGSize(width: widthPerItem, height: tmpHeight)
    }
    
    
    // Returns the spacing between the cells, headers, and footers. A constant is used to store the value.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // This method controls the spacing between each line in the layout. You want this to match the padding at the left and right.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    // MARK: Font of the cells
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


