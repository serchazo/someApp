//
//  FoodType.swift
//  someApp
//
//  Created by Sergio Ortiz on 05.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase

class FoodType{
    let ref: DatabaseReference?
    let key: String
    let name: String
    let geography: String
    let icon: String
    
    
    init(geography: String, icon: String, name: String, key: String = "") {
        self.ref = nil
        self.key = key
        self.geography = geography
        self.icon = icon
        self.name = name
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let name = value["name"] as? String,
            let geography = value["geography"] as? String,
            let icon = value["icon"] as? String else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.name = name
        self.geography = geography
        self.icon = icon
    }
    
    // Turn GroceryItem to a Dictionary
    func toAnyObject() -> Any {
        return[
            "geography" : geography,
            "name" : name,
            "icon" : icon]
    }
    
    
}
