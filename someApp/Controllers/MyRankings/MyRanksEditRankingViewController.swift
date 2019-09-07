//
//  MyRanksEditRankingViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class MyRanksEditRankingViewController: UIViewController {
    var user: User!
    var thisRankingId: String!
    var thisRankingFoodKey: String!
    var rankingDatabaseReference: DatabaseReference!
    var restoDatabaseReference: DatabaseReference!
    var restoPointsDatabaseReference: DatabaseReference!
    var thisRanking: [Resto] = []
    
    //Attention, variables initialized from segue-r MyRanksViewController
    var currentCity: BasicCity!
    var currentFood: String = ""
    
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
    
    func initializeArray(withElements: Int) -> [Resto] {
        var tmpRestoList: [Resto] = []
        for _ in 0..<withElements {
            tmpRestoList.append(Resto(name: "placeHolder", city: "placeholder"))
        }
        return tmpRestoList
    }
    
    // Call this function to update the table
    func updateTableFromDatabase(){
        self.rankingDatabaseReference.observeSingleEvent(of: .value, with: {snapshot in
            var tmpRanking = self.initializeArray(withElements: Int(snapshot.childrenCount))
            var count = 0
            // 1. Get the resto keys
            for child in snapshot.children{
                // Get the children
                if let testChild = child as? DataSnapshot,
                    let value = testChild.value as? [String: AnyObject],
                    let position = value["position"] as? Int,
                    let restoId = value["restoId"] as? String
                {
                    // For each Key go and find the values
                    self.restoDatabaseReference.child(restoId).observeSingleEvent(of: .value, with: {shot in
                        let tmpResto = Resto(snapshot: shot)
                        if tmpResto != nil {
                            tmpRanking[position-1] = tmpResto!
                            //tmpRanking.insert(tmpResto!, at: (position-1))
                        }
                        // Trick! If we have processed all children then we reload the Data
                        count += 1
                        if count == snapshot.childrenCount {
                            self.thisRanking = tmpRanking
                            self.editRankingTable.reloadData()
                        }
                    })
                }
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thisRankingId = currentCity.rawValue.lowercased() + "-" + currentFood
        // Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // Update the DB References
            self.rankingDatabaseReference = basicModel.dbRanking.child(user.uid+"-"+self.thisRankingId)
            self.restoDatabaseReference = basicModel.dbResto
            let tmpRef = basicModel.dbRestoPoints.child(self.currentCity.rawValue)
            self.restoPointsDatabaseReference = tmpRef.child(self.thisRankingFoodKey)
            
            self.updateTableFromDatabase()
        }

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
            return thisRanking.count
        case 1: return 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let tmpCell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath)
            if let cell = tmpCell as? MyRanksEditRankingTableViewCell {
                cell.restoForThisCell = thisRanking[indexPath.row]
                cell.restoImage.text = "Pic"
                let restoName = "\(indexPath.row + 1). \(thisRanking[indexPath.row].name)"
                cell.restoName.attributedText = NSAttributedString(string: restoName, attributes: [.font: restorantNameFont])
                let restoAddress = "Get address" //thisRanking[indexPath.row]
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
    //
    func restaurantChosenFromMap(someMapItem: MKMapItem) {
        // Build a tmpResto with the data from the delegation
        let tmpResto = Resto(name: someMapItem.placemark.name!, city: currentCity.rawValue)
        if someMapItem.url != nil{
            tmpResto.url = someMapItem.url!
        }
        
        // 1. Verify if the resto exists in the ranking
        if (thisRanking.filter {$0.key == tmpResto.key}).count > 0{
           showAlertDuplicateRestorant()
        }else{
            addRestoToModel(resto: tmpResto)
            addRestoToRanking(key: tmpResto.key, position: thisRanking.count)
            updateTableFromDatabase()
        }
        editRankingTable.reloadData()
    }
    
    // Add resto to model
    func addRestoToModel(resto: Resto){
        // 2. Verify if the resto exists in the resto list
        restoDatabaseReference.child(resto.key).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                print("No need to Add")
            }else{
                // Create a child reference with autoID and set the value
                let newRankingRef = self.restoDatabaseReference.child(resto.key)
                newRankingRef.setValue(resto.toAnyObject())
            }
        })
    }
    
    func positionToAny(position: Int, restoKey: String) -> Any{
        return ["position": position, "restoId": restoKey]
    }
    
    // Add resto to ranking
    func addRestoToRanking(key: String, position: Int){
        // I. Add to the ranking DB
        let newRestoRef = rankingDatabaseReference.childByAutoId()
        newRestoRef.setValue(positionToAny(position: position+1, restoKey: key))
        
        // II. Update the number of points
        // II.1. First get the number of points
        restoPointsDatabaseReference.observeSingleEvent(of: .value, with: {snapshot in
            var currentPoints:Int
            if let value = snapshot.value as? [String: AnyObject],
                let points = value[key] as? Int
            {
                currentPoints = points
                // II.2. Then update
                self.restoPointsDatabaseReference.updateChildValues([key:(currentPoints + (15-position-1))])
            }
        })
        
    }
    
    // Helper functions
    func showAlertDuplicateRestorant(){
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
                        //currentRanking!.updateList(sourceIndex: sourceIndexPath.row, destinationIndex: destinationIndexPath.row)
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
