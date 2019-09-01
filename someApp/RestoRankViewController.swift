//
//  RestoRankViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class RestoRankViewController: UIViewController {
    
    // Class Variables
    var currentCity: BasicCity!
    var currentFood: BasicFoodType!
    var currentRestoList: [BasicResto]{
        get{
            if currentFood != nil{
                return basicModel.getSomeRestoList(fromCity: currentCity,ofFoodType: currentFood!.foodType).sorted(by: {$0.numberOfPoints > $1.numberOfPoints})
            }else{
                return basicModel.getSomeRestoList(fromCity: currentCity).sorted(by: {$0.numberOfPoints > $1.numberOfPoints})
            }
        }
    }
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
        
        //Some setup
        restoRankTableView.tableHeaderView = restoRankTableHeader
        tableHeaderFoodIcon.text = currentFood.foodIcon
        tableHeaderFoodName.text = "Best \(currentFood.foodDescription) restaurants in \(currentCity.rawValue)"
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when segued pops
        if let indexPath = restoRankTableView.indexPathForSelectedRow {
            restoRankTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        // Fetch Weather Data
        restoRankTableView.reloadData()
        self.refreshControl.endRefreshing()
        //self.activityIndicatorView.stopAnimating()
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
                    //tmp
                    let text = currentRestoList[indexPath.row].restoName
                    // Segue
                    seguedToResto.restoName = text 
                }
            
                
            default: break
            }
        }
    }
}

// MARK : Table stuff
extension RestoRankViewController : UITableViewDelegate, UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentRestoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "RestoRankCell", for: indexPath) as? RestoRankTableViewCell {
            //Configure the cell
            let thisResto = currentRestoList[indexPath.row]
            cell.restoNameLabel.attributedText = NSAttributedString(string: thisResto.restoName, attributes: [.font : restorantNameFont])
            cell.restoPointsLabel.attributedText = NSAttributedString(string: "Points: \(thisResto.numberOfPoints)", attributes: [.font : restorantPointsFont])
            cell.restoOtherInfoLabel.attributedText = NSAttributedString(string: thisResto.address, attributes: [.font : restorantAddressFont])
            
            return cell
        }else{
            fatalError("Marche pas.")
        }
    }
}


// MARK: Some view stuff
extension RestoRankViewController{
    private var restorantNameFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .title3).withSize(23.0))
    }
    
    private var restorantPointsFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
    
    private var restorantAddressFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = restorantNameFont.lineHeight + restorantAddressFont.lineHeight + restorantPointsFont.lineHeight + 65.0
        return CGFloat(cellHeight)
    }
}
