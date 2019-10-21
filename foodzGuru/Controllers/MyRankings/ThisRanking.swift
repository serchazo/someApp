//
//  MyRanksEditRankingViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class ThisRanking: UIViewController {
    // class variables
    private static let showRestoDetail = "ShowResto"
    private static let addResto = "addNewResto"
    private static let delRestoCell = "delRestoCell"
    private static let screenSize = UIScreen.main.bounds.size
    private let editReviewCell = "EditReviewCell"
    
    //Get from segue-r
    var currentCity: City!
    var currentFood: FoodType!
    var calledUser: UserDetails! // Control variable
    var profileImage: UIImage! // If we don't get it from segue-r, it's OK
    
    // Instance variables
    private var user: User!
    private var thisRankingId: String!
    private var thisRankingDescription: String = ""
    
    private var userRankingDetailRef: DatabaseReference!
    private var userRankingsRef: DatabaseReference!
    private var userReviewsRef : DatabaseReference!
    private var restoDatabaseReference: DatabaseReference!
    private var restoPointsDatabaseReference: DatabaseReference!
    private var restoAddressDatabaseReference: DatabaseReference!
    private var thisRanking: [Resto] = []
    private var thisEditableRanking: [Resto] = []
    private var thisRankingReviews: [(text: String, timestamp: Double)] = []
    private var descriptionRowHeight = CGFloat(50.0)
    private var descriptionEditRankingRowHeight = CGFloat(70.0)
    
    //For Edit Review swipe-up
    private var editReviewTransparentView = UIView()
    private var editReviewTableView = UITableView()
    private var indexPlaceholder:Int = 0
    
    //For Edit the description swipe-up
    private var transparentView = UIView()
    private var editDescriptionTableView = UITableView()
    private var editTextField = UITextView()
    private let editDescriptionCellId = "EditReviewCell"
    private let editDescriptionCellXib = "EditReviewCell"
    
    //For "Edit the ranking" swipe left
    private var editRankTransparentView = UIView()
    private var editRankTableView = UITableView()
    private var navBar = UINavigationBar()
    private var operations:[RankingOperation] = []
    
    // Header outlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var rankingTitleLabel: UILabel!
    @IBOutlet weak var rankingDescriptionLabel: UILabel!
    @IBOutlet weak var editDescriptionButton: UIButton!{
        didSet{
            editDescriptionButton.isHidden = true
            editDescriptionButton.isEnabled = false
        }
    }
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var editRankingBarButton: UIBarButtonItem!
    
    // Ad stuff
    private var bannerView: GADBannerView!
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myRankingTable: UITableView!{
        didSet{
            myRankingTable.dataSource = self
            myRankingTable.delegate = self
        }
    }
    
    ///
    // MARK: Edit table
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        // Create the Edit TableView
        let windowEditRank = UIApplication.shared.keyWindow
        editRankTransparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        editRankTransparentView.frame = self.view.frame
        windowEditRank?.addSubview(editRankTransparentView)
        
        // Add a navigation bar - hidden first
        let navBarHeight =  self.navigationController!.navigationBar.frame.size.height
        navBar.frame = CGRect(
            x: ThisRanking.screenSize.width,
            y: ThisRanking.screenSize.height * 0.1,
            width: ThisRanking.screenSize.width,
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
            x: ThisRanking.screenSize.width,
            y: ThisRanking.screenSize.height * 0.1 + navBarHeight,
            width: ThisRanking.screenSize.width,
            height: ThisRanking.screenSize.height * 0.9 - navBarHeight)
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
                            y: ThisRanking.screenSize.height * 0.1,
                            width: ThisRanking.screenSize.width,
                            height: navBarHeight)
                        self.editRankTableView.frame = CGRect(
                            x: 0,
                            y: ThisRanking.screenSize.height * 0.1 + navBarHeight,
                            width: ThisRanking.screenSize.width,
                            height: ThisRanking.screenSize.height * 0.9)
                        //self.editTextField.becomeFirstResponder()
        },
                       completion: nil)
        
        
    }
    
    // MARK: timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set vars
        let thisRankingIdwithoutFood = currentCity.country + "/" + currentCity.state + "/" + currentCity.key
        thisRankingId = currentCity.country + "/" + currentCity.state + "/" + currentCity.key+"/" + currentFood.key
        restoDatabaseReference = SomeApp.dbResto.child(thisRankingIdwithoutFood)
        restoPointsDatabaseReference = SomeApp.dbRestoPoints.child(thisRankingId)
        restoAddressDatabaseReference = SomeApp.dbRestoAddress
        
        // Verify if I'm asking for my data
        if calledUser == nil {
            // Get the logged in user
            Auth.auth().addStateDidChangeListener {auth, user in
                guard let user = user else {return}
                self.user = user
                
                // I'm asking for my data
                let dbPath = user.uid+"/"+self.thisRankingId
                self.userRankingDetailRef = SomeApp.dbUserRankingDetails.child(dbPath)
                self.userRankingsRef = SomeApp.dbUserRankings.child(dbPath)
                self.userReviewsRef = SomeApp.dbUserReviews.child(dbPath)
                
                self.updateTableFromDatabase()
                self.setupMyTables()
                
                // Configure the header: Attention, need to do it after setting the DB vars
                self.configureHeader(userId: user.uid)
            }
        }else {
            // I'm asking for data of someone else
            let dbPath = calledUser.key+"/"+self.thisRankingId
            self.userRankingDetailRef = SomeApp.dbUserRankingDetails.child(dbPath)
            self.userRankingsRef = SomeApp.dbUserRankings.child(dbPath)
            self.userReviewsRef = SomeApp.dbUserReviews.child(dbPath)
            self.updateTableFromDatabase()
            
            // Configure the header: Attention, need to do it after setting the DB vars
            configureHeader(userId: calledUser.key)
        }
        // In both cases
        
        // Some setup
        myRankingTable.estimatedRowHeight = 100
        myRankingTable.rowHeight = UITableView.automaticDimension
        
        // Configure the banner ad
        configureBannerAd()
    }
    
    // func
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //self.userRankingDetailRef.removeAllObservers()
    }
    
    
    // MARK: setup My tables
    private func setupMyTables(){
        // The editDescriptionTableView needs to be loaded only if it's my data
        editDescriptionTableView.delegate = self
        editDescriptionTableView.dataSource = self
        editDescriptionTableView.register(UINib(nibName: editDescriptionCellXib, bundle: nil), forCellReuseIdentifier: editDescriptionCellId)
        editTextField.delegate = self
        
        // The editRankingTableView needs to be loaded only if it's my data
        editRankTableView.delegate = self
        editRankTableView.dataSource = self
        editRankTableView.dragDelegate = self
        editRankTableView.dragInteractionEnabled = true
        editRankTableView.dropDelegate = self
        editRankTableView.register(UINib(nibName: "EditableRestoCell", bundle: nil), forCellReuseIdentifier: ThisRanking.delRestoCell)
        
        // The editReviewTableView needs to be loaded only if it's my data
        editReviewTableView.delegate = self
        editReviewTableView.dataSource = self
        editReviewTableView.register(UINib(nibName: editReviewCell, bundle: nil), forCellReuseIdentifier: editReviewCell)
        
    }

    // MARK: myRanking Header
    private func configureHeader(userId: String){
        // Configure navbar
        navigationItem.title = "foodz.guru"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        if calledUser != nil{
            navigationItem.rightBarButtonItem = nil
        }
        
        // Picture
        FoodzLayout.configureProfilePicture(imageView: imageView)
        
        if profileImage != nil{
            imageView.image = profileImage!
        }else{
            // If the segue-r doesn't send us an image, we go look for it :)
            SomeApp.dbUserData.child(userId).observeSingleEvent(of: .value, with: {snapshot in
                if let value = snapshot.value as? [String: AnyObject]{
                    var photoURL: URL!
                    if let tmpPhotoURL = value["photourl"] as? String {
                        photoURL = URL(string: tmpPhotoURL)
                    }else{
                        photoURL = URL(string: "")
                    }
                    self.imageView.sd_setImage(
                    with: photoURL,
                    placeholderImage: UIImage(named: "userdefault"),
                    options: [],
                    completed: nil)
                }
            })
        }
        
        // Title
        if calledUser == nil{
            rankingTitleLabel.text = "My favorite \(currentFood.name) places in \(currentCity.name)"
        }else{
            rankingTitleLabel.text = "\(calledUser.nickName)'s favorite \(currentFood.name) places"
        }
        // Description
        self.userRankingsRef.observe(.value, with: {snapshot in
            if let rankingItem = Ranking(snapshot: snapshot){
                self.rankingDescriptionLabel.text = rankingItem.description
                self.thisRankingDescription = rankingItem.description
                //self.myRankingTable.reloadData()
            }
        })
        
        // Edit Description Button
        if calledUser == nil {
            FoodzLayout.configureButton(button: editDescriptionButton)
            
            editDescriptionButton.setTitle("Edit Description", for: .normal)
            editDescriptionButton.addTarget(self, action: #selector(popUpEditDescriptionTable), for: .touchUpInside)
            editDescriptionButton.isHidden = false
            editDescriptionButton.isEnabled = true
            
        }
        
    }
    
    // MARK: update from database
    private func updateTableFromDatabase(){
        
        // I. Outer: get the Resto keys and Positions
        self.userRankingDetailRef.observe(.value, with: {snapshot in
            var tmpPositions = self.initializeStringArray(withElements: Int(snapshot.childrenCount))
            var tmpRanking = self.initializeArray(withElements: Int(snapshot.childrenCount))
            self.thisRankingReviews = self.initializeReviewArray(withElements: Int(snapshot.childrenCount))
            var count = 0
            
            // 1. Get the resto keys
            for child in snapshot.children{
                if let testChild = child as? DataSnapshot,
                    let value = testChild.value as? [String:AnyObject],
                    let position = value["position"] as? Int {
                    let restoId = testChild.key
                    tmpPositions[position-1] = restoId
                    
                    // Get the Resto data
                    self.restoDatabaseReference.child(restoId).observeSingleEvent(of: .value, with: {restoDetailSnap in
                        let tmpResto = Resto(snapshot: restoDetailSnap)
                        if tmpResto != nil{
                            tmpRanking[position-1] = tmpResto!
                        }
                        // Then
                        count += 1
                        if count == snapshot.childrenCount{
                            self.thisRanking = tmpRanking
                            self.thisEditableRanking = tmpRanking
                            self.myRankingTable.reloadData()
                            
                            // then get the Reviews.  Update by row
                            for tmpRestoId in tmpPositions{
                                self.userReviewsRef.child(tmpRestoId).observe(.value, with:{ reviewSnap in
                                    if let reviewValue = reviewSnap.value as? [String: AnyObject],
                                        let reviewText = reviewValue["text"] as? String,
                                        let timestamp = reviewValue["timestamp"] as? Double{
                                        let thisReviewPosition = tmpPositions.firstIndex(of: reviewSnap.key)
                                        self.thisRankingReviews[thisReviewPosition!] = (text: reviewText, timestamp: timestamp)
                                        self.myRankingTable.reloadRows(
                                            at: [IndexPath(row: thisReviewPosition!, section: 0)],
                                            with: .none)
                                    }
                                })
                            }
                            //
                        }
                    })
                    
                }
            }
        })
    }
    
    // MARK: Initialize Arrays
    func initializeArray(withElements: Int) -> [Resto] {
        var tmpRestoList: [Resto] = []
        for _ in 0..<withElements {
            tmpRestoList.append(Resto(name: "placeHolder", city: "placeholder"))
        }
        return tmpRestoList
    }
    
    func initializeStringArray(withElements: Int) -> [String]{
        var tmpArray: [String] = []
        for _ in 0..<withElements {
            tmpArray.append("")
        }
        return tmpArray
    }
    
    func initializeReviewArray(withElements: Int) -> [(text: String, timestamp: Double)]{
        var tmpReviewList: [(text: String, timestamp: Double)] = []
        
        for _ in 0..<withElements {
            tmpReviewList.append((text:"",timestamp: 0.0))
        }
        return tmpReviewList
    }
    
    // MARK: Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == ThisRanking.addResto{
            return true
        }else{
            return false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case ThisRanking.showRestoDetail:
                if let cell = sender as? ThisRankingCell,
                    let indexPath = myRankingTable.indexPath(for: cell),
                    let seguedToResto = segue.destination as? MyRestoDetail{
                    seguedToResto.currentResto = thisRanking[indexPath.row]
                    seguedToResto.currentCity = currentCity
                }
            case ThisRanking.addResto:
                if let seguedMVC = segue.destination as? MyRanksMapSearchViewController{
                    seguedMVC.delegate = self
                }
                
            default: break
            }
        }
    }
}

