//
//  City.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 19.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase

class City{
    let ref: DatabaseReference?
    let key: String
    let country: String
    let state: String
    let name: String
    
    init(name: String, state: String, country: String, key:String = "") {
        self.ref = nil
        self.name = name
        self.state = state
        self.country = country
        self.key = key
    }
    
    init(country: String, state: String, key: String, name:String = "") {
        self.ref = nil
        self.name = name
        self.state = state
        self.country = country
        self.key = key
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let name = value["name"] as? String,
            let state = value["state"] as? String,
            let country = value["country"] as? String else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.name = name
        self.state = state
        self.country = country
    }
    
    // Turn Ranking to a Dictionary
    func toAnyObject() -> Any {
        return[
            "name" : name,
            "state" : state,
            "country" : country,
        ]
    }
    
}
