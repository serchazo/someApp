//
//  MyRanksViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase

class MyRanks: UIViewController {
    
    // Class constants
    static let addRanking = "addRankSegue"
    static let showRakingDetail = "editRestoList"
    static let screenSize = UIScreen.main.bounds.size
    
    // Instance variables
    var user:User!
    var currentCity:BasicCity = .Singapore
    var rankings:[Ranking] = []
    var foodItems:[FoodType] = []
    var rankingReferenceForUser: DatabaseReference!
    var foodDBReference: DatabaseReference!
    var profileMenu = ["My profile", "Pic", "Settings", "Help & Support", "Log out"]
    
    //For the myProfile swipe table
    var transparentView = UIView()
    var myProfileTableView = UITableView()
    
    // Outlets
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
    
    // Action buttons
    
    @IBAction func myProfileAction(_ sender: UIBarButtonItem) {        
        // Create the frame
        let window = UIApplication.shared.keyWindow
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        transparentView.frame = self.view.frame
        window?.addSubview(transparentView)
        
        // Add the table
        myProfileTableView.frame = CGRect(
            x: MyRanks.screenSize.width,
            y: MyRanks.screenSize.height * 0.1,
            width: MyRanks.screenSize.width * 0.9,
            height: MyRanks.screenSize.height * 0.9)
        window?.addSubview(myProfileTableView)
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickTransparentView))
        transparentView.addGestureRecognizer(tapGesture)
        
        // Cool "slide-up" animation when appearing
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0.7 //Start at 0, go to 0.5
                        self.myProfileTableView.frame = CGRect(
                            x: MyRanks.screenSize.width * 0.1,
                            y: MyRanks.screenSize.height * 0.1 ,
                            width: MyRanks.screenSize.width * 0.9,
                            height: MyRanks.screenSize.height * 0.9)
        },
                       completion: nil)
    }
    
    //Disappear!
    @objc func onClickTransparentView(){
        // Animation when disapearing
        
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0 //Start at value above, go to 0
                        self.myProfileTableView.frame = CGRect(
                            x: MyRanks.screenSize.width,
                            y: MyRanks.screenSize.height * 0.1,
                            width: MyRanks.screenSize.width * 0.9,
                            height: MyRanks.screenSize.height * 0.9)
                        
        },
                       completion: nil)
        
        // Deselect the row to go back to normal
        if let indexPath = myRanksTable.indexPathForSelectedRow {
            myRanksTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
    //
    // MARK : Timeline funcs
    //
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Get the logged in user - needed for the next step
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // 2. Once we get the user, update!
            self.rankingReferenceForUser = basicModel.dbRankingsPerUser.child(user.uid)
            self.foodDBReference = basicModel.dbFoodTypeRoot
            self.updateTablewithRanking()
        }
        
        //
        myProfileTableView.delegate = self
        myProfileTableView.dataSource = self
    }
    
    func updateTablewithRanking(){
        
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: MyRanks.screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: MyRanks.screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = basicModel.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        labelView.text = "Tell the world your favorite restorants"
        
        headerView.addSubview(labelView)
        self.myRanksTable.tableHeaderView = headerView
        
        
        self.rankingReferenceForUser.observeSingleEvent(of: .value, with: {snapshot in
            //
            var tmpRankings: [Ranking] = []
            var tmpFoodType: [FoodType] = []
            var count = 0
            
            for ranksPerUserAny in snapshot.children {
                if let ranksPerUserSnapshot = ranksPerUserAny as? DataSnapshot,
                    let rankingItem = Ranking(snapshot: ranksPerUserSnapshot){
                    tmpRankings.append(rankingItem)
                    
                    //Get food type
                    self.foodDBReference.child(rankingItem.foodKey).observeSingleEvent(of: .value, with: { foodSnapshot in
                        let foodItem = FoodType(snapshot: foodSnapshot)
                        tmpFoodType.append(foodItem!)
                        // Apply the trick when using Joins
                        count += 1
                        if count == snapshot.childrenCount {
                            self.foodItems = tmpFoodType
                            self.rankings = tmpRankings
                            self.myRanksTable.reloadData()
                        }
                    })
                }
            }
        })
    }
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case MyRanks.showRakingDetail :
            if let seguedMVC = segue.destination as? EditRanking{
                if let tmpCell = sender as? MyRanksTableViewCell,
                    let tmpIndexPath = myRanksTable.indexPath(for: tmpCell){
                    // I should send Ranking, Food Key, and current city
                    seguedMVC.currentCity = self.currentCity
                    seguedMVC.thisRankingFoodKey = rankings[tmpIndexPath.row].foodKey
                }
            }
        case MyRanks.addRanking :
            if let seguedMVC = segue.destination as? MyRanksAddRankingViewController{
                seguedMVC.delegate = self
            }
        default: 
            break
        }
    }
    
}

// MARK : update the ranking list when we receive the event from the menu choser
extension MyRanks: MyRanksAddRankingViewDelegate{
    func addRankingReceiveInfoToCreate(inCity: String, withFood: FoodType) {
        
        // Test if we already have that ranking in our list
        if (rankings.filter {$0.city == inCity && $0.foodKey == withFood.key}).count == 0{
            // If we don't have the ranking, we add it to Firebase
            let newRanking = Ranking(city: inCity, foodKey: withFood.key)
            // Create a child reference and update the value
            let newRankingRef = self.rankingReferenceForUser.child(newRanking.key)
            newRankingRef.setValue(newRanking.toAnyObject())
            updateTablewithRanking()
            
        }else{
            // Ranking already in list
            let alert = UIAlertController(
                title: "Duplicate ranking",
                message: "You already have a \(withFood.name) ranking in \(inCity).",
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
}

// MARK : table stuff
extension MyRanks: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Verifiy if it's the myProfile table
        if tableView == myProfileTableView{
            return 1
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Verifiy if it's the myProfile table
        if tableView == myProfileTableView{
            return 5
        }else{
            // The normal table
            switch(section){
            case 0:
                guard rankings.count == foodItems.count else { return 1 }
                return rankings.count
            default: return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Not used
    }
    
    //cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Verifiy if it's the myProfile table
        if tableView == myProfileTableView{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = profileMenu[indexPath.row]
            return cell
        }else{
            // The normal table
            guard rankings.count > 0 && rankings.count == foodItems.count else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Waiting for services"
                let spinner = UIActivityIndicatorView(style: .gray)
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            
            // Rankings table
            let tmpCell = tableView.dequeueReusableCell(withIdentifier: "MyRanksCell", for: indexPath)
            if let cell = tmpCell as? MyRanksTableViewCell {
                cell.iconLabel.text = foodItems[indexPath.row].icon
                let tmpTitleText = "Best " + foodItems[indexPath.row].name + " in " + rankings[indexPath.row].city
                cell.titleLabel.text = tmpTitleText
                cell.descriptionLabel.text = rankings[indexPath.row].description
            }
            return tmpCell
        }
        
    }
}

// MARK: Some view stuff
extension MyRanks{
    private var iconFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    private var cellTitleFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
    
    private var cellCityNameFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(20.0))
    }
    
    /*
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(iconFont.lineHeight + 10.0)
    }*/
}

// MARK : drag delegate
extension MyRanks: UITableViewDragDelegate {
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
extension MyRanks: UITableViewDropDelegate{
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
                        // TODO : Update the model here
                        //let tempRanking = user.myRankings[sourceIndexPath.row]
                        //user.myRankings.remove(at: sourceIndexPath.row)
                        //user.myRankings.insert(tempRanking, at: destinationIndexPath.row)
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
