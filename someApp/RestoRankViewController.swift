//
//  RestoRankViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 23.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class RestoRankViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
    @IBOutlet weak var restoRankTableView: UITableView!{
        didSet{
            restoRankTableView.dataSource = self
            restoRankTableView.delegate = self
        }
    }
    
    @IBOutlet var tableView: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

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
            default: break
            }
        }
    }
    
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case "showRestoDetail":
                if let cell = sender as? RestoRankTableViewCell,
                    //let indexPath = tableView.indexPath(for: cell),
                    let seguedToResto = segue.destination as? RestoDetailViewController{
                    print("segue \(indexPath.row)")
                    //tmp
                    let text = basicModel.restoList[indexPath.row].restoName
                    print("This is a Segue with \(text)")
                    // Segue
                    seguedToResto.titleCell = text
                }else{print("here")}
                
                
            default: break
            }
        }
        
    }
    */

}
