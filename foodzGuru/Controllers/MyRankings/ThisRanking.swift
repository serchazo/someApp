//
//  MyRanksEditRankingViewController.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 25.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces
import GoogleMaps

class ThisRanking: UIViewController {
    // class variables
    private static let showRestoDetailSegue = "ShowResto"
    private static let showMyReviewSegue = "myReviewSegue"
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
    private var userMultiplier: Int = 10
    
    private var emptyListFlag = false
    private var isSenderGoogle = false
    
    private var userRankingDetailRef: DatabaseReference!
    private var userRankingsRef: DatabaseReference!
    private var userReviewsRef : DatabaseReference!
    private var restoDatabaseReference: DatabaseReference!
    private var restoPointsDatabaseReference: DatabaseReference!
    private var thisRanking: [Resto] = []
    private var thisEditableRanking: [Resto] = []
    private var thisRankingReviews: [(text: String, timestamp: Double)] = []
    private var thisRankingReviewsLiked: [Bool] = []
    private var thisRankingReviewsLikes: [Int] = []
    private var descriptionRowHeight = CGFloat(50.0)
    private var descriptionEditRankingRowHeight = CGFloat(70.0)
    
    //Handles
    private var userRankingHandle:UInt!
    private var userRankingDetailHandle:UInt!
    private var userLikedReviewsHandle:[(handle: UInt, dbPath: String)] = []
    private var userReviewsHandle:[(handle: UInt, dbPath: String)] = []
    private var userReviewsLikesNbHandle:[(handle: UInt, dbPath:String)] = []
    
    //For "Edit the ranking" swipe left
    private var editRankTransparentView = UIView()
    private var editRankTableView = UITableView()
    private var navBar = UINavigationBar()
    private var operations:[RankingOperation] = []
    private let editRankTitleCellId = "EditRankingTitleCell"
    private let editRankTitleCellXib = "EditRankingTitleCell"
    
    // Header outlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var rankingTitleLabel: UILabel!
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var editRankingBarButton: UIBarButtonItem!
    
    // Ad stuff
    private var bannerView: GADBannerView!
    
    // Google stuff
    private let autocompleteController = GMSAutocompleteViewController()
    private let locationManager = CLLocationManager()
    private var placesClient: GMSPlacesClient!
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myRankingTable: UITableView!{
        didSet{
            myRankingTable.dataSource = self
            myRankingTable.delegate = self
            // For avoiding drawing the extra lines
            myRankingTable.tableFooterView = UIView()
        }
    }
    
    ///
    // MARK: Edit table
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        thisEditableRanking = thisRanking
        editRankTableView.reloadData()
        
