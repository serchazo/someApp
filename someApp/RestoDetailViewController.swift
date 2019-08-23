//
//  RestoDetailViewController.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class RestoDetailViewController: UIViewController {
    
    var titleCell: String = "Some title"

    @IBOutlet weak var restoTitle: UILabel!
    @IBOutlet weak var restoLongDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoTitle?.text = titleCell
        // Do any additional setup after loading the view.
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
