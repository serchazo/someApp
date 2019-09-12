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

class EditRanking: UIViewController {
    // class variables
    static let showRestoDetail = "ShowResto"
    static let addResto = "addNewResto"
    static let screenSize = UIScreen.main.bounds.size
    
    //
    var user: User!
    var thisRankingId: String!
    var thisRankingFoodKey: String!
    var thisRankingDescription: String = ""
    var rankingDatabaseReference: DatabaseReference!
    var rankingsPeruserDBRef: DatabaseReference!
    var restoDatabaseReference: DatabaseReference!
    var restoPointsDatabaseReference: DatabaseReference!
    var restoAddressDatabaseReference: DatabaseReference!
    var thisRanking: [Resto] = []
    var descriptionRowHeight = CGFloat(50.0)
    
    //For Edit the description swipe-up
    var transparentView = UIView()
    var editDescriptionTableView = UITableView()
    var editTextField = UITextView()
    
    //Attention, variables initialized from segue-r MyRanksViewController
    var currentCity: BasicCity!
    
    // Outlets
    @IBOutlet weak var editRankingTable: UITableView!{
        didSet{
            editRankingTable.dataSource = self
            editRankingTable.delegate = self
            editRankingTable.dragDelegate = self
            editRankingTable.dragInteractionEnabled = true
            editRankingTable.dropDelegate = self
            editRankingTable.estimatedRowHeight = 70
            editRankingTable.rowHeight = UITableView.automaticDimension
        }
    }
    
    func initializeArray(withElements: Int) -> [Resto] {
        var tmpRestoList: [Resto] = []
        for _ in 0..<withElements {
            tmpRestoList.append(Resto(name: "placeHolder", city: "placeholder"))
        }
        return tmpRestoList
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thisRankingId = currentCity.rawValue.lowercased() + "-" + thisRankingFoodKey
        // Get the logged in user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            // Update the DB References
            self.rankingDatabaseReference = SomeApp.dbRanking.child(user.uid+"-"+self.thisRankingId)
            let tmpRankingsPeruser = SomeApp.dbRankingsPerUser.child(user.uid)
            self.rankingsPeruserDBRef = tmpRankingsPeruser.child(self.thisRankingId)
            
            self.restoDatabaseReference = SomeApp.dbResto
            
            let tmpRef = SomeApp.dbRestoPoints.child(self.currentCity.rawValue)
            self.restoPointsDatabaseReference = tmpRef.child(self.thisRankingFoodKey)
            self.restoAddressDatabaseReference = SomeApp.dbRestoAddress
            
            self.updateTableFromDatabase()
        }
        
        // Define the properties for the editDescription TableView
        editDescriptionTableView.delegate = self
        editDescriptionTableView.dataSource = self
        editDescriptionTableView.register(MyRanksEditDescriptionCell.self, forCellReuseIdentifier: "EditDescriptionCell")
        editTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when segued pops
        if let indexPath = editRankingTable.indexPathForSelectedRow {
            editRankingTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // Call this function to update the table
    func updateTableFromDatabase(){
        //
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: MyRanks.screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: MyRanks.screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = SomeApp.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        labelView.text = "Your favorite \(thisRankingFoodKey!) places"
        
        headerView.addSubview(labelView)
        self.editRankingTable.tableHeaderView = headerView
        //
        
        // Get the description
        self.rankingsPeruserDBRef.observeSingleEvent(of: .value, with: {snapshot in
            if let rankingItem = Ranking(snapshot: snapshot){
                self.thisRankingDescription = rankingItem.description
                self.editRankingTable.reloadData()
            }
        })
        
        // Big update
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
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case EditRanking.showRestoDetail:
                if let cell = sender as? MyRanksEditRankingTableViewCell,
                    let indexPath = editRankingTable.indexPath(for: cell),
                    let seguedToResto = segue.destination as? MyRestoDetail{
                    seguedToResto.currentResto = thisRanking[indexPath.row]
                }
            case EditRanking.addResto:
                if let seguedMVC = segue.destination as? MyRanksMapSearchViewController{
                    seguedMVC.delegate = self
                }
                
            default: break
            }
        }
    }
}

