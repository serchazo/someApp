//
//  MyRanksEditRankingViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit

class MyRanksEditRankingViewController: UIViewController {
    
    var currentCity: BasicCity!
    var currentFood: BasicFood!
    var currentRanking: BasicRanking?
    
    // Outlets
    @IBOutlet weak var editRankingTable: UITableView!{
        didSet{
            editRankingTable.dataSource = self
            editRankingTable.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let seguedMVC = segue.destination as? MyRanksMapSearchViewController{
            seguedMVC.delegate = self
        }
        
    }

}

// MARK: Extension for the Table stuff
extension MyRanksEditRankingViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentRanking != nil {
            return currentRanking!.restoList.count+1
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var itemCount:Int{
            get{
                if currentRanking != nil {return currentRanking!.restoList.count}
                else{ return 0}
            }
        }
        
        switch(indexPath.row){
        case 0..<itemCount:
        
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath) as? MyRanksEditRankingTableViewCell,
                currentRanking != nil {
                cell.restoImage.text = "Pic"
                cell.restoName.text = currentRanking!.restoList[indexPath.row].restoName
                cell.restoImage.text = "Some info."
                return cell
            }else{
                fatalError("Marche pas.")
            }
        default:
            return tableView.dequeueReusableCell(withIdentifier: "AddRestoToRankingCell", for: indexPath)
        }
    }
}

extension MyRanksEditRankingViewController: MyRanksMapSearchViewDelegate{
    func restaurantChosenFromMap(someMapItem: MKMapItem) {
        print("\(someMapItem.placemark)")
        let tmpResto = BasicResto(restoCity: currentCity, restoName: someMapItem.placemark.name!)
        currentRanking?.restoList.append(tmpResto)
        editRankingTable.reloadData()
    }
    
}