        FoodzLayout.popupTable(viewController: self,
        transparentView: editRankTransparentView,
        tableView: editRankTableView)
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickEditRankTransparentView))
        editRankTransparentView.addGestureRecognizer(tapGesture)
        
    }
    
    // MARK: timeline funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        userReviewsLikesNbHandle.removeAll()
        
        // Get the current user
        Auth.auth().addStateDidChangeListener {auth, user in
            guard let user = user else {return}
            self.user = user
            
            //Inside the closure (we need the user to proceed)
            var dbPath = ""
            var userId = ""
            // Verify if I'm asking for my data
            if self.calledUser == nil {
                userId = self.user.uid
                
                // I'm asking for my data
                self.setupMyTables()
            }else {
                userId = self.calledUser.key
            }
            // In both cases
            dbPath = userId + "/"+self.thisRankingId
            self.userRankingDetailRef = SomeApp.dbUserRankingDetails.child(dbPath)
            self.userRankingsRef = SomeApp.dbUserRankings.child(dbPath)
            self.userReviewsRef = SomeApp.dbUserReviews.child(dbPath)
            // Configure the header: Attention, need to do it after setting the DB vars
            self.configureHeader(userId: userId)
            self.updateTableFromDatabase()
        }
        
        // Configure the banner ad
        configureBannerAd()
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set vars
        let thisRankingIdwithoutFood = currentCity.country + "/" + currentCity.state + "/" + currentCity.key
        thisRankingId = currentCity.country + "/" + currentCity.state + "/" + currentCity.key+"/" + currentFood.key
        restoDatabaseReference = SomeApp.dbResto.child(thisRankingIdwithoutFood)
        restoPointsDatabaseReference = SomeApp.dbRestoPoints.child(thisRankingId)
        
        // Some setup
        myRankingTable.estimatedRowHeight = 100
        myRankingTable.rowHeight = UITableView.automaticDimension
        myRankingTable.separatorInset = .zero
        
        // Location stuff
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Remove handles
        DispatchQueue.global(qos: .utility).async{
            
            if self.userRankingHandle != nil{
                self.userRankingsRef.removeObserver(withHandle: self.userRankingHandle)
            }
            if self.userRankingDetailHandle != nil {
                self.userRankingDetailRef.removeObserver(withHandle: self.userRankingDetailHandle)
            }
            
            for (handle, dbPath) in self.userLikedReviewsHandle{
                SomeApp.dbUserReviewsLikes.child(dbPath).removeObserver(withHandle: handle)
            }
            for (handle,dbPath) in self.userReviewsHandle{
                self.userReviewsRef.child(dbPath).removeObserver(withHandle: handle)
            }
            for (handle,dbPath) in self.userReviewsLikesNbHandle{
                SomeApp.dbUserReviewsLikesNb.child(dbPath).removeObserver(withHandle: handle)
            }
        }
  
        // Remove banner view
        bannerView.delegate = nil 
    }
    
    //Dynamic header height.  Snippet from : https://useyourloaf.com/blog/variable-height-table-view-header/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = myRankingTable.tableHeaderView else {
            return
        }

        // The table view header is created with the frame size set in
        // the Storyboard. Calculate the new size and reset the header
        // view to trigger the layout.
        // Calculate the minimum height of the header view that allows
        // the text label to fit its preferred width.
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height

            // Need to set the header view property of the table view
            // to trigger the new layout. Be careful to only do this
            // once when the height changes or we get stuck in a layout loop.
            myRankingTable.tableHeaderView = headerView

            // Now that the table view header is sized correctly have
            // the table view redo its layout so that the cells are
            // correcly positioned for the new header size.
            // This only seems to be necessary on iOS 9.
            myRankingTable.layoutIfNeeded()
        }
    }
    
    
    // MARK: setup My tables
    private func setupMyTables(){
        // The editRankingTableView needs to be loaded only if it's my data
        editRankTableView.delegate = self
        editRankTableView.dataSource = self
        editRankTableView.dragDelegate = self
        editRankTableView.dragInteractionEnabled = true
        editRankTableView.dropDelegate = self
        editRankTableView.register(UINib(nibName: "EditableRestoCell", bundle: nil), forCellReuseIdentifier: ThisRanking.delRestoCell)
        editRankTableView.register(UINib(nibName: self.editRankTitleCellId, bundle: nil), forCellReuseIdentifier: self.editRankTitleCellXib)
        editRankTableView.estimatedRowHeight = 100
        editRankTableView.rowHeight = UITableView.automaticDimension
    }

    // MARK: myRanking Header
    private func configureHeader(userId: String){
        // Configure navbar
        //navigationItem.title = FoodzLayout.FoodzStrings.appName.localized()
        
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
            rankingTitleLabel.text = MyStrings.headerTitleMe.localized(arguments: currentFood.name,currentCity.name)
        }else{
            rankingTitleLabel.text = MyStrings.headerTitleUser.localized(arguments: calledUser.nickName,currentFood.name,currentCity.name)
        }
        
        // Points multiplier
        SomeApp.dbUserPointsMultiplier.child(userId).observeSingleEvent(of: .value, with: {snapshot in
            if let tmpValue = snapshot.value as? Int{
                self.userMultiplier = tmpValue
            }
        })
        
    }
    
    // MARK: update from database
    private func updateTableFromDatabase(){
        
        // I. Outer: get the Resto keys and Positions
        userRankingDetailHandle = self.userRankingDetailRef.observe(.value, with: {snapshot in
            // Clean first
            var tmpPositions = self.initializeStringArray(withElements: Int(snapshot.childrenCount))
            var tmpRanking = self.initializeArray(withElements: Int(snapshot.childrenCount))
            
            self.thisRankingReviewsLiked = self.initializeBoolArray(withElements: Int(snapshot.childrenCount))
            self.thisRankingReviewsLikes = self.initializeIntArray(withElements: Int(snapshot.childrenCount))
            self.thisRankingReviews = self.initializeReviewArray(withElements: Int(snapshot.childrenCount))
            var count = 0
            
            if !snapshot.exists(){
                // If we don't have a ranking, mark the empty list flag
                self.emptyListFlag = true
                self.myRankingTable.reloadData()
            }else{
                self.emptyListFlag = false
                // 1. Get the resto keys
                for child in snapshot.children{
                    if let testChild = child as? DataSnapshot,
                        let value = testChild.value as? [String:AnyObject],
                        var position = value["position"] as? Int {
                        let restoId = testChild.key
                        
                        // Garde-fous
                        if position >= snapshot.childrenCount{
                            position = Int(snapshot.childrenCount)
                        }
                        
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
                                self.myRankingTable.reloadData()
                                
                                // Then get the Reviews.  Update by row
                                self.getReviews()
                            }
                        })
                        
                    }
                }
            }
        })
    }
    
    // MARK: get reviews
    func getReviews(){
        // Setup first
        var currentUser = user.uid
        if calledUser != nil{
            currentUser = calledUser.key
        }
        // Then
        for i in 0 ..< thisRanking.count{
            let tmpRestoId = thisRanking[i].key
            let likedDBPath = currentUser + "/" + self.currentCity.country + "/" + self.currentCity.state + "/" + self.currentCity.key + "/" + self.currentFood.key + "/" + tmpRestoId + "/" + self.user.uid
            let reviewsLikeNb = currentUser + "/" + self.currentCity.country+"/"+self.currentCity.state + "/" + self.currentCity.key + "/" + self.currentFood.key + "/" + tmpRestoId + "/"
            
            userReviewsHandle.append((handle: userReviewsRef.child(tmpRestoId).observe(.value, with:{ reviewSnap in
                if reviewSnap.exists(),
                    let reviewValue = reviewSnap.value as? [String: AnyObject],
                    let reviewText = reviewValue["text"] as? String,
                    let timestamp = reviewValue["timestamp"] as? Double{
                    self.thisRankingReviews[i] = (text: reviewText, timestamp: timestamp)
                }
                    
                else{
                    self.thisRankingReviews[i] = (text: "", timestamp: 0.0)
                }
                
                // 3. Get if liked
                self.userLikedReviewsHandle.append((
                    handle: SomeApp.dbUserReviewsLikes.child(likedDBPath).observe( .value, with: {likeSnap in
                    self.thisRankingReviewsLiked[i] = likeSnap.exists()
                    
                    //4. Get nb of likes
                    self.userReviewsLikesNbHandle.append((handle:  SomeApp.dbUserReviewsLikesNb.child(reviewsLikeNb).observe(.value, with: {likesNbSnap in
                        
                        if likesNbSnap.exists(),
                            let nbLikes = likesNbSnap.value as? Int{
                            self.thisRankingReviewsLikes[i] = nbLikes
                        }else{
                            self.thisRankingReviewsLikes[i] = 0
                        }
                        // Update per row
                        self.myRankingTable.reloadRows(
                            at: [IndexPath(row: i, section: 0)],
                            with: .none)
                    }),dbPath:reviewsLikeNb))
                    // [End] 4.
                    }), dbPath:likedDBPath))
                // [End] 3.
            }), dbPath: tmpRestoId))
            
        }
        
    }
    
    // MARK: Initialize Arrays
    func initializeArray(withElements: Int) -> [Resto] {
        var tmpRestoList: [Resto] = []
        for _ in 0..<withElements {
            tmpRestoList.append(Resto(key: "0", name: "placeholder"))
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
    
    func initializeIntArray(withElements: Int) -> [Int]{
        var tmpArray: [Int] = []
        for _ in 0..<withElements {
            tmpArray.append(0)
        }
        return tmpArray
    }
    
    func initializeBoolArray(withElements: Int) -> [Bool]{
        var tmpArray: [Bool] = []
        for _ in 0..<withElements {
            tmpArray.append(false)
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
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            switch identifier{
            case ThisRanking.showRestoDetailSegue:
                if !isSenderGoogle,
                    let cell = sender as? ThisRankingCell,
                    let indexPath = myRankingTable.indexPath(for: cell),
                    let seguedToResto = segue.destination as? MyRestoDetail{
                    seguedToResto.currentResto = thisRanking[indexPath.row]
                    seguedToResto.currentCity = currentCity
                    seguedToResto.currentFood = currentFood
                    if calledUser == nil {
                        seguedToResto.seguer = MyRestoDetail.MyRestoSeguer.ThisRankingMy
                    }else{
                        seguedToResto.seguer = MyRestoDetail.MyRestoSeguer.ThisRankingVisitor
                    }
                }
                // If the sender is the Google Search Menu
                if isSenderGoogle,
                    let resto = sender as? Resto,
                    let seguedToResto = segue.destination as? MyRestoDetail{
                    // Clean up
                    isSenderGoogle = false
                    // Prepare
                    seguedToResto.currentResto = resto
                    seguedToResto.currentCity = currentCity
                    seguedToResto.currentFood = currentFood
                }
            case ThisRanking.showMyReviewSegue:
                if let cell = sender as? ThisRankingCell,
                let indexPath = myRankingTable.indexPath(for: cell),
                let seguedToReview = segue.destination as? MyReview{
                    seguedToReview.currentResto = thisRanking[indexPath.row]
                    seguedToReview.currentCity = currentCity
                    seguedToReview.currentFood = currentFood
                }
            default: break
            }
        }
    }
}

// MARK: Table stuff
extension ThisRanking: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Editable TableView
        if tableView == self.editRankTableView{
            return 2
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
        // test if the table is the EditDescription pop-up
        if tableView == self.editRankTableView{
            if section == 0{
                return 1
            }
            else if section == 1 {
                return thisEditableRanking.count
            }
            else{
                return 0
            }
        }else{
            // The normal table
            switch(section){
            case 0:
                if emptyListFlag == true{
                    return 1
                }else{
                    return thisRanking.count
                }
            case 1: return 1
            default: return 0
            }
        }
    }
    
    // Cell for Row at
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // [START] The Editable Ranking Table
        if tableView == self.editRankTableView{
            
            if indexPath.section == 0,
                let titleCell = editRankTableView.dequeueReusableCell(withIdentifier: self.editRankTitleCellId, for: indexPath) as? EditRankingTitleCell{
                
                titleCell.titleLabel.textColor = SomeApp.themeColor
                titleCell.doneButton.setTitleColor(SomeApp.themeColor, for: .normal)
                titleCell.cancelButton.setTitleColor(SomeApp.themeColor, for: .normal)
                titleCell.cancelAction = {(cell) in
                    self.onClickEditRankTransparentView()
                }
                titleCell.doneAction = {(cell) in
                    self.performUpdate()
                }
                titleCell.selectionStyle = .none
                
                return titleCell
                
            }
            // Editable Cells
            else if let editRestoCell = editRankTableView.dequeueReusableCell(withIdentifier: ThisRanking.delRestoCell, for: indexPath) as? EditableRestoCell{
                // Text
                editRestoCell.restoLabel.text = thisEditableRanking[indexPath.row].name
                
                editRestoCell.tapAction = { (cell) in
                    // If the delete button is pressed, we show an alert asking for confirmation
                    let alert = UIAlertController(title: MyStrings.buttonDeleteAsk.localized(),
                                                  message: "",
                                                  preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                                                     style: .cancel)
                    
                    let delAction = UIAlertAction(title: MyStrings.buttonDeleteTitle.localized(), style: .destructive){ _ in
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
            // [END] The Editable Ranking Table
        }
        // [START] The "normal" table
        else{
            if indexPath.section == 0 {
                // [START] Spinner while downloading
                guard thisRanking.count > 0 || emptyListFlag else{
                    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                    cell.textLabel?.text = FoodzLayout.FoodzStrings.loading.localized()
                    let spinner = UIActivityIndicatorView(style: .medium)
                    spinner.startAnimating()
                    cell.accessoryView = spinner
                    return cell
                } // [END] Spinner while downloading
                
                // [START] Empty list
                if emptyListFlag && calledUser == nil{
                    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                    cell.textLabel?.text = MyStrings.emptyTitleMe.localized(arguments: currentFood.name)
                    cell.detailTextLabel?.text = MyStrings.emptyMsgMe.localized()
                    return cell
                }else if emptyListFlag && calledUser != nil{
                    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                    cell.textLabel?.text = MyStrings.emptyTitleUser.localized(arguments: currentFood.name, calledUser.nickName)
                    cell.detailTextLabel?.text = MyStrings.emptyMsgUser.localized()
                    return cell
                }// [END] Empty list
                
                // [START] Restaurant cells
                else if let cell = tableView.dequeueReusableCell(withIdentifier: "EditRankingCell", for: indexPath) as? ThisRankingCell {
                    // Position label
                    let position = indexPath.row + 1
                    
                    // Name
                    let placeNameText = String(position) + ". " + thisRanking[indexPath.row].name
                    cell.placeName.setTitle(placeNameText, for: .normal)
                    
                    // Points
                    var positionMultiple = 10 - indexPath.row
                    // Correct for the positions higher than 10
                    if (positionMultiple < 0) {positionMultiple = 1}
                    //write points
                    let pointsToAdd = ceil(Double(userMultiplier * positionMultiple) * 0.1);
                    cell.pointsGivenLabel.text = MyStrings.pointsGiven.localized(arguments: Int(pointsToAdd))
                    
                    // Review text
                    if !(thisRankingReviews.count > 0) {
                        cell.reviewLabel.text = " " // the space is important
                        let spinner = UIActivityIndicatorView(style: .medium)
                        spinner.startAnimating()
                        cell.reviewLabel.addSubview(spinner)
                    }else{ // We already downloaded the reviews
                        cell.reviewLabel.text = thisRankingReviews[indexPath.row].text
                    }
                    
                    // Show details Action
                    cell.showRestoDetailAction = {(cell) in
                        self.performSegue(withIdentifier: ThisRanking.showRestoDetailSegue, sender: cell)
                    }
                    
                    // [Below part]
                    
                    // Stack View border: only invisible in one option
                    cell.borderStack.layer.borderColor = UIColor.systemGray.cgColor
                    cell.borderStack.layer.borderWidth = 0.8
                    cell.borderStack.layer.cornerRadius = 10
                    cell.borderStack.layer.masksToBounds = true
                    
                    //
                    var currentUser = user.uid
                    if calledUser != nil {currentUser = calledUser.key}
                    
                    // show the border stack
                    cell.borderStack.isHidden = false
                    
                    // [START] Like button
                    cell.likeButton.setTitle(MyStrings.buttonYum.localized(), for: .normal)
                    cell.likeButton.isHidden = false
                    cell.likeButton.isEnabled = true
                    
                    // Action and color depending if the comment is liked
                    if thisRankingReviewsLiked[indexPath.row] {
                        cell.likeButton.setTitleColor(SomeApp.selectionColor, for: .normal)
                        cell.likeButton.setTitle(MyStrings.buttonYummed.localized(), for: .normal)
                        cell.likeAction = {(cell) in
                            let tmpIndexPath = self.myRankingTable.indexPath(for: cell)
                            SomeApp.dislikeReview(userid: self.user.uid,
                                                  resto: self.thisRanking[tmpIndexPath!.row],
                                                  city: self.currentCity,
                                                  foodId: self.currentFood.key,
                                                  reviewerId: currentUser)
                        }
                    }
                        // If it's not yet liked
                    else{
                        cell.likeButton.setTitleColor(SomeApp.themeColor, for: .normal)
                        cell.likeAction = {(cell) in
                            let tmpIndexPath = self.myRankingTable.indexPath(for: cell)
                            SomeApp.likeReview(userid: self.user.uid,
                                               resto: self.thisRanking[tmpIndexPath!.row],
                                               city: self.currentCity,
                                               foodId: self.currentFood.key,
                                               reviewerId: currentUser)
                        }
                    }
                    // [END] Like button
                    
                    // [START] Nb yums
                    cell.nbLikesButton.setTitleColor(.systemGray, for: .normal)
                    cell.nbLikesButton.setTitle(MyStrings.buttonYumNb.localized(arguments: thisRankingReviewsLikes[indexPath.row]), for: .normal)
                    cell.nbLikesButton.isEnabled = false
                    // [END] Nb yums button when there is a comment
                    
                    // [START] Edit Review / Report button
                    if calledUser == nil {
                        
                        // Edit Review part
                        cell.editReviewButton.setTitleColor(SomeApp.themeColor, for: .normal)
                        cell.editReviewButton.setTitle(MyStrings.buttonEditReview.localized(), for: .normal)
                        cell.editReviewButton.isHidden = false
                        cell.editReviewButton.isEnabled = true
                        cell.editReviewAction = {(cell) in
                            self.performSegue(withIdentifier: ThisRanking.showMyReviewSegue, sender: cell)
                        }
                    }
                        // Visiting: report
                    else{
                        setupReportMenu(cell: cell)
                    }
                    // [END] Edit Review / Report button
                    
                      return cell
                }else{
                    fatalError("Can't return restaurant cell")
                }
             }
            // [END] Restaurant cells
            // [] The last cell : Add resto to ranking
            else if indexPath.section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddRestoToRankingCell", for: indexPath)
                cell.textLabel?.text = MyStrings.cellAddResto.localized(arguments: currentFood.name)
                return cell
            }else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                return cell
            }
        }//[END] The "normal" table
    }
    
    // MARK: Actions
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // [START] If press on Add ranking cell, then we go to google
        if tableView == myRankingTable && indexPath.section == 1{
            //Assign the parent view controller as the delegate property.
            autocompleteController.delegate = self
            autocompleteController.autocompleteBoundsMode = .restrict
            
            // Specify the place data types to return.
            let nameRawValue = UInt(GMSPlaceField.name.rawValue)
            //let formattedAddressRawValue = UInt(GMSPlaceField.formattedAddress.rawValue)
            //let phoneRawValue = UInt(GMSPlaceField.phoneNumber.rawValue)
            //let webRawValue = UInt(GMSPlaceField.website.rawValue)
            let placeIDRawValue = UInt(GMSPlaceField.placeID.rawValue)
            
            let rawValueExpression:UInt = nameRawValue | placeIDRawValue
            
            let fields: GMSPlaceField = GMSPlaceField(rawValue:rawValueExpression)!
            
            autocompleteController.placeFields = fields
            
            //Add a GMSAutocompleteFilter to constrain the query to a particular type of place.
            let filter = GMSAutocompleteFilter()
            filter.type = .establishment
            autocompleteController.autocompleteFilter = filter
            
            // Display the autocomplete view controller.
            present(autocompleteController, animated: true, completion: nil)
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
    
    // MARK: report menu
    private func setupReportMenu(cell:ThisRankingCell){
        // The Edit review button becomes a "report" button
        cell.editReviewButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
        cell.editReviewButton.setTitleColor(.darkGray, for: .normal)
        cell.editReviewButton.setTitle("...", for: .normal)
        cell.editReviewButton.isHidden = false
        cell.editReviewButton.isEnabled = true
        cell.editReviewAction = {(cell) in
            let tmpIndexPath = self.myRankingTable.indexPath(for: cell)
            let moreAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let reportAction = UIAlertAction(
                title: MyStrings.reportTitle.localized(),
                style: .destructive,
                handler: {_ in
                    // [START] Inner Alert
                    let innerAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    let inappropriateAction = UIAlertAction(
                        title: MyStrings.reportInappropriate.localized(),
                        style: .destructive,
                        handler: {_ in
                            SomeApp.reportReview(
                                userid: self.calledUser.key,
                                resto: self.thisRanking[tmpIndexPath!.row],
                                city: self.currentCity,
                                foodId: self.currentFood.key,
                                text: self.thisRankingReviews[tmpIndexPath!.row].text,
                                reportReason: "Inappropriate",
                                postTimestamp: self.thisRankingReviews[tmpIndexPath!.row].timestamp,
                                reporterId: self.user.uid)
                            self.navigationController?.popViewController(animated: true)
                })
                
                    let spamAction = UIAlertAction(
                        title: MyStrings.reportSpam.localized(),
                        style: .destructive,
                        handler: {_ in
                            SomeApp.reportReview(
                                userid: self.calledUser.key,
                                resto: self.thisRanking[tmpIndexPath!.row],
                                city: self.currentCity,
                                foodId: self.currentFood.key,
                                text: self.thisRankingReviews[tmpIndexPath!.row].text,
                                reportReason: "Spam",
                                postTimestamp: self.thisRankingReviews[tmpIndexPath!.row].timestamp,
                                reporterId: self.user.uid)
                            
                            self.navigationController?.popViewController(animated: true)
                    })
                let cancelAction = UIAlertAction(
                    title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                    style: .cancel, handler: nil)
                innerAlert.addAction(inappropriateAction)
                innerAlert.addAction(spamAction)
                innerAlert.addAction(cancelAction)
                self.present(innerAlert,animated: true)
                // [END] Inner alert
            })
            let cancelAction = UIAlertAction(
                title: FoodzLayout.FoodzStrings.buttonCancel.localized(),
                style: .cancel, handler: nil)
            
            moreAlert.addAction(reportAction)
            moreAlert.addAction(cancelAction)
            self.present(moreAlert,animated: true)
        }
    }
}


// MARK: objc funcs

extension ThisRanking{
    // Perform the update
    @objc func performUpdate(){
        if operations.count > 0{
            let delOperations = operations.filter({$0.operationType == .Delete})
            delOperations.forEach({SomeApp.deleteRestoFromRanking(userId: user.uid, city: currentCity, foodId: currentFood.key, restoId: $0.restoIdentifier) })
            
            // Update the ranking
            SomeApp.updateRanking(userId: user.uid, city: currentCity, foodId: currentFood.key, ranking: thisEditableRanking)
        }
        // Clean the vars
        thisRanking.removeAll()
        thisEditableRanking.removeAll()
        thisRankingReviews.removeAll()
        thisRankingReviewsLiked.removeAll()
        thisRankingReviewsLikes.removeAll()
        
        //Update view
        onClickEditRankTransparentView()
    }
    
    //Disappear!
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
                        self.editRankTableView.frame = CGRect(
                            x: 0,
                            y: ThisRanking.screenSize.height,
                            width: ThisRanking.screenSize.width,
                            height: ThisRanking.screenSize.height * 0.9 - navBarHeight)
                        //self.editTextField.resignFirstResponder()
        },
                       completion: nil)
    }
   
}

