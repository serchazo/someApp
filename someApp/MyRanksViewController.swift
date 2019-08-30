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
    
    //var selectedRow = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("Hello \(user.userName)")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myRanksTable: UITableView!{
        didSet{
            myRanksTable.dataSource = self
            myRanksTable.delegate = self
            myRanksTable.dragDelegate = self
            myRanksTable.dragInteractionEnabled = true
            myRanksTable.dropDelegate = self
            
        }
    }
    
    // MARK: - Navigation
    func addRankingReceiveInfoToCreate(basicCity: BasicCity, basicFood: BasicFood) {
        //Update the list
        if (user.myRankings.filter {$0.cityOfRanking == basicCity && $0.typeOfFood == basicFood}).count == 0 {
            user.myRankings.append(BasicRanking(cityOfRanking: basicCity, typeOfFood: basicFood))
            myRanksTable.reloadData()
        }else{
            // Resto already in list
            let alert = UIAlertController(
                title: "Duplicate ranking",
                message: "You already have a \(basicFood.rawValue) ranking in \(basicCity.rawValue).",
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
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "editRestoList":
            if let seguedMVC = segue.destination as? MyRanksEditRankingViewController{
                if let tmpCell = sender as? MyRanksTableViewCell,
                    let tmpIndexPath = myRanksTable.indexPath(for: tmpCell){
                    seguedMVC.currentCity = self.currentCity
                    seguedMVC.currentFood = user.myRankings[tmpIndexPath.row].typeOfFood
                    seguedMVC.currentRanking = user.myRankings[tmpIndexPath.row]
                }
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section){
        case 0: return user.myRankings.count
        case 1: return 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Not used
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let tmpCell = tableView.dequeueReusableCell(withIdentifier: "MyRanksCell", for: indexPath)
            if let cell = tmpCell as? MyRanksTableViewCell {
                cell.cellIcon.text = "\(indexPath.row)"
                cell.cellTitle.text = user.myRankings[indexPath.row].typeOfFood.rawValue
                cell.cellCity.text = user.myRankings[indexPath.row].cityOfRanking.rawValue
            }
            return tmpCell
        }else{
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

// MARK : drag delegate
extension MyRanksViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = tableView
        return dragItem(at: indexPath)
    }
    
    private func dragItem(at indexPath: IndexPath) -> [UIDragItem]{
        // We don't allow dragging of the "Add ranking" cell 
        if indexPath.section == 0{
            let attributedString = NSAttributedString(string: "test")
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return[dragItem]
        }else{
            return []
        }
    }
}

// MARK : drop delegate
extension MyRanksViewController: UITableViewDropDelegate{
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 0{
            let isSelf = (session.localDragSession?.localContext as? UITableView) == tableView
            return UITableViewDropProposal(operation: isSelf ? .move : .cancel, intent: .insertAtDestinationIndexPath)
        }else{
            return UITableViewDropProposal(operation: .cancel)
        }
        
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items{
            //The drag is coming from myself (no need to look at the local context to know it's coming from me)
            if let sourceIndexPath = item.sourceIndexPath{
                //if let attributtedString = item.dragItem.localObject as? NSAttributedString{
                // Garde-fous: we need to keep the view and model in synch
                myRanksTable.performBatchUpdates(
                    {
                        //Update the model here
                        let tempRanking = user.myRankings[sourceIndexPath.row]
                        user.myRankings.remove(at: sourceIndexPath.row)
                        user.myRankings.insert(tempRanking, at: destinationIndexPath.row)
                        // DO NOT RELOAD DATA HERE!!
                        // Delete row and then insert row instead
                        myRanksTable.deleteRows(at: [sourceIndexPath], with: UITableView.RowAnimation.left)
                        myRanksTable.insertRows(at: [destinationIndexPath], with: UITableView.RowAnimation.right)
                })
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
                //}
                myRanksTable.reloadData()
            }
        }
    }
    
    
}