// MARK: Extension for the Table stuff
extension EditRanking: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // test if the table is the EditDescription pop-up
        if tableView == self.editDescriptionTableView{
            return 1
        }else{
            // the normal table
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // test if the table is the EditDescription pop-up
        if tableView == self.editDescriptionTableView{
            return 1
        }else{
            // The normal table
            switch(section){
            case 0:
                return 1
            case 1:
                return thisRanking.count
            case 2: return 1
            default: return 0
            }
        }
    }
    
    func setupEditDescriptionCell(cell: MyRanksEditDescriptionCell){
        
        //A label for warning the user about the max chars
        let maxCharsLabel = UILabel(frame: CGRect(
            x: 0,
            y: SomeApp.titleFont.lineHeight + 20,
            width: cell.frame.width,
            height: SomeApp.titleFont.lineHeight + 30 ))
        maxCharsLabel.textColor = UIColor.lightGray
        maxCharsLabel.textAlignment = NSTextAlignment.center
        maxCharsLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        maxCharsLabel.text = "(Max 250 characters)"
        
        // set up the TextField.  This var is defined in the class to take the value later
        editTextField.frame = CGRect(x: 8, y: 2 * SomeApp.titleFont.lineHeight + 60, width: cell.frame.width - 16, height: 200)
        editTextField.textColor = UIColor.gray
        editTextField.font = UIFont.preferredFont(forTextStyle: .body)
        if thisRankingDescription != "" {
            editTextField.text = thisRankingDescription
        }else{
            editTextField.text = "Enter a description for your ranking."
        }
        editTextField.keyboardType = UIKeyboardType.default
        editTextField.allowsEditingTextAttributes = true
        
        let doneButton = UIButton(type: .custom)
        doneButton.frame = CGRect(x: cell.frame.width - 100, y: 250, width: 70, height: 70)
        doneButton.backgroundColor = SomeApp.themeColor
        doneButton.layer.cornerRadius = 0.5 * doneButton.bounds.size.width
        doneButton.layer.masksToBounds = true
        doneButton.setTitle("Done!", for: .normal)
        doneButton.addTarget(self, action: #selector(doneUpdating), for: .touchUpInside)
        
        //editTextField.addSubview(doneButton)
        cell.selectionStyle = .none
        cell.backView.addSubview(maxCharsLabel)
        cell.backView.addSubview(editTextField)
        cell.backView.addSubview(doneButton)
    }
    
    // Update the model when the button is pressed
    @objc
    func doneUpdating(){
        let descriptionDBRef = rankingsPeruserDBRef.child("description")
        descriptionDBRef.setValue(editTextField.text)

        //Update view
        onClickTransparentView()
        updateTableFromDatabase()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // test if the table is the EditDescription pop-up
        if tableView == self.editDescriptionTableView{
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EditDescriptionCell", for: indexPath) as? MyRanksEditDescriptionCell{
                setupEditDescriptionCell(cell: cell)
                return cell
            }else{
                fatalError("Unable to create cell")
            }
            
        }else{
            // The normal table
            if indexPath.section == 0 {
                // The Description cell
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                
                let descriptionLabel = UILabel()
                descriptionLabel.lineBreakMode = .byWordWrapping
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
                descriptionLabel.text = thisRankingDescription
                
                //Get the label Size with the manip
                let maximumLabelSize = CGSize(width: EditRanking.screenSize.width, height: EditRanking.screenSize.height);
                let transformedText = thisRankingDescription as NSString
                let boundingBox = transformedText.boundingRect(
                    with: maximumLabelSize,
                    options: .usesLineFragmentOrigin,
                    attributes: [.font : UIFont.preferredFont(forTextStyle: .body)],
                    context: nil)
                
                descriptionLabel.frame = CGRect(x: 20, y: 0, width: EditRanking.screenSize.width-40, height: boundingBox.height)
                
                cell.addSubview(descriptionLabel)
                
                let clickToEditString = NSAttributedString(string: "Click to edit", attributes: [.font : UIFont.preferredFont(forTextStyle: .footnote),.foregroundColor: #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) ])
                
                let clickToEditSize = clickToEditString.size()
                let clickToEditLabel = UILabel(frame: CGRect(
                    x: cell.frame.width - (clickToEditSize.width),
                    y: boundingBox.height,
                    width: clickToEditSize.width,
                    height: clickToEditSize.height+10))
                clickToEditLabel.attributedText = clickToEditString
                
                cell.addSubview(clickToEditLabel)
                
                descriptionRowHeight = boundingBox.height + clickToEditSize.height + 20
                
                return cell
            }
            else if indexPath.section == 1 {
                // Restaurants cells
                let tmpCell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath)
                if let cell = tmpCell as? MyRanksEditRankingTableViewCell {
                    cell.restoForThisCell = thisRanking[indexPath.row]
                    cell.restoImage.text = "Pic"
                    let restoName = "\(indexPath.row + 1). \(thisRanking[indexPath.row].name)"
                    cell.restoName.attributedText = NSAttributedString(string: restoName, attributes: [.font: restorantNameFont])
                    let restoAddress = thisRanking[indexPath.row].address
                    cell.restoTmpInfo.attributedText = NSAttributedString(string: restoAddress, attributes: [.font : restorantAddressFont])
                }
                return tmpCell
                
            }else{
                // The last cell : Add resto to ranking
                return tableView.dequeueReusableCell(withIdentifier: "AddRestoToRankingCell", for: indexPath)
            }
        }
    }
    
    // If we press on a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.editRankingTable && indexPath.section == 0{
            
            // Slide up the Edit TableView
            let window = UIApplication.shared.keyWindow
            transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            transparentView.frame = self.view.frame
            window?.addSubview(transparentView)
            
            // Add the table
            
            editDescriptionTableView.frame = CGRect(
                x: 0,
                y: EditRanking.screenSize.height,
                width: EditRanking.screenSize.width,
                height: EditRanking.screenSize.height * 0.9)
            window?.addSubview(editDescriptionTableView)
            
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
                            self.editDescriptionTableView.frame = CGRect(x: 0, y: EditRanking.screenSize.height - EditRanking.screenSize.height * 0.9 , width: EditRanking.screenSize.width, height: EditRanking.screenSize.height * 0.9)
                            self.editTextField.becomeFirstResponder()
                            },
                           completion: nil)
            
          
        }
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
                        self.editDescriptionTableView.frame = CGRect(
                            x: 0,
                            y: EditRanking.screenSize.height ,
                            width: EditRanking.screenSize.width,
                            height: EditRanking.screenSize.height * 0.9)
                        self.editTextField.resignFirstResponder()
                        
                        },
                       completion: nil)
        
        // Deselect the row to go back to normal
        if let indexPath = editRankingTable.indexPathForSelectedRow {
            editRankingTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Test if it's the Edit Description table
        if tableView == self.editDescriptionTableView {
            return 450
        }else{
            // The normal table
            if indexPath.section == 0{
                return descriptionRowHeight
            }
            else if indexPath.section == 1 {
                let cellHeight = restorantNameFont.lineHeight + restorantAddressFont.lineHeight + 45.0
                return CGFloat(cellHeight)
            }else{
                return UITableView.automaticDimension
            }
            
        }
    }
}

