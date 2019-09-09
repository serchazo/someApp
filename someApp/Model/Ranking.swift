//
//  Ranking.swift
//  someApp
//
//  Created by Sergio Ortiz on 06.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase

class Ranking{
    let ref: DatabaseReference?
    let key: String
    let city: String
    let foodKey: String
    let description: String
    
    init(city: String, foodKey: String, description: String = ""){
        self.ref = nil
        self.city = city
        self.foodKey = foodKey
        self.key = city.lowercased() + "-" + foodKey
        self.description = description
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let city = value["city"] as? String,
            let foodKey = value["foodKey"] as? String else {
                return nil
        }
        if let description = value["description"] as? String{
            self.description = description
        } else { self.description = ""}
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.city = city
        self.foodKey = foodKey
    }
    
    // Turn Ranking to a Dictionary
    func toAnyObject() -> Any {
        return[
            "city" : city,
            "foodKey" : foodKey,
            "description" : description]
    }
}