// MARK: Table stuff
extension ThisRanking: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // if it's the editReview pop-up
        if tableView == self.editReviewTableView{
            return 1
        }else if tableView == self.editDescriptionTableView{
            // test if the table is the EditDescription pop-up
            return 1
        }else if tableView == self.editRankTableView{
            return 1
        }else{
            // the normal table
            // I'm asking for my data
            if calledUser == nil {
                return 2
            }else{
                // If I'm asking for another user's data, I don't need the last cell
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == editReviewTableView{
            return 1
        }
        // test if the table is the EditDescription pop-up
        else if tableView == self.editDescriptionTableView{
            return 1
        }else if tableView == self.editRankTableView{
            return thisEditableRanking.count
        }else{
            // The normal table
            switch(section){
            case 0:
                return thisRanking.count
            case 1: return 1
            default: return 0
            }
        }
    }
    
    // Cell for Row at
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Edit Review pop-up
        if tableView == editReviewTableView,
            let editReviewCell = editReviewTableView.dequeueReusableCell(withIdentifier: editReviewCell) as? EditReviewCell{
            configureEditReviewCell(cell: editReviewCell, forIndex: indexPlaceholder)
            
            return editReviewCell
        }
        // EditDescription pop-up
        else if tableView == self.editDescriptionTableView,
            let cell = tableView.dequeueReusableCell(withIdentifier: editDescriptionCellId, for: indexPath) as? EditReviewCell{
            configureEditDescriptionCell(cell: cell)
            return cell
            
        // The Editable Ranking Table
        }else if tableView == self.editRankTableView{
            
            if let editRestoCell = editRankTableView.dequeueReusableCell(withIdentifier: ThisRanking.delRestoCell, for: indexPath) as? EditableRestoCell{
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
            
            // The "normal" table
        }else{
            if indexPath.section == 0 {
                // Restaurants cells
                let tmpCell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath)
                if let cell = tmpCell as? ThisRankingCell {
                    // Position
                    let position = indexPath.row + 1
                    cell.positionLabel.text = String(position)
                    // Name
                    cell.restoName.text = thisRanking[indexPath.row].name
                    // Points
                    cell.pointsGivenLabel.text = "Points: ToDo"
                    
                    // Review
                    if !(thisRankingReviews.count > 0) {
                        cell.reviewLabel.text = " " // the space is important
                        let spinner = UIActivityIndicatorView(style: .gray)
                        spinner.startAnimating()
                        cell.reviewLabel.addSubview(spinner)
                    }else{ // We already downloaded the reviews
                        cell.reviewLabel.text = thisRankingReviews[indexPath.row].text
                    }
                    
                    // Edit review button
                    if calledUser == nil{
                        FoodzLayout.configureButton(button: cell.editReviewButton)
                        cell.editReviewButton.setTitle("Edit Review", for: .normal)
                        cell.editReviewButton.isHidden = false
                        cell.editReviewButton.isEnabled = true
                        cell.editReviewAction = {(cell) in
                            
                            self.indexPlaceholder = self.myRankingTable.indexPath(for: cell)!.row
                            self.editReview()
                        }
                        
                    }
                    // Details button
                    cell.showRestoDetailAction = {(cell) in
                        self.performSegue(withIdentifier: ThisRanking.showRestoDetail, sender: cell)
                    }
                    
                }
                return tmpCell
                
            }else if indexPath.section == 1 {
                // The last cell : Add resto to ranking
                return tableView.dequeueReusableCell(withIdentifier: "AddRestoToRankingCell", for: indexPath)
            }else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                return cell
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == editReviewTableView{
            return 450
        }
        // Test if it's the Edit Description table
        else if tableView == self.editDescriptionTableView {
            return 450
        // All the others are automatic dimension
        }else{
            return UITableView.automaticDimension
        }
    }
}

