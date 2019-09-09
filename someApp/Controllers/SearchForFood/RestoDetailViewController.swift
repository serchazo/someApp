//
//  RestoDetailViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import SafariServices
import Firebase
import MapKit

class RestoDetailViewController: UIViewController {
    var currentResto: Resto!
    var dbAddressReference: DatabaseReference!
    var mapItem: MKMapItem!
    
    @IBOutlet weak var restoDetailTable: UITableView!{
        didSet{
            restoDetailTable.delegate = self
            restoDetailTable.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dbAddressReference = basicModel.dbRestoAddress.child(currentResto.key)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect the row when segued pops
        if let indexPath = restoDetailTable.indexPathForSelectedRow {
            restoDetailTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Get the map from the database
        self.dbAddressReference.observeSingleEvent(of: .value, with: {snapshot in
            let value = snapshot.value as? [String: AnyObject]
            //let tmpMapItem:MKMapItem = RestoMapArray(from: address!).restoMapItem
            //let str = String(decoding: encoded, as: UTF8.self)

            
        })
        
        return false 
        
        /*
        switch(identifier){
        case "showMapDetail":
            if currentResto.mapItems.count > 0{
                return true
            }else{
                // No map information: generate an alert
                let alert = UIAlertController(
                    title: "No map information available",
                    message: "Please try another restaurant.",
                    preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: {
                        (action: UIAlertAction)->Void in
                        //do nothing
                }))
                present(alert, animated: false, completion: nil)
                
                //
                return false
            }
        default: return false
        }
 */
    }
    
    /*
    //Prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch(segue.identifier){
        case "showMapDetail":
            if currentResto.mapItems.count > 0, let seguedMapMVC = segue.destination as? RestoDetailMapVC{
                seguedMapMVC.mapItems = currentResto.mapItems
            }
        default:break
        }
    }*/
}

extension RestoDetailViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section){
        case 0: return 5
        case 1: return 0 //currentResto.comments.count // number of comments
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Call the restaurant
        if indexPath.section == 0 && indexPath.row == 2{
            let tmpModifiedPhone = String(currentResto.phoneNumber.filter { !" \n\t\r".contains($0) })
            guard let number = URL(string: "tel://" + tmpModifiedPhone) else { return }
            UIApplication.shared.open(number)
        }
        //Go to URL
        else if indexPath.section == 0 && indexPath.row == 3 {
            if currentResto.url != nil{
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                let vc = SFSafariViewController(url: currentResto.url, configuration: config)
                present(vc, animated: true)
            }
        }
    }
    

    //
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RestoNameCell", for: indexPath)
                cell.textLabel!.text = currentResto.name
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RestoAddressCell", for: indexPath)
                cell.textLabel!.text = "Address: "
                cell.detailTextLabel!.text = currentResto!.address
                return cell
            }else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RestoPhoneCell", for: indexPath)
                cell.textLabel!.text = "Phone: "
                cell.detailTextLabel!.text = currentResto.phoneNumber
                return cell
            }else if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RestoURLCell", for: indexPath)
                cell.textLabel!.text = "URL: "
                cell.detailTextLabel!.text = currentResto.url.absoluteString
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsTitleCell", for: indexPath)
                cell.textLabel!.text = "Comments"
                return cell
            }
        }else{
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsCell", for: indexPath) as? RestoDetailCommentCell{
                //cell.comment = "TODO: comment" //currentResto!.comments[indexPath.row]
                cell.dateLabel.text = "1 Jan 1979"
                cell.userLable.text = "some user"
                cell.commentLabel.text = "This resto is terrific!"
                
                return cell
            }else{
                fatalError("No comment cell possible")
            }
            
        }
    }
}

// MARK: Some view stuff
extension RestoDetailViewController{
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
        if indexPath.section == 0{
            return CGFloat(44)
        }else if indexPath.section == 1{
            let cellHeight = restorantNameFont.lineHeight + restorantAddressFont.lineHeight + 145.0
            return CGFloat(cellHeight)
        }else{
            return CGFloat(0)
        }
    }
}