// MARK: Extension for Drag
extension ThisRanking: UITableViewDragDelegate{
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if tableView == editRankTableView, indexPath.section == 1{
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
            let indexPath = destinationIndexPath, indexPath.section == 1{
            
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
            }
        }
        // [END] Coordinator: Now reload
        //editRankTableView.reloadData()
    }
}


// MARK: - CLLocationManagerDelegate
extension ThisRanking: CLLocationManagerDelegate{
    
    // When we get the location we update the AutoComplete
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        let lat = location.coordinate.latitude
        let long = location.coordinate.longitude
        
        let offset = 200.0 / 1000.0;
        let latMax = lat + offset;
        let latMin = lat - offset;
        
        let lngOffset = offset * cos(lat * .pi / 200.0);
        let lngMax = long + lngOffset;
        let lngMin = long - lngOffset;
        
        let initialLocation = CLLocationCoordinate2D(latitude: latMax, longitude: lngMax)
        let otherLocation = CLLocationCoordinate2D(latitude: latMin, longitude: lngMin)
        let bounds = GMSCoordinateBounds(coordinate: initialLocation, coordinate: otherLocation)
        
        autocompleteController.autocompleteBounds = bounds
    }
}

// MARK: GMSAutocompleteViewControllerDelegate stuff
extension ThisRanking: GMSAutocompleteViewControllerDelegate{
    // Handle the user's selection.
    // This one will pass the result to the resto creator
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        let restoId = place.placeID ?? ""
        let restoName = place.name ?? ""
        let tmpResto = Resto(key: restoId, name: restoName)
        
