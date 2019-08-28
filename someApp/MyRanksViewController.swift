//
//  MyRanksViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyRanksViewController: UIViewController, MyRanksAddRankingViewDelegate {
    
    var user:BasicUser!
    var currentCity:BasicCity = .Singapore
    
    var selectedRow = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("Hello \(user.userName)")
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myRanksTable: UITableView!{
        didSet{
            myRanksTable.dataSource = self
            myRanksTable.delegate = self
        }
    }
    
    // MARK: - Navigation
    func addRankingReceiveInfoToCreate(basicCity: BasicCity, basicFood: BasicFood) {
        //Update the list
        user.myRankings.append(BasicRanking(cityOfRanking: basicCity, typeOfFood: basicFood))
        myRanksTable.reloadData()

    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "editRestoList":
            if let seguedMVC = segue.destination as? MyRanksEditRankingViewController{
                seguedMVC.currentCity = self.currentCity
                seguedMVC.currentRanking = user.myRankings[selectedRow]
            }
        case "addRanking":
            if let seguedMVC = segue.destination as? MyRanksAddRankingViewController{
                seguedMVC.delegate = self
            }
        default: 
            break
        }
    }
    
}

// MARK: table stuff
extension MyRanksViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return user.myRankings.count + 1
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch(indexPath.row){
        case 0..<user.myRankings.count:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MyRanksCell", for: indexPath) as? MyRanksTableViewCell {
                cell.cellIcon.text = "\(indexPath.row)"
                cell.cellTitle.text = user.myRankings[indexPath.row].typeOfFood.rawValue
                cell.cellCity.text = user.myRankings[indexPath.row].cityOfRanking.rawValue
                return cell
            }else{
                fatalError("Marche pas.")
            }
        default:
            return tableView.dequeueReusableCell(withIdentifier: "AddNewRankingCell", for: indexPath)
        }
    }
}

// MARK: Some view stuff
extension MyRanksViewController{
    private var iconFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    private var cellTitleFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
    
    private var cellCityNameFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(iconFont.lineHeight + 10.0)
    }
}