// MARK : get stuff from the segued view and process the info
extension EditRanking: MyRanksMapSearchViewDelegate{
    //
    func restaurantChosenFromMap(someMapItem: MKMapItem) {
        // Build a tmpResto with the data from the delegation
        let tmpResto = Resto(name: someMapItem.placemark.name!, city: currentCity.rawValue)
        // Add details
        if someMapItem.url != nil{ tmpResto.url = someMapItem.url! }
        if someMapItem.phoneNumber != nil {tmpResto.phoneNumber = someMapItem.phoneNumber!}
        if someMapItem.placemark.formattedAddress != nil {
            tmpResto.address = someMapItem.placemark.formattedAddress!
        }
        
        // 1. Verify if the resto exists in the ranking
        if (thisRanking.filter {$0.key == tmpResto.key}).count > 0{
           showAlertDuplicateRestorant()
        }else{
            addRestoToModel(resto: tmpResto, withMapItem: someMapItem)
        }
    }
    
    // Add resto to model
    func addRestoToModel(resto: Resto, withMapItem: MKMapItem){
        // A. Check if the resto exists in the resto list
        restoDatabaseReference.child(resto.key).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                //I. if it exists, then do nothing
                //print("No need to Add")
            }else{
                // II. We need to add the resto many places
                
                // Add the resto to the Resto table
                let newRankingRef = self.restoDatabaseReference.child(resto.key)
                newRankingRef.setValue(resto.toAnyObject())
                
                // Add the resto to the Points table
                let newRankingCityPointsRef = self.restoPointsDatabaseReference.child(resto.key)
                let newRankingNbPointsRef = newRankingCityPointsRef.child("points")
                newRankingNbPointsRef.setValue(0)
                
                // Add the resto to the Address table
                self.addrestoAddressToModel(mapItem: withMapItem, toRestoKey: resto.key)
            }
            // B. even if it exists, we add to our ranking
            self.addRestoToRanking(key: resto.key, position: self.thisRanking.count)
            self.updateTableFromDatabase()
        })
    }
    
    // Add restoAddressToModel
    func addrestoAddressToModel(mapItem: MKMapItem, toRestoKey: String){
        
        let restoAddress = RestoMapArray(fromMapItem: mapItem)
        let encoder = JSONEncoder()
        
        do {
            let encodedMapItem = try encoder.encode(restoAddress)
            let encodedMapItemForFirebase = NSString(data: encodedMapItem, encoding: String.Encoding.utf8.rawValue)
            let newRestoAddressRef = restoAddressDatabaseReference.child(toRestoKey)
            let again = newRestoAddressRef.child("address")
            again.setValue(encodedMapItemForFirebase)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    

    
    // Add resto to ranking
    func addRestoToRanking(key: String, position: Int){
        // I. Add to the ranking DB
        let newRestoRef = rankingDatabaseReference.childByAutoId()
        newRestoRef.setValue(positionToAny(position: position+1, restoKey: key))
        
        // II. Update the number of points
        // II.1. First get the number of points
        restoPointsDatabaseReference.child(key).observeSingleEvent(of: .value, with: {snapshot in
            var currentPoints:Int
            if let value = snapshot.value as? [String: AnyObject],
                let points = value["points"] as? Int
            {
                currentPoints = points
                // II.2. Then update
                self.restoPointsDatabaseReference.child(key).updateChildValues(["points":(currentPoints + (15-position-1))])
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
    // Helper func to convert to Any
    func positionToAny(position: Int, restoKey: String) -> Any{
        return ["position": position, "restoId": restoKey]
    }
    
}


// MARK: The fonts
extension EditRanking{
    private var iconFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    private var restorantNameFont: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(25.0))
    }
    
    private var restorantAddressFont:UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(15.0))
    }
}

// MARK : Extension for Drag
extension EditRanking: UITableViewDragDelegate{
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
extension EditRanking : UITableViewDropDelegate {
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

extension EditRanking:UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 250
    }
    
}
