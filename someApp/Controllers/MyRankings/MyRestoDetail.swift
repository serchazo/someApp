//
//  MyRestoDetail.swift
//  someApp
//
//  Created by Sergio Ortiz on 11.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import SafariServices
import MapKit
import Firebase

class MyRestoDetail: UIViewController {
    private static let screenSize = UIScreen.main.bounds.size
    private static let segueToMap = "showMap"
    
    // We get this var from the preceding ViewController 
    var currentResto: Resto!
    var dbMapReference: DatabaseReference!
    
    // Variable to pass to map Segue
    var currentRestoMapItem : MKMapItem!
    var OKtoPerformSegue = true

    @IBOutlet weak var restoDetailTable: UITableView!{
        didSet{
            restoDetailTable.delegate = self
            restoDetailTable.dataSource = self
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbMapReference = SomeApp.dbRestoAddress.child(currentResto.key)
        
        // Get the map from the database
        self.dbMapReference.observeSingleEvent(of: .value, with: {snapshot in
            if let value = snapshot.value as? [String: String],
                let mapString = value["address"]{
                
                let decoder = JSONDecoder()
                do{
                    let tempMapArray = try decoder.decode(RestoMapArray.self, from: mapString.data(using: String.Encoding.utf8)!)
                    self.currentRestoMapItem = tempMapArray.restoMapItem
                }catch{
                    self.OKtoPerformSegue = false
                    print(error.localizedDescription)
                }
                
            }else{
                self.OKtoPerformSegue = false
            }
        })
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch(segue.identifier){
        case MyRestoDetail.segueToMap:
            if let seguedVC = segue.destination as? MyRestoMap{
                seguedVC.mapItems = [currentRestoMapItem]
            }
        default:break
        }
    }
    
    //
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return OKtoPerformSegue
    }
}

//

extension MyRestoDetail : UITableViewDataSource, UITableViewDelegate{
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
                cell.textLabel?.text = currentResto.name
                return cell
            }else if indexPath.row == 1{
                let cell = restoDetailTable.dequeueReusableCell(withIdentifier: "AddressCell")
                //let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell!.textLabel?.textColor = .black
                cell!.textLabel?.text = "Address"
                cell!.detailTextLabel?.text = currentResto.address
                return cell!
            }else if indexPath.row == 2 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.textColor = .black
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Phone"
                cell.detailTextLabel?.text = currentResto.phoneNumber
                return cell
            }else if indexPath.row == 3 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.textColor = .black
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "URL"
                if currentResto.url != nil{
                    cell.detailTextLabel?.text = currentResto.url!.absoluteString
                }else{
                    cell.detailTextLabel?.text = ""
                }
                return cell
            }else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Add Comment"
                return cell
            }
        }else{
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Test"
            return cell
        }
    }
    
    // Actions
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0{
            if indexPath.row == 2{
                let tmpModifiedPhone = "tel://" + currentResto.phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                if let number = URL(string: tmpModifiedPhone){
                    UIApplication.shared.open(number)
                }else{
                    // Can't call
                    let alert = UIAlertController(
                        title: "Can't call",
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
                    
                }
            }else if indexPath.row == 3{
                // URL clicket, open the web page
                if currentResto.url != nil{
                    let config = SFSafariViewController.Configuration()
                    config.entersReaderIfAvailable = true
                    let vc = SFSafariViewController(url: currentResto.url, configuration: config)
                    vc.preferredControlTintColor = UIColor.white
                    vc.preferredBarTintColor = SomeApp.themeColorOpaque
                    present(vc, animated: true)
                }
            }
        }
    }
}
