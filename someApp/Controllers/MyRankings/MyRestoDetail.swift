//
//  MyRestoDetail.swift
//  someApp
//
//  Created by Sergio Ortiz on 11.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class MyRestoDetail: UIViewController {
    private static let screenSize = UIScreen.main.bounds.size
    private var thisView = UIView()
    private var restoDetailTable = UITableView()
    
    // We get this var from the preceding ViewController 
    var currentResto: Resto!

    override func viewDidLoad() {
        super.viewDidLoad()
        restoDetailTable.delegate = self
        restoDetailTable.dataSource = self
        restoDetailTable.frame = CGRect(x: 0, y: 0, width: MyRestoDetail.screenSize.width, height: MyRestoDetail.screenSize.height)
        self.view.addSubview(restoDetailTable)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

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
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.textColor = .black
                cell.textLabel?.text = "Address"
                cell.detailTextLabel?.text = currentResto.address
                return cell
            }else if indexPath.row == 2 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.textColor = .black
                cell.textLabel?.text = "Phone"
                cell.detailTextLabel?.text = currentResto.phoneNumber
                return cell
            }else if indexPath.row == 3 {
                let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
                cell.textLabel?.textColor = .black
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
}
