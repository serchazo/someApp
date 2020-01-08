//
//  Ranking.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 06.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase

class Ranking{
    let ref: DatabaseReference?
    let key: String
    let name: String
    let icon: String
    
    init(foodKey: String, name: String, icon:String = "🍴"){
        self.ref = nil
        self.key = foodKey.lowercased()
        self.name = name
        self.icon = icon
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let name = value["name"] as? String else{
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.name = name
        
        if let icon = value["icon"] as? String {self.icon = icon} else {self.icon = "🍴"}
    }
    
    // Turn Ranking to a Dictionary
    func toAnyObject() -> Any {
        return[
            "icon" : icon,
            "name" : name ]
    }
}
