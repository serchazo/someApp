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
    private static let showRestoDetail = "ShowResto"
    private static let addResto = "addNewResto"
    private static let delRestoCell = "delRestoCell"
    private static let screenSize = UIScreen.main.bounds.size
    
    //Get from segue-r
    var currentCity: City!
    var currentFood: FoodType!
    var calledUserId:UserDetails! // Control variable
    
    // Instance variables
    private var user: User!
    private var thisRankingId: String!
    private var thisRankingDescription: String = ""
    private var userRankingDetailRef: DatabaseReference!
    private var userRankingsRef: DatabaseReference!
    private var restoDatabaseReference: DatabaseReference!
    private var restoPointsDatabaseReference: DatabaseReference!
    private var restoAddressDatabaseReference: DatabaseReference!
    private var thisRanking: [Resto] = []
    private var thisEditableRanking: [Resto] = []
    private var descriptionRowHeight = CGFloat(50.0)
    private var descriptionEditRankingRowHeight = CGFloat(70.0)
    
    //For Edit the description swipe-up
    private var transparentView = UIView()
    private var editDescriptionTableView = UITableView()
    private var editTextField = UITextView()
    
    //For "Edit the ranking" swipe left
    private var editRankTransparentView = UIView()
    private var editRankTableView = UITableView()
    private var navBar = UINavigationBar()
    private var operations:[RankingOperation] = []
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myRankingTable: UITableView!{
        didSet{
            myRankingTable.dataSource = self
            myRankingTable.delegate = self
            myRankingTable.dragDelegate = self
            myRankingTable.dragInteractionEnabled = true
            myRankingTable.dropDelegate = self
            myRankingTable.estimatedRowHeight = 70
            myRankingTable.rowHeight = UITableView.automaticDimension
        }
    }
    
    ///
    // MARK : Edit table
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        // Create the Edit TableView
        let windowEditRank = UIApplication.shared.keyWindow
        editRankTransparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        editRankTransparentView.frame = self.view.frame
        windowEditRank?.addSubview(editRankTransparentView)
        
        // Add a navigation bar - hidden first
        let navBarHeight =  self.navigationController!.navigationBar.frame.size.height
        navBar.frame = CGRect(
            x: EditRanking.screenSize.width,
            y: EditRanking.screenSize.height * 0.1,
            width: EditRanking.screenSize.width,
            height: navBarHeight)
        navBar.barTintColor = UIColor.white
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: SomeApp.themeColor]
        
        
        let navItem = UINavigationItem(title: "Edit ranking")
        let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(performUpdate))
        navItem.rightBarButtonItem = doneItem
        let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(onClickEditRankTransparentView))
        cancelItem.tintColor = SomeApp.themeColor
        doneItem.tintColor = SomeApp.themeColor
        
        navItem.leftBarButtonItem = cancelItem
        navBar.setItems([navItem], animated: false)
        windowEditRank?.addSubview(navBar)
        
        // Add the table
        editRankTableView.frame = CGRect(
            x: EditRanking.screenSize.width,
            y: EditRanking.screenSize.height * 0.1 + navBarHeight,
            width: EditRanking.screenSize.width,
            height: EditRanking.screenSize.height * 0.9 - navBarHeight)
        windowEditRank?.addSubview(editRankTableView)
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickEditRankTransparentView))
        editRankTransparentView.addGestureRecognizer(tapGesture)
        
        // Cool "slide-up" animation when appearing
        editRankTransparentView.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.editRankTransparentView.alpha = 0.7 //Start at 0, go to 0.5
                        self.navBar.frame = CGRect(
                            x: 0,
                            y: EditRanking.screenSize.height * 0.1,
                            width: EditRanking.screenSize.width,
                            height: navBarHeight)
                        self.editRankTableView.frame = CGRect(
                            x: 0,
                            y: EditRanking.screenSize.height * 0.1 + navBarHeight,
                            width: EditRanking.screenSize.width,
                            height: EditRanking.screenSize.height * 0.9)
                        //self.editTextField.becomeFirstResponder()
        },
                       completion: nil)
        
        
    }
    
    // MARK : timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set vars
        thisRankingId = currentCity.country + "/" + currentCity.state + "/" + currentCity.key+"/" + currentFood.key
        restoDatabaseReference = SomeApp.dbResto
        restoPointsDatabaseReference = SomeApp.dbRestoPoints.child(thisRankingId)
        restoAddressDatabaseReference = SomeApp.dbRestoAddress
        
        editRankTableView.register(UINib(nibName: "EditableRestoCell", bundle: nil), forCellReuseIdentifier: EditRanking.delRestoCell)
        
        // Verify if I'm asking for my data
        if calledUserId == nil {
            // Get the logged in user
            Auth.auth().addStateDidChangeListener {auth, user in
                guard let user = user else {return}
                self.user = user
                
                // I'm asking for my data
                let dbPath = user.uid+"/"+self.thisRankingId
                self.userRankingDetailRef = SomeApp.dbRanking.child(dbPath)
                self.userRankingsRef = SomeApp.dbRankingsPerUser.child(dbPath)
                self.updateTableFromDatabase()
                
                // The editDescriptionTableView needs to be loaded only if it's my data
                self.editDescriptionTableView.delegate = self
                self.editDescriptionTableView.dataSource = self
                self.editDescriptionTableView.register(MyRanksEditDescriptionCell.self, forCellReuseIdentifier: "EditDescriptionCell")
                self.editTextField.delegate = self
                
                // The editRankingTableView needs to be loaded only if it's my data
                self.editRankTableView.delegate = self
                self.editRankTableView.dataSource = self 
            }
        }else {
            // I'm asking for data of someone else
            let dbPath = calledUserId.key+"/"+self.thisRankingId
            self.userRankingDetailRef = SomeApp.dbRanking.child(dbPath)
            self.userRankingsRef = SomeApp.dbRankingsPerUser.child(dbPath)
            self.updateTableFromDatabase()
        }
        // In both cases
        navigationItem.title = currentFood.icon
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    // func
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    
    // Table : MyRankingTable
    func updateTableFromDatabase(){
        
        // 1. Header
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: EditRanking.screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: EditRanking.screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = SomeApp.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        if calledUserId == nil{
            labelView.text = "My favorite \(currentFood.name) places in \(currentCity.name)"
        }else{
            labelView.text = "\(calledUserId.nickName)'s favorite \(currentFood.name) places"
        }
        headerView.addSubview(labelView)
        self.myRankingTable.tableHeaderView = headerView
        
        
        // Get the description from my rankings
        self.userRankingsRef.observeSingleEvent(of: .value, with: {snapshot in
            if let rankingItem = Ranking(snapshot: snapshot){
                self.thisRankingDescription = rankingItem.description
                self.myRankingTable.reloadData()
            }
        })
        
        // Get the details
        self.userRankingDetailRef.observeSingleEvent(of: .value, with: {snapshot in
            var tmpRanking = self.initializeArray(withElements: Int(snapshot.childrenCount))
            var count = 0
            // 1. Get the resto keys
            for child in snapshot.children{
                // Get the children
                if let testChild = child as? DataSnapshot,
                    let value = testChild.value as? [String:AnyObject],
                    let position = value["position"] as? Int
                {
                    let restoId = testChild.key
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
                            self.thisEditableRanking = tmpRanking
                            self.myRankingTable.reloadData()
                        }
                    })
                }
            }
        })
    }
    
    func initializeArray(withElements: Int) -> [Resto] {
        var tmpRestoList: [Resto] = []
        for _ in 0..<withElements {
            tmpRestoList.append(Resto(name: "placeHolder", city: "placeholder"))
        }
        return tmpRestoList
    }
    
    // MARK : Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case EditRanking.showRestoDetail:
                if let cell = sender as? MyRanksEditRankingTableViewCell,
                    let indexPath = myRankingTable.indexPath(for: cell),
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

