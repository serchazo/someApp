//
//  FirstSelectFoodz.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 19.01.20.
//  Copyright © 2020 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class FirstSelectFoodz: UIViewController {
    
    private let cellImageIdentifier = "FoodCellImage"
    private let headerIdentifier = "foodSelectorHeader"
    private let segue2App = "goToApp"
    
    //Instance vars
    private var foodList:[FoodType] = []
    private var user: User!
    private var currentCity: City!
    private let defaults = UserDefaults.standard

    private var selectedFoodz: [FoodType] = []{
        didSet{
            if selectedFoodz.count > 0 {
                goButton.setTitle(MyStrings.buttonGo.localized(), for: .normal)
            }else{
                goButton.setTitle(MyStrings.buttonSkip.localized(), for: .normal)
            }
        }
    }
    
    @IBOutlet weak var goButton: UIButton!{
        didSet{
            FoodzLayout.configureButton(button: goButton)
            goButton.setTitle(MyStrings.buttonSkip.localized(), for: .normal)
        }
    }
    @IBOutlet weak var foodSelectorCollection: UICollectionView!{
        didSet{
            foodSelectorCollection.delegate = self
            foodSelectorCollection.dataSource = self
        }
    }
    
    @IBAction func goButtonPressed(_ sender: Any) {
        // Go
        if selectedFoodz.count > 0{
            // Follow the foodz
            for food in selectedFoodz {
                SomeApp.followRanking(userId: user.uid, city: currentCity, foodId: food.key)
            }
            performSegue(withIdentifier: self.segue2App, sender: nil)
        }
        // Not go
        else{
            let emptyAlert = UIAlertController(
                title: MyStrings.emptyListTitle.localized(),
                message: MyStrings.emptyListMsg.localized(),
                preferredStyle: .alert)
            let cancelAction = UIAlertAction(
                title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                style: .default, handler: nil)
            let skipAction = UIAlertAction(
                title: MyStrings.emptyListButton.localized(),
                style: .destructive, handler: { _ in
                self.performSegue(withIdentifier: self.segue2App, sender: nil)
            })
            emptyAlert.addAction(cancelAction)
            emptyAlert.addAction(skipAction)
            present(emptyAlert, animated: true)
        }
    }
    
    // MARK: Timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.currentCity = self.getCurrentCityFromDefaults()
        
        // Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            self.loadFoodTypesFromDB()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        foodSelectorCollection.allowsMultipleSelection = true
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    // MARK: Get foodz from DB
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
    //
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
        }
    }
    // [END] Get the image

}


// MARK: Collection Stuff
extension FirstSelectFoodz: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard foodList.count > 0 else { return 1 }
        return foodList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // TODO: while loading display a spinner
        guard foodList.count > 0 else {
            // then go
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellImageIdentifier, for: indexPath) as? FirstSelectFoodzCell {
                cell.foodImage.image = nil
                cell.foodNameLabel.text = FoodzLayout.FoodzStrings.loading.localized()
                return cell
            }else{
                fatalError("Cannot create cell")
            }
        }
        
        // Image cells
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellImageIdentifier, for: indexPath) as? FirstSelectFoodzCell {
            
            // Image
            cell.foodImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
            cell.foodImage.sd_imageTransition = .fade
            cell.foodImage!.sd_setImage(
                with: foodList[indexPath.row].imageURL,
                placeholderImage: UIImage(named: "defaultBest"),
                options: [],
                completed: nil)
            
            // Label
            cell.foodNameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.foodNameLabel.text = foodList[indexPath.row].name
            
            return cell
        }
            
        // Cannot
        else{
            fatalError("Cannot create cell")
        }
        
    }
    
    // Header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch(kind){
        case UICollectionView.elementKindSectionHeader:
            guard
                let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: self.headerIdentifier,
                    for: indexPath) as? FirstSelectFoodzHeader
                else {
                    fatalError("Invalid view type")
            }
            
            return headerView
        default:
            fatalError("Unexpected kind element")
            
        }
    }
    
    // MARK: Multiple selection stuff
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        selectedFoodz.append(foodList[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didDeselectItemAt indexPath: IndexPath) {
        
        let singleFood = foodList[indexPath.row]
        
        if let index = selectedFoodz.firstIndex(of: singleFood) {
          selectedFoodz.remove(at: index)
        }
    }
}

// MARK: Layout stuff
extension FirstSelectFoodz{
    // snippet from : https://www.raywenderlich.com/5436806-modern-collection-views-with-compositional-layouts
    func generateLayout() -> UICollectionViewLayout {
        // Insets
        let insets = NSDirectionalEdgeInsets(
            top: 6,
            leading: 6,
            bottom: 6,
            trailing: 6)

      
        // I. Only type: Twins
        let twinItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(4/8),
                heightDimension: .fractionalHeight(1.0)))
        
        twinItem.contentInsets = insets
        
        let twinGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(3.5/8)),
            subitems: [twinItem, twinItem])
      
        // Header
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120))
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)
        
        let section = NSCollectionLayoutSection(group: twinGroup)
        section.boundarySupplementaryItems = [sectionHeader]
        //section.orthogonalScrollingBehavior = .continuous
        
        // Return the layout
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}

// MARK: Localized Strings
extension FirstSelectFoodz{
    private enum MyStrings {
        case buttonGo
        case buttonSkip
        case emptyListTitle
        case emptyListMsg
        case emptyListButton
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .buttonGo:
            return String(
                format: NSLocalizedString("FIRSTLOG4_BUTTON_GO", comment: "Go"),
                locale: .current,
                arguments: arguments)
            case .buttonSkip:
                return String(
                format: NSLocalizedString("FIRST_SELECT_FOODZ_BUTTON_SKIP", comment: "Skip"),
                locale: .current,
                arguments: arguments)
            case .emptyListTitle:
                return String(
                format: NSLocalizedString("FIRST_SELECT_EMPTYLIST_TITLE", comment: "Go"),
                locale: .current,
                arguments: arguments)
            case .emptyListMsg:
                return String(
                format: NSLocalizedString("FIRST_SELECT_EMPTYLIST_MSG", comment: "Go"),
                locale: .current,
                arguments: arguments)
            case .emptyListButton:
                return String(
                format: NSLocalizedString("FIRST_SELECT_EMPTYLIST_BUTTON", comment: "Go"),
                locale: .current,
                arguments: arguments)
            }
        }
    }
}
