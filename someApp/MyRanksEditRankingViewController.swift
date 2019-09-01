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
    var currentRanking: BasicRanking!
    
    // Outlets
    @IBOutlet weak var editRankingTable: UITableView!{
        didSet{
            editRankingTable.dataSource = self
            editRankingTable.delegate = self
            editRankingTable.dragDelegate = self
            editRankingTable.dragInteractionEnabled = true
            editRankingTable.dropDelegate = self
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section){
        case 0:
            if currentRanking != nil {
                return currentRanking!.restoList.count
            }else{
                return 0
            }
        case 1: return 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let tmpCell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath)
            if let cell = tmpCell as? MyRanksEditRankingTableViewCell,
                currentRanking != nil {
                cell.restoForThisCell = currentRanking!.restoList[indexPath.row]
                cell.restoImage.text = "Pic"
                let restoName = "\(indexPath.row + 1). \(currentRanking!.restoList[indexPath.row].restoName)"
                cell.restoName.attributedText = NSAttributedString(string: restoName, attributes: [.font: restorantNameFont])
                let restoAddress = currentRanking!.restoList[indexPath.row].address
                cell.restoTmpInfo.attributedText = NSAttributedString(string: restoAddress, attributes: [.font : restorantAddressFont])
            }
            return tmpCell
            
        }else{
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

// MARK : Extension for Drag
extension MyRanksEditRankingViewController: UITableViewDragDelegate{
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = tableView
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        // We don't allow dragging of the "Add ranking" cell
        if indexPath.section == 0, let restoNameToDrag = (editRankingTable.cellForRow(at: indexPath) as? MyRanksEditRankingTableViewCell)?.restoName.attributedText{
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: restoNameToDrag))
            dragItem.localObject = restoNameToDrag
            return[dragItem]
        }else{
            return []
        }
    }
}

// MARK : Drop stuff
extension MyRanksEditRankingViewController : UITableViewDropDelegate {
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
                editRankingTable.performBatchUpdates(
                    {
                        //Update the model here
                        currentRanking!.updateList(sourceIndex: sourceIndexPath.row, destinationIndex: destinationIndexPath.row)
                        // DO NOT RELOAD DATA HERE!!
                        // Delete row and then insert row instead
                        editRankingTable.deleteRows(at: [sourceIndexPath], with: UITableView.RowAnimation.left)
                        editRankingTable.insertRows(at: [destinationIndexPath], with: UITableView.RowAnimation.right)
                })
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
                //}
                editRankingTable.reloadData()
            }
        }
    }

    
    
}