//////////////////////////
// MARK: Extension for the Table stuff
//////////////////////////

extension EditRanking: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // test if the table is the EditDescription pop-up
        if tableView == self.editDescriptionTableView{
            return 1
        }else if tableView == self.editRankTableView{
            return 2
        }else{
            // the normal table
            // I'm asking for my data
            if calledUserId == nil {
                return 3
            }else{
                // If I'm asking for another user's data, I don't need the last cell
                return 2
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // test if the table is the EditDescription pop-up
        if tableView == self.editDescriptionTableView{
            return 1
        }else if tableView == self.editRankTableView{
            if section == 0{ return 1}
            else {return thisEditableRanking.count}
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
    
    // Cell for Row at
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // EditDescription pop-up
        if tableView == self.editDescriptionTableView{
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EditDescriptionCell", for: indexPath) as? MyRanksEditDescriptionCell{
                setupEditDescriptionCell(cell: cell)
                return cell
            }else{
                fatalError("Unable to create cell")
            }
        // The Editable Ranking Table
        }else if tableView == self.editRankTableView{
            // Description cell
            if indexPath.section == 0 {
                let descriptionCell = UITableViewCell(style: .default, reuseIdentifier: nil)
                setupDescriptionEditRankingCell(descriptionEditRankingCell: descriptionCell)
                return descriptionCell
            }else{
                if let editRestoCell = editRankTableView.dequeueReusableCell(withIdentifier: EditRanking.delRestoCell, for: indexPath) as? EditableRestoCell{
                    editRestoCell.restoLabel.text = thisEditableRanking[indexPath.row].name
                    editRestoCell.tapAction = { (cell) in
                        // If the delete button is pressed, we show an alert asking for confirmation
                        let alert = UIAlertController(title: "Delete Restaurant?",
                                                      message: "",
                                                      preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Cancel",
                                                         style: .cancel)
                        
                        let delAction = UIAlertAction(title: "Delete", style: .destructive){ _ in
                            //Get the indexPath
                            let delIndexPath = self.editRankTableView.indexPath(for: cell)
                            // Add to the list of operations
                            self.operations.append(RankingOperation(operationType: .Delete, restoIdentifier: self.thisEditableRanking[delIndexPath!.row].key))
                            //Do the animation
                            self.thisEditableRanking.remove(at: delIndexPath!.row)
                            self.editRankTableView.deleteRows(at: [delIndexPath!], with: .fade)
                            
                        }
                        alert.addAction(cancelAction)
                        alert.addAction(delAction)
                        self.present(alert, animated: true, completion: nil)
                        // End of the Action
                    }
                    return editRestoCell
                }else{fatalError() }
            }
            /// The "normal" table
        }else{
            if indexPath.section == 0 {
                // The Description cell
                let descriptionCell = UITableViewCell(style: .default, reuseIdentifier: nil)
                setupDescriptionCell(descriptionCell: descriptionCell)
                return descriptionCell
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
                
            }else if indexPath.section == 2 {
                // The last cell : Add resto to ranking
                return tableView.dequeueReusableCell(withIdentifier: "AddRestoToRankingCell", for: indexPath)
            }else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                return cell
            }
            
        }
    }
    
    // If we press on a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.editRankTableView && indexPath.section == 0{
            
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
                            self.editDescriptionTableView.frame = CGRect(
                                x: 0,
                                y: EditRanking.screenSize.height - EditRanking.screenSize.height * 0.9 ,
                                width: EditRanking.screenSize.width,
                                height: EditRanking.screenSize.height * 0.9)
                            self.editTextField.becomeFirstResponder()
                            },
                           completion: nil)
          
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Test if it's the Edit Description table
        if tableView == self.editDescriptionTableView {
            return 450
        // "Editable" Table
        }else if tableView == editRankTableView{
            if indexPath.section == 0{ return descriptionEditRankingRowHeight+20}
            else{ return UITableView.automaticDimension}
        // "Normal" Table
        }else{
            if indexPath.section == 0{return descriptionRowHeight}
            else if indexPath.section == 1 {
                let cellHeight = restorantNameFont.lineHeight + restorantAddressFont.lineHeight + 45.0
                return CGFloat(cellHeight)
            }else{ return UITableView.automaticDimension }
        }
    }
}