// MARK: setup cells
extension ThisRanking{
    
    // MARK: "normal" Description cell
    func setupDescriptionCell(descriptionCell :UITableViewCell){
        let descriptionLabel = UILabel()
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        descriptionLabel.text = thisRankingDescription
        
        //Get the label Size with the manip
        let maximumLabelSize = CGSize(width: ThisRanking.screenSize.width, height: ThisRanking.screenSize.height);
        let transformedText = thisRankingDescription as NSString
        let boundingBox = transformedText.boundingRect(
            with: maximumLabelSize,
            options: .usesLineFragmentOrigin,
            attributes: [.font : UIFont.preferredFont(forTextStyle: .body)],
            context: nil)
        
        descriptionLabel.frame = CGRect(x: 20, y: 15, width: ThisRanking.screenSize.width-40, height: boundingBox.height)
        
        descriptionCell.addSubview(descriptionLabel)
        
        descriptionCell.isUserInteractionEnabled = false
        descriptionCell.selectionStyle = .none
        
        descriptionRowHeight = boundingBox.height + 35
    }
    
    //MARK: Description cell for the Editable table
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
    
    // MARK: Edit Description Cell
    func configureEditDescriptionCell(cell: EditReviewCell){
        FoodzLayout.configureEditTextCell(cell: cell)
        
        //title
        cell.titleLabel.text = "Edit your Ranking description"
        
        // Warning Label
        cell.warningLabel.text = "(Max 250 characters)"
        
        
        // set up the TextField
        if thisRankingDescription != "" {
            cell.editReviewTextView.text = thisRankingDescription
        }else{
            cell.editReviewTextView.text = "Enter a description for your ranking."
        }
        cell.editReviewTextView.becomeFirstResponder()
        
        // Button
        cell.doneButton.setTitle("Done!", for: .normal)
        cell.updateReviewAction = { (cell) in
            self.doneUpdatingDescription()
        }
    }
    
