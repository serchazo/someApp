//
//  RestoRankViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class RestoRankViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ItemChooserViewDelegate {
    // MARK: Temorary model
    var basicModel = BasicModel()
    
    /* Table View Stuff */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return basicModel.restoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "RestoRankCell", for: indexPath) as? RestoRankTableViewCell {
            //Configure the cell
            cell.testLabel.text = basicModel.restoList[indexPath.row].restoName
            
            return cell
        }else{
            fatalError("Marche pas.")
        }
    }
    
    // MARK: outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var restoRankTableView: UITableView!{
        didSet{
            restoRankTableView.dataSource = self
            restoRankTableView.delegate = self
        }
    }
    
    @IBOutlet weak var restoRankTableHeader: UIView!
    
    // Selection stuff
    @IBOutlet weak var foodButton: UIButton!
    @IBOutlet weak var cityButton: UIButton!
    
    @IBAction func someSelector(_ sender: UIButton) {
        // TBD
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Some setup
        restoRankTableView.tableHeaderView = restoRankTableHeader

    }
    
    //Broadcasting stuff
    func itemChooserReceiveItem(_ sender: Int) {
        print("hoa \(sender)")
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
                    print("segue \(indexPath.row)")
                    //tmp
                    let text = basicModel.restoList[indexPath.row].restoName
                    print("This is a Segue with \(text)")
                    // Segue
                    seguedToResto.titleCell = text
                }
            case "cityChoser":
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.setPickerValue(withData: .City)
                    seguedToCityChooser.delegate = self
                    
                }
            case "FoodChoser":
                if let seguedToCityChooser = segue.destination as? ItemChooserViewController{
                    seguedToCityChooser.setPickerValue(withData: .Food)
                    seguedToCityChooser.delegate = self
                }
                
            default: break
            }
        }
    }


}