/////////////////////
// MARK : setup cells
/////////////////////
extension EditRanking{
    // Setup the Description cell for the Editable table
    func setupDescriptionEditRankingCell(descriptionEditRankingCell: UITableViewCell){
        setupDescriptionCell(descriptionCell: descriptionEditRankingCell)
        // Label "Click to edit description"
        let clickToEditString = NSAttributedString(string: "Click to edit description", attributes: [.font : UIFont.preferredFont(forTextStyle: .footnote),.foregroundColor: #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) ])
        let clickToEditSize = clickToEditString.size()
        let clickToEditLabel = UILabel(frame: CGRect(
            x: descriptionEditRankingCell.frame.width - (clickToEditSize.width),
            y: descriptionRowHeight+5,
            width: clickToEditSize.width,
            height: clickToEditSize.height+5))
        clickToEditLabel.attributedText = clickToEditString
        descriptionEditRankingCell.addSubview(clickToEditLabel)
        
        // Override from the original setup
        descriptionEditRankingCell.isUserInteractionEnabled = true
        descriptionEditRankingCell.selectionStyle = .default
        
        descriptionEditRankingRowHeight = descriptionRowHeight + clickToEditSize.height
    }
    
    // Setup the "normal" Description cell
    func setupDescriptionCell(descriptionCell :UITableViewCell){
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
        
        descriptionLabel.frame = CGRect(x: 20, y: 15, width: EditRanking.screenSize.width-40, height: boundingBox.height)
        
        descriptionCell.addSubview(descriptionLabel)
        
        descriptionCell.isUserInteractionEnabled = false
        descriptionCell.selectionStyle = .none
        
        descriptionRowHeight = boundingBox.height + 35
    }
    
    // Setup the Edit Description Cell
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
    
    // Setup the editRestorantcell
    func setupEditableRestoCell(){
        
    }
    
}


////////////////////
// MARK : objc funcs
///////////////////

extension EditRanking{
    // Update the description when the button is pressed
    @objc
    func doneUpdating(){
        let descriptionDBRef = userRankingsRef.child("description")
        descriptionDBRef.setValue(editTextField.text)
        
        //Update view
        onClickTransparentView()
        updateTableFromDatabase()
    }
    
    // Perform the update
    @objc func performUpdate(){
        print("Update here")
        if operations.count > 0{
            for oper in operations{
                print(oper.restoIdentifier)
            }
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
        if let indexPath = editRankTableView.indexPathForSelectedRow {
            editRankTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc func onClickEditRankTransparentView(){
        //Set the variables back to normal
        thisEditableRanking = thisRanking
        editRankTableView.reloadData()
        operations.removeAll()
        
        //
        let navBarHeight =  self.navigationController!.navigationBar.frame.size.height
        // Animation when disapearing
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.editRankTransparentView.alpha = 0 //Start at value above, go to 0
                        self.navBar.frame = CGRect(
                            x: EditRanking.screenSize.width,
                            y: EditRanking.screenSize.height * 0.1,
                            width: EditRanking.screenSize.width,
                            height: navBarHeight)
                        self.editRankTableView.frame = CGRect(
                            x: 0,
                            y: EditRanking.screenSize.height ,
                            width: EditRanking.screenSize.width,
                            height: EditRanking.screenSize.height * 0.9)
                        //self.editTextField.resignFirstResponder()
        },
                       completion: nil)
    }
}

///////////////////
// MARK : get stuff from the segued view and process the info
//////////////////

extension EditRanking: MyRanksMapSearchViewDelegate{
    //
    func restaurantChosenFromMap(someMapItem: MKMapItem) {
        let tmpResto = Resto(name: someMapItem.placemark.name!, city: currentCity.key)
        // Verify if the resto exists in the ranking
        if (thisRanking.filter {$0.key == tmpResto.key}).count > 0{
           showAlertDuplicateRestorant()
        }else{
            SomeApp.addRestoToRanking(userId: user.uid, resto: tmpResto, mapItem: someMapItem, forFood: currentFood, position: thisRanking.count)
        }
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
        if indexPath.section == 0, let restoNameToDrag = (myRankingTable.cellForRow(at: indexPath) as? MyRanksEditRankingTableViewCell)?.restoName.attributedText{
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
                myRankingTable.performBatchUpdates(
                    {
                        //Update the model here
                        //currentRanking!.updateList(sourceIndex: sourceIndexPath.row, destinationIndex: destinationIndexPath.row)
                        // DO NOT RELOAD DATA HERE!!
                        // Delete row and then insert row instead
                        myRankingTable.deleteRows(at: [sourceIndexPath], with: UITableView.RowAnimation.left)
                        myRankingTable.insertRows(at: [destinationIndexPath], with: UITableView.RowAnimation.right)
                })
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
                //}
                myRankingTable.reloadData()
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