    // MARK: Edit review cell
    func configureEditReviewCell(cell: EditReviewCell, forIndex: Int){
        FoodzLayout.configureEditTextCell(cell: cell)
        
        //title
        cell.titleLabel.text = "My review for \(thisRanking[forIndex].name)"
        
        // set up the TextField placeholder
        if thisRankingReviews[forIndex].text.count < 5{
            cell.editReviewTextView.text = "Write your Review here."
        }else{
            cell.editReviewTextView.text = thisRankingReviews[forIndex].text
        }
        cell.editReviewTextView.becomeFirstResponder()
        
        // Done Button
        cell.doneButton.setTitle("Done!", for: .normal)
        cell.updateReviewAction = { (cell) in
            self.doneUpdating(resto: self.thisRanking[self.indexPlaceholder],
                              commentText: cell.editReviewTextView.text)
        }
    }
}


// MARK: objc funcs

extension ThisRanking{
    // Update the description when the button is pressed
    @objc func doneUpdatingDescription(){
        let descriptionDBRef = userRankingsRef.child("description")
        descriptionDBRef.setValue(editTextField.text)
        
        //Update view
        onClickTransparentView()
        onClickEditRankTransparentView()
    }
    
    // Perform the update
    @objc func performUpdate(){
        if operations.count > 0{
            let delOperations = operations.filter({$0.operationType == .Delete})
            delOperations.map({SomeApp.deleteRestoFromRanking(userId: user.uid, city: currentCity, foodId: currentFood.key, restoId: $0.restoIdentifier) })
            
            // Update the ranking
            SomeApp.updateRanking(userId: user.uid, city: currentCity, foodId: currentFood.key, ranking: thisEditableRanking)
        }
        //Update view
        onClickEditRankTransparentView()
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
                            y: ThisRanking.screenSize.height ,
                            width: ThisRanking.screenSize.width,
                            height: ThisRanking.screenSize.height * 0.9)
                        self.editDescriptionTableView.endEditing(true)
                        
        },
                       completion: nil)
        
        // Deselect the row to go back to normal
        if let indexPath = editRankTableView.indexPathForSelectedRow {
            editRankTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: Write review & close the pop-up table
    func doneUpdating(resto: Resto, commentText: String){
        // Write to model
        if ![""," ","Write your Review here","Write your Review here."].contains(commentText){
            SomeApp.updateUserReview(userid: user.uid, resto: resto, city: currentCity, foodId: currentFood.key ,text: commentText)
        }
        //Close the view
        onClickEditReviewTransparentView()
    }
    
    //Disappear!
    @objc func onClickEditReviewTransparentView(){
        // Animation when disapearing
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.editReviewTransparentView.alpha = 0 //Start at value above, go to 0
                        self.editReviewTableView.frame = CGRect(
                            x: 0,
                            y: ThisRanking.screenSize.height ,
                            width: ThisRanking.screenSize.width,
                            height: ThisRanking.screenSize.height * 0.9)
                        self.editReviewTableView.endEditing(true)
        },
                       completion: nil)
    }
    
    @objc func onClickEditRankTransparentView(){
        //Set the variables back to normal
        updateTableFromDatabase()
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
                            x: ThisRanking.screenSize.width,
                            y: ThisRanking.screenSize.height * 0.1,
                            width: ThisRanking.screenSize.width,
                            height: navBarHeight)
                        self.editRankTableView.frame = CGRect(
                            x: 0,
                            y: ThisRanking.screenSize.height ,
                            width: ThisRanking.screenSize.width,
                            height: ThisRanking.screenSize.height * 0.9)
                        //self.editTextField.resignFirstResponder()
        },
                       completion: nil)
    }
    
    // MARK: Popup the Edit description table
    @objc func popUpEditDescriptionTable(){
        FoodzLayout.popupTable(viewController: self,
                               transparentView: transparentView,
                               tableView: editDescriptionTableView)
        
        // Set the first responder
        if let cell = editDescriptionTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditReviewCell{
            cell.editReviewTextView.becomeFirstResponder()
        }
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickTransparentView))
        transparentView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: Popup the Edit Review table
    @objc func editReview(){
        editReviewTableView.reloadData()
        
        FoodzLayout.popupTable(viewController: self,
                               transparentView: editReviewTransparentView,
                               tableView: editReviewTableView)
        
        // Set the first responder
        if let cell = editReviewTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditReviewCell{
            cell.editReviewTextView.becomeFirstResponder()
        }
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickEditReviewTransparentView))
        editReviewTransparentView.addGestureRecognizer(tapGesture)
    }
    
}

