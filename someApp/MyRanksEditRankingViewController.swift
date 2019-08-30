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
    
    //Attention, variables initialized from segue-r MyRanksViewController
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when segued pops
        if let indexPath = editRankingTable.indexPathForSelectedRow {
            editRankingTable.deselectRow(at: indexPath, animated: true)
        }
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
                let restoName = "\(indexPath.row + 1). \(currentRanking!.restoList[indexPath.row].restoName)"
                cell.restoName.attributedText = NSAttributedString(string: restoName, attributes: [.font: restorantNameFont])
                let restoAddress = currentRanking!.restoList[indexPath.row].address
                cell.restoTmpInfo.attributedText = NSAttributedString(string: restoAddress, attributes: [.font : restorantAddressFont])
                return cell
            }else{
                fatalError("Marche pas.")
            }
        default:
            return tableView.dequeueReusableCell(withIdentifier: "AddRestoToRankingCell", for: indexPath)
        }
    }
}

// MARK : get stuff from the segued view and process the info
extension MyRanksEditRankingViewController: MyRanksMapSearchViewDelegate{
    func restaurantChosenFromMap(someMapItem: MKMapItem) {
        let tmpResto = BasicResto(restoCity: currentCity, restoName: someMapItem.placemark.name!)
        
        if someMapItem.placemark.formattedAddress != nil{
            tmpResto.address = someMapItem.placemark.formattedAddress!
        }
        
        if someMapItem.url != nil{
            tmpResto.restoURL = someMapItem.url
        }
        tmpResto.mapItem = someMapItem
        tmpResto.tags.append(currentFood)
        
        if !currentRanking!.addToRanking(resto: tmpResto){
            print("aja!")
            let alert = UIAlertController(
                title: "Duplicate restaurant",
                message: "The restaurant is already in your ranking.",
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: {
                    (action: UIAlertAction)->Void in
                    //do nothing
            }))
            present(alert, animated: false, completion: nil)
        }
        
        editRankingTable.reloadData()
    }
    
}


// MARK: Some view stuff
extension MyRanksEditRankingViewController{
    private var iconFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    private var restorantNameFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(25.0))
    }
    
    private var restorantAddressFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = restorantNameFont.lineHeight + restorantAddressFont.lineHeight + 45.0
        return CGFloat(cellHeight)
    }
}
