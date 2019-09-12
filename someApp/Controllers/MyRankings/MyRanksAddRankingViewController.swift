//
//  MyRanksAddRankingViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

protocol MyRanksAddRankingViewDelegate: class{
    func addRankingReceiveInfoToCreate(inCity: String, withFood: FoodType)
}

class MyRanksAddRankingViewController: UIViewController {

    //To probably change later
    var foodList:[FoodType] = []
    var currentCity = "Singapore"
    
    // Action when a cell is pressed
    weak var delegate: MyRanksAddRankingViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Get the list from the Database (an observer)
        SomeApp.dbFoodTypeRoot.observe(.value, with: {snapshot in
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
            switch identifier{
            case "cityChoser":
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.setPickerValue()
                    seguedToCityChooser.delegate = self
                }
            default:break
            }
            
        }
    }
}
// MARK : collection stuff
extension MyRanksAddRankingViewController : UICollectionViewDelegate, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return foodList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // send info to the delegate
        self.delegate?.addRankingReceiveInfoToCreate(inCity: currentCity, withFood: foodList[indexPath.row])
        
        self.navigationController?.popViewController(animated: true)
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

// MARK : Get the city from the City Chooser
extension MyRanksAddRankingViewController: ItemChooserViewDelegate {
    func itemChooserReceiveCity(_ sender: BasicCity) {
        currentCity = sender.rawValue
        cityNavBarButton.title = currentCity
        
    }
}

// MARK: Layout stuff
extension MyRanksAddRankingViewController : UICollectionViewDelegateFlowLayout{
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