// MARK: Add new resto

extension ThisRanking: MyRanksMapSearchViewDelegate{
    //
    func restaurantChosenFromMap(someMapItem: MKMapItem) {
        let tmpResto = Resto(name: someMapItem.placemark.name!, city: currentCity.key)
        // Verify if the resto exists in the ranking
        if (thisRanking.filter {$0.key == tmpResto.key}).count > 0{
           showAlertDuplicateRestorant()
        }else{
            SomeApp.addRestoToRanking(userId: user.uid, resto: tmpResto, mapItem: someMapItem, forFood: currentFood, foodId: currentFood.key, city: currentCity)
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
extension ThisRanking{
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


///////////////////////
// Drag & Drop stuff
//////////////////////

// MARK: Extension for Drag
extension ThisRanking: UITableViewDragDelegate{
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if tableView == editRankTableView{
            session.localContext = editRankTableView
            return dragItems(at: indexPath)
        }else{
            return []
        }
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        // Only allow dragging of the section with the names
        if let restoNameToDrag = (editRankTableView.cellForRow(at: indexPath) as? EditableRestoCell)?.restoLabel.attributedText{
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: restoNameToDrag))
            dragItem.localObject = restoNameToDrag
            return[dragItem]
        }else{
            return []
        }
    }
}

// MARK: Drop stuff
extension ThisRanking : UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
     func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // Only for the editable Table view, and for section 0
        if tableView == editRankTableView,
            let indexPath = destinationIndexPath, indexPath.section == 0{
            
            let isSelf = (session.localDragSession?.localContext as? UITableView) == editRankTableView
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
                editRankTableView.performBatchUpdates(
                    {
                        //Add to the operations list
                        self.operations.append(RankingOperation(operationType: .Update, restoIdentifier: self.thisEditableRanking[sourceIndexPath.row].key))
                        // Update the "model"
                        let tmpResto = thisEditableRanking[sourceIndexPath.row]
                        thisEditableRanking.remove(at: sourceIndexPath.row)
                        thisEditableRanking.insert(tmpResto, at: destinationIndexPath.row)
                        
                        // DO NOT RELOAD DATA HERE!!
                        // Delete row and then insert row instead
                        editRankTableView.deleteRows(at: [sourceIndexPath], with: UITableView.RowAnimation.left)
                        editRankTableView.insertRows(at: [destinationIndexPath], with: UITableView.RowAnimation.right)
                })
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
                // Now reload
                //editRankTableView.reloadData()
            }
        }
    }
}

// MARK: UITextView Delegate
extension ThisRanking:UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 250
    }
    
}

// MARK: Banner Ad Delegate
extension ThisRanking: GADBannerViewDelegate{
    // my funcs
    private func configureBannerAd(){
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = SomeApp.adBAnnerUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
    }
    
    // Delegate funcs
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(bannerView)
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
        
        //small animation
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
        
        // Default Ad
        FoodzLayout.defaultAd(adView: adView)
        
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}
