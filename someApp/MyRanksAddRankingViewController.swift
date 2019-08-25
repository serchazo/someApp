//
//  MyRanksAddRankingViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

protocol MyRanksAddRankingViewDelegate: class{
    func addRankingReceiveCity(_ sender: BasicCity)
    func addRankingReceiveFoodType(_ sender: BasicFood)
}

class MyRanksAddRankingViewController: UIViewController, UICollectionViewDelegate,UICollectionViewDataSource, ItemChooserViewDelegate {

    //To probably change later
    var foodData = basicModel.foodList
    var currentCity:BasicCity = .Singapore
    
    //
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return foodData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodCell", for: indexPath) as? SearchFoodCell {
            cell.cellBasicFood = foodData[indexPath.row].foodtype
            cell.cellLabel.text = foodData[indexPath.row].foodDescription
            cell.cellIcon.text = foodData[indexPath.row].foodIcon
            return cell
        }else{
            fatalError("No cell")
        }
    }
    
    // Action when a cell is pressed
    weak var delegate: MyRanksAddRankingViewDelegate!
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.addRankingReceiveFoodType(foodData[indexPath.row].foodtype)
        self.delegate?.addRankingReceiveCity(currentCity)
        
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    //Do this to avoid the "ambiguous reference" in the prepare to Segue
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var foodSelectorCollection: UICollectionView!{
        didSet{
            foodSelectorCollection.dataSource = self
            foodSelectorCollection.delegate = self
        }
    }
    
    // MARK: Broadcasting stuff
    func itemChooserReceiveCity(_ sender: BasicCity) {
        currentCity = sender
        cityNavBarButton.title = sender.rawValue
        
    }
    
    
    
    // MARK: - Navigation
    @IBOutlet weak var cityNavBarButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case "cityChoser":
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.setPickerValue(withData: .City)
                    seguedToCityChooser.delegate = self
                }
            default:break
            }
            
        }
    }
 

}
