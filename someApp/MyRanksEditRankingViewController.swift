//
//  MyRanksEditRankingViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyRanksEditRankingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var currentCity: BasicCity!
    var currentFood: BasicFood!
    var currentRanking: BasicRanking?
    
    //Table stuff
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentRanking != nil {
            return currentRanking!.restoList.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath) as? MyRanksEditRankingTableViewCell,
            currentRanking != nil {
            cell.restoImage.text = "Pic"
            cell.restoName.text = currentRanking!.restoList[indexPath.row].restoName
            cell.restoImage.text = "Some info."
            
            return cell
        }else{
            fatalError("Marche pas.")
        }
    }
    
    // Outlets
    
    @IBOutlet weak var editRankingSearchBar: UISearchBar!
    @IBOutlet weak var editRankingTable: UITableView!{
        didSet{
            editRankingTable.dataSource = self
            editRankingTable.delegate = self
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
