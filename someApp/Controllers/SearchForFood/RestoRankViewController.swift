//
//  RestoRankViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class RestoRankViewController: UIViewController {
    var restoDatabaseReference: DatabaseReference!
    var restoPointsDatabaseReference: DatabaseReference!
    var thisRanking: [Resto] = []
    
    // Class Variables
    var currentCity: BasicCity!
    var currentFood: FoodType!
    let refreshControl = UIRefreshControl()

    
    // MARK: outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var restoRankTableView: UITableView!{
        didSet{
            restoRankTableView.dataSource = self
            restoRankTableView.delegate = self
            restoRankTableView.refreshControl = refreshControl
        }
    }
    
    @IBOutlet weak var restoRankTableHeader: UIView!
    @IBOutlet weak var tableHeaderFoodIcon: UILabel!
    @IBOutlet weak var tableHeaderFoodName: UILabel!
    
    
    // MARK: Selection stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize the references
        let tmpRef = SomeApp.dbRestoPoints.child(currentCity.rawValue)
        restoPointsDatabaseReference = tmpRef.child(currentFood.key)
        restoDatabaseReference = SomeApp.dbResto
        
        updateTableFromDatabase()
        
        //Some setup
        restoRankTableView.tableHeaderView = restoRankTableHeader
        tableHeaderFoodIcon.text = currentFood.icon
        tableHeaderFoodName.text = "Best \(currentFood.name) restaurants in \(currentCity.rawValue)"
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    ///
    func updateTableFromDatabase(){
        restoPointsDatabaseReference.observeSingleEvent(of: .value, with: { snapshot in
            var count = 0
            var tmpRestoList:[Resto] = []
            // I. Get the values
            for child in snapshot.children{
                if let snapChild = child as? DataSnapshot,
                    let value = snapChild.value as? [String: AnyObject],
                    let points = value["points"] as? Int{
                    // II. Get the restaurants
                    self.restoDatabaseReference.child(snapChild.key).observeSingleEvent(of: .value, with: {shot in
                        let tmpResto = Resto(snapshot: shot)
                        if tmpResto != nil {
                            tmpResto!.nbPoints = points
                            tmpRestoList.append(tmpResto!)
                        }
                        // Trick! If we have processed all children then we reload the Data
                        count += 1
                        if count == snapshot.childrenCount {
                            self.thisRanking = tmpRestoList
                            self.thisRanking.sort(by: {$0.nbPoints > $1.nbPoints})
                            self.restoRankTableView.reloadData()
                        }
                        
                    })
                    
                }
                
            }
        })
    }
    
    
    ///
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when segued pops
        if let indexPath = restoRankTableView.indexPathForSelectedRow {
            restoRankTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        // If pull down the table, then refresh data
        updateTableFromDatabase()
        self.refreshControl.endRefreshing()
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case "showRestoDetail":
                if let cell = sender as? RestoRankTableViewCell,
                    let indexPath = tableView.indexPath(for: cell),
                    let seguedToResto = segue.destination as? RestoDetailViewController{
                    // Segue
                    seguedToResto.currentResto = thisRanking[indexPath.row]
                }
            default: break
            }
        }
    }
}

// MARK : Table stuff
extension RestoRankViewController : UITableViewDelegate, UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thisRanking.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "RestoRankCell", for: indexPath) as? RestoRankTableViewCell {
            //Configure the cell
            let thisResto = thisRanking[indexPath.row]
            cell.restoNameLabel.attributedText = NSAttributedString(string: thisResto.name, attributes: [.font : restorantNameFont])
            cell.restoPointsLabel.attributedText = NSAttributedString(string: "Points: \(thisResto.nbPoints)", attributes: [.font : restorantPointsFont])
            cell.restoOtherInfoLabel.attributedText = NSAttributedString(string: thisResto.city, attributes: [.font : restorantAddressFont])
            
            cell.decorateCell()
            
            return cell
        }else{
            fatalError("Marche pas.")
        }
    }
}


// MARK: Some view stuff
extension RestoRankViewController{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = restorantNameFont.lineHeight + restorantAddressFont.lineHeight + restorantPointsFont.lineHeight + 65.0
        return CGFloat(cellHeight)
    }
    
    // MARK : Fonts
    private var restorantNameFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .title3).withSize(23.0))
    }
    
    private var restorantPointsFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
    
    private var restorantAddressFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
}