        self.isSenderGoogle = true
        
        self.performSegue(withIdentifier: ThisRanking.showRestoDetailSegue , sender: tmpResto)
        
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("An error occurred \(error.localizedDescription)")
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Helper functions for adding a resto
    func showAlertDuplicateRestorant(){
        let alert = UIAlertController(
            title: MyStrings.duplicateTitle.localized(),
            message: MyStrings.duplicateMsg.localized(),
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: FoodzLayout.FoodzStrings.buttonOK.localized(),
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
    
    // Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        //print("adViewDidReceiveAd")
        FoodzLayout.removeDefaultAd(adView: adView)
        
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
    
    // Tells the delegate that a full-screen view will be presented in response
    // to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        //print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        //print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        //print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        //print("adViewWillLeaveApplication")
    }
}

// MARK: Localized Strings
extension ThisRanking{
    private enum MyStrings {
        case headerTitleMe
        case headerTitleUser
        case descriptionTitle
        case buttonDeleteAsk
        case buttonDeleteTitle
        case emptyTitleMe
        case emptyTitleUser
        case emptyMsgMe
        case emptyMsgUser
        case pointsGiven
        case buttonYum
        case buttonYummed
        case buttonYumNb
        case buttonEditReview
        case cellAddResto
        case descriptionEditTitle
        case descriptionEditWarning
        case descriptionEditPlaceholder
        case descriptionEditDone
        case reviewEditTitle
        case reviewEditWarning
        case reviewEditPlaceholder
        case reviewEditDone
        case reportTitle
        case reportInappropriate
        case reportSpam
        case duplicateTitle
        case duplicateMsg
    
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .headerTitleMe:
                return String(
                    format: NSLocalizedString("THISRANKING_HEADER_TITLE_ME", comment: "Favorite"),
                    locale: .current,
                    arguments: arguments)
            case .headerTitleUser:
                return String(
                    format: NSLocalizedString("THISRANKING_HEADER_TITLE_USER", comment: "Favorite"),
                    locale: .current,
                    arguments: arguments)
            case .descriptionTitle:
                return String(
                    format: NSLocalizedString("THISRANKING_DESCRIPTION_TITLE", comment: "To describe"),
                    locale: .current,
                    arguments: arguments)
            case .buttonDeleteAsk:
                return String(
                    format: NSLocalizedString("THISRANKING_BUTTON_DELETE_ASK", comment: "To delete"),
                    locale: .current,
                    arguments: arguments)
            case .buttonDeleteTitle:
                return String(
                    format: NSLocalizedString("THISRANKING_BUTTON_DELETE_TITLE", comment: "To delete"),
                    locale: .current,
                    arguments: arguments)
            case .emptyTitleMe:
                return String(
                    format: NSLocalizedString("THISRANKING_EMPTY_TITLE_ME", comment: "Empty"),
                    locale: .current,
                    arguments: arguments)
            case .emptyTitleUser:
                return String(
                    format: NSLocalizedString("THISRANKING_EMPTY_TITLE_USER", comment: "Empty"),
                    locale: .current,
                    arguments: arguments)
            case .emptyMsgMe:
                return String(
                    format: NSLocalizedString("THISRANKING_EMPTY_MSG_ME", comment: "Empty"),
                    locale: .current,
                    arguments: arguments)
            case .emptyMsgUser:
                return String(
                    format: NSLocalizedString("THISRANKING_EMPTY_MSG_USER", comment: "Empty"),
                    locale: .current,
                    arguments: arguments)
            case .pointsGiven:
            return String(
                format: NSLocalizedString("THISRANKING_POINTS_GIVEN", comment: "Points"),
                locale: .current,
                arguments: arguments)
            case .buttonYum:
                return String(
                format: NSLocalizedString("THISRANKING_BUTTON_YUM", comment: "yum"),
                locale: .current,
                arguments: arguments)
            case .buttonYummed:
                return String(
                format: NSLocalizedString("THISRANKING_BUTTON_YUMMED", comment: "yum"),
                locale: .current,
                arguments: arguments)
            case .buttonYumNb:
                return String(
                format: NSLocalizedString("THISRANKING_BUTTON_YUMNB", comment: "yum"),
                locale: .current,
                arguments: arguments)
            case .buttonEditReview:
                return String(
                    format: NSLocalizedString("THISRANKING_BUTTON_EDITREVIEW", comment: "Edit"),
                    locale: .current,
                    arguments: arguments)
            case .cellAddResto:
            return String(
                format: NSLocalizedString("THISRANKING_CELL_ADDRESTO", comment: "Add place"),
                locale: .current,
                arguments: arguments)
            case .descriptionEditTitle:
            return String(
                format: NSLocalizedString("THISRANKING_DESCRIPTION_EDIT_TITLE", comment: "Write your description"),
                locale: .current,
                arguments: arguments)
            case .descriptionEditWarning:
            return String(
                format: NSLocalizedString("THISRANKING_DESCRIPTION_EDIT_WARNING", comment: "Max characters"),
                locale: .current,
                arguments: arguments)
            case .descriptionEditPlaceholder:
            return String(
                format: NSLocalizedString("THISRANKING_DESCRIPTION_EDIT_INSTRUCTIONS", comment: "Write your description"),
                locale: .current,
                arguments: arguments)
            case .descriptionEditDone:
            return String(
                format: NSLocalizedString("THISRANKING_DESCRIPTION_EDIT_BUTTON_DONE", comment: "OK"),
                locale: .current,
                arguments: arguments)
            case .reviewEditTitle:
                return String(
                    format: NSLocalizedString("THISRANKING_REVIEW_EDIT_TITLE", comment: "Review"),
                    locale: .current,
                    arguments: arguments)
            case .reviewEditWarning:
                return String(
                    format: NSLocalizedString("THISRANKING_REVIEW_EDIT_WARNING", comment: "Write something"),
                    locale: .current,
                    arguments: arguments)
            case .reviewEditPlaceholder:
                return String(
                    format: NSLocalizedString("THISRANKING_REVIEW_EDIT_INSTRUCTIONS", comment: "Write here"),
                    locale: .current,
                    arguments: arguments)
            case .reviewEditDone:
                return String(
                    format: NSLocalizedString("THISRANKING_REVIEW_EDIT_BUTTON_DONE", comment: "OK"),
                    locale: .current,
                    arguments: arguments)
            case .reportTitle:
                return String(
                    format: NSLocalizedString("THISRANKING_REPORT_TITLE", comment: "To report"),
                    locale: .current,
                    arguments: arguments)
            case .reportInappropriate:
                return String(
                    format: NSLocalizedString("THISRANKING_REPORT_REASON_INAPPROPRIATE", comment: "Inappropriate"),
                    locale: .current,
                    arguments: arguments)
            case .reportSpam:
                return String(
                    format: NSLocalizedString("THISRANKING_REPORT_REASON_SPAM", comment: "Spam"),
                    locale: .current,
                    arguments: arguments)
            case .duplicateTitle:
            return String(
                format: NSLocalizedString("THISRANKING_DUPLICATE_TITLE", comment: "Duplicate"),
                locale: .current,
                arguments: arguments)
            case .duplicateMsg:
            return String(
                format: NSLocalizedString("THISRANKING_DUPLICATE_MSG", comment: "Already here"),
                locale: .current,
                arguments: arguments)
            }
        }
    }
}
