//
//  MyRanksViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyRanksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MyRanksAddRankingViewDelegate {
    
    var user:BasicUser!
    var currentCity:BasicCity = .Singapore

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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return user.myRankings.count + 1
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
    
    // MARK: - Navigation
    func addRankingReceiveInfoToCreate(basicCity: BasicCity, basicFood: BasicFood) {
        //Update the list
        user.myRankings.append(BasicRanking(cityOfRanking: basicCity, typeOfFood: basicFood))
        myRanksTable.reloadData()

    }
    
     
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let seguedMVC = segue.destination as? MyRanksAddRankingViewController{
            seguedMVC.delegate = self 
        }
        
    }
    
    
}
