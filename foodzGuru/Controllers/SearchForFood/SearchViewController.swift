//
//  SearchViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 24.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class SearchViewController: UIViewController {
    
    
    private var currentCity:City!
    
    private static let screenSize = UIScreen.main.bounds.size
    private let cityChooserSegueID = "cityChooser"
    private let foodChosen = "GoNinjaGo"
    private let goNinjaGoImage = "GoNinjaGoImage"
    
    private let cellImageIdentifier = "FoodCellImage"
    
    private let defaults = UserDefaults.standard
    //Instance vars
    private var foodList:[FoodType] = []
    private var user: User!
    

    // MARK: Timeline funcs    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currentCity = self.getCurrentCityFromDefaults()
        self.loadFoodTypesFromDB()
        
        cityNavBarButton.title = currentCity.name
        foodSelectorCollection.collectionViewLayout = generateLayout()
    }

    //
    private func getCurrentCityFromDefaults() -> City{
        if let currentCityString = defaults.object(forKey: SomeApp.currentCityDefault) as? String{
            let cityArray = currentCityString.components(separatedBy: "/")
            return City(country: cityArray[0], state: cityArray[1], key: cityArray[2], name: cityArray[3])
        }else{
            return City(country: "sg", state: "sg", key: "sin", name: "Singapore")
        }
    }

    // MARK: get stuff from Database
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
                    self.getImages()
                    self.foodSelectorCollection.reloadData()
                    self.foodSelectorCollection.collectionViewLayout.invalidateLayout()
                    
                }
            }
            
        })
    }
    
    private func getImages(){
        guard foodList.count > 0 else{return}
        
        for food in foodList{
            // [START] Get the image
            let storagePath = self.currentCity.country + "/" + food.key + ".png"
            let imageRef = SomeApp.storageFoodRef.child(storagePath)
            // Fetch the download URL
            imageRef.downloadURL { url, error in
              if let error = error {
                print(error.localizedDescription)
              } else {
                food.imageURL = url!
                let index = self.foodList.firstIndex(where: {$0.key == food.key})
                self.foodSelectorCollection.reloadItems(at: [IndexPath(item: index!, section: 0)])
              }
            }
            // [END] Get the image
            
        }
        
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
            // with image
            case goNinjaGoImage:
                // with image
                if let cell = sender as? SearchFoodImageCell,
                    //Don't forget the outlet colllectionView to avoid the ambiguous ref
                    let indexPath = collectionView.indexPath(for: cell),
                    let seguedDestinationVC = segue.destination as? BestRestosViewController{
                    seguedDestinationVC.currentFood = foodList[indexPath.row]
                    seguedDestinationVC.currentCity = currentCity!
                }
            case cityChooserSegueID :
                if let seguedToCityChooser = segue.destination as? CountryChoser{
                    seguedToCityChooser.delegate = self
                    seguedToCityChooser.firstLoginFlag = false
                }
            default: break
            }
        }
    }
}

// MARK: get city from chose
extension SearchViewController: CountryChooserViewDelegate{
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
        
        // Image cells
        if foodList[indexPath.row].imageURL != nil,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellImageIdentifier, for: indexPath) as? SearchFoodImageCell {
            
            // Image
            cell.foodImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
            cell.foodImage.sd_imageTransition = .curlUp
            cell.foodImage!.sd_setImage(
                with: foodList[indexPath.row].imageURL,
                placeholderImage: nil,//UIImage(named: "defaultBest"),
                options: [],
                completed: nil)
            
            // Label
            cell.foodNameLabel.textColor = .black
            cell.foodNameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.foodNameLabel.text = foodList[indexPath.row].name
            
            return cell
        }
        // Icon cells
        else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellImageIdentifier, for: indexPath) as? SearchFoodImageCell {
            
            // Decorate first
            // Image
            cell.foodImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
            cell.foodImage!.sd_setImage(
                with: foodList[indexPath.row].imageURL,
                placeholderImage: UIImage(named: "defaultBest"),
                options: [],
                completed: nil)
            
            // Label
            cell.foodNameLabel.textColor = .black
            cell.foodNameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.foodNameLabel.text = foodList[indexPath.row].name
            return cell
        }
        
        // Cannot
        else{
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

// MARK: Layout stuff
extension SearchViewController{
    // snippet from : https://www.raywenderlich.com/5436806-modern-collection-views-with-compositional-layouts
    func generateLayout() -> UICollectionViewLayout {
        
        // Insets
        let insets = NSDirectionalEdgeInsets(
            top: 2,
            leading: 2,
            bottom: 2,
            trailing: 2)
      
        // We have three row styles
        // Style 1: 'Full': A full width photo
        // Style 2: 'Main with pair': A 2/3 width photo with two 1/3 width photos stacked vertically
        // Style 3: 'Triplet': Three 1/3 width photos stacked horizontally
        
        // I. First type. Full
        let fullPhotoItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(3/4)))
        
        fullPhotoItem.contentInsets = insets
      
        // II. Second type: Main with pair
        let mainItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(2/3),
                heightDimension: .fractionalHeight(1.0)))
        
        mainItem.contentInsets = insets
      
        // Pair items are inside a group
        let pairItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(0.5)))
        
        pairItem.contentInsets = insets
      
        let trailingGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1/3),
                heightDimension: .fractionalHeight(1.0)),
            subitem: pairItem,
            count: 2)
      
        // Then the group
        let mainWithPairGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(4/8)),
                //heightDimension: .fractionalWidth(4/9)),
            subitems: [mainItem, trailingGroup])
      
        // III. Third type. Twins
        let twinItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(4/8),
                heightDimension: .fractionalHeight(1.0)))
        
        twinItem.contentInsets = insets
        
        let twinGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(3/8)),
            subitems: [twinItem, twinItem])
      
        // IV. Fourth type. Reversed main with pair
        /*
        let mainWithPairReversedGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(4/9)),
            subitems: [trailingGroup, mainItem])
       */
        
        // V. Finally
        let nestedGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                //heightDimension: .fractionalWidth(16/9)),
            heightDimension: .fractionalWidth(13/8)),
            subitems: [
                twinGroup,
                fullPhotoItem,
                mainWithPairGroup
            ]
        )

        let section = NSCollectionLayoutSection(group: nestedGroup)
        // Return the layout
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}
