//
//  SearchViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 24.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class SearchViewController: UIViewController,ItemChooserViewDelegate {
    
    //To probably change later
    var foodList:[FoodType] = []
    var currentCity:BasicCity = .Singapore
    var user: User!

    //Listen for changes in the Accessibility font
    private var accessibilityPropertyObserver: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        accessibilityPropertyObserver = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { notification in
                self.reloadText()
        })
    }

    func reloadText(){
        foodSelectorCollection.reloadData()
        titleCell.attributedText = NSAttributedString(string: "Craving any food today?", attributes: [.font: titleFont])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the list from the Database (an observer)
        basicModel.dbFoodTypeRoot.observe(.value, with: {snapshot in
            var tmpFoodList: [FoodType] = []
            
            for child in snapshot.children{
                if let childSnapshot = child as? DataSnapshot,
                    let foodItem = FoodType(snapshot: childSnapshot){
                    tmpFoodList.append(foodItem)
                }
            }
            self.foodList = tmpFoodList
            self.foodSelectorCollection.reloadData()
        })
        
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
    
    //Do this to avoid the "ambiguous reference" in the prepare to Segue
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var foodSelectorCollection: UICollectionView!{
        didSet{
            foodSelectorCollection.dataSource = self
            foodSelectorCollection.delegate = self
        }
    }
    @IBOutlet weak var titleCell: UILabel!
    
    // MARK: Broadcasting stuff
    func itemChooserReceiveCity(_ sender: BasicCity) {
        currentCity = sender
        cityNavBarButton.title = sender.rawValue 
        
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
            case "cityChoser":
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.setPickerValue(withData: .City)
                    seguedToCityChooser.delegate = self
                    
                }
            default: break
            }
        }
    }
 

}

// MARK : Extension for Collection stuff

extension SearchViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return foodList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // TODO : while loading display a spinner
        
        guard foodList.count != 0 else {
            print("mmmm")
            let tmpCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Spinner", for: indexPath)
            if let cell = tmpCell as? SpinnerCollectionViewCell{
                print("here")
                cell.spinner.style = .gray
                cell.spinner.startAnimating()
                return cell
            }else{
                return tmpCell
            }
        }
        
        // then go
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodCell", for: indexPath) as? SearchFoodCell {
            cell.cellBasicFood = foodList[indexPath.row].key
            
            let foodIconText = NSAttributedString(string: foodList[indexPath.row].icon, attributes: [.font: iconFont])
            cell.cellIcon.attributedText = foodIconText
            
            let foodTitleText = NSAttributedString(string: foodList[indexPath.row].name , attributes: [.font: cellTitleFont])
            cell.cellLabel.attributedText = foodTitleText
            
            return cell
        }else{
            fatalError("No cell")
        }
    }
}


// MARK: Layout stuff
extension SearchViewController: UICollectionViewDelegateFlowLayout{
    // MARK: Font of the cells
    private var iconFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    private var cellTitleFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
    
    private var titleFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(25.0))
    }
    
    var cellHeight:CGFloat{
        get{
            return CGFloat(iconFont.lineHeight + cellTitleFont.lineHeight + 10.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (view.frame.width-10)/2
        return CGSize(width: cellWidth, height: cellHeight)
    }
}


