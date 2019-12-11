//
//  Resto.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 06.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase
import MapKit

class Resto{
    let ref: DatabaseReference?
    let key: String
    let name: String
    var url: URL!
    var phoneNumber: String
    var address: String
    let city: String
    var nbPoints:Int = 0 //This is a helper value, don't put in the -> Any
    var nbReviews:Int = 0 // same
    
    
    init(name: String, city: String, url: String = "", phoneNumber:String = "", address: String = "", addressKey:String = "") {
        self.ref = nil
        
        let pattern = "[^A-Za-z0-9]+"
        let tmpModifiedName = name.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        let tmpModifiedAddressKey = addressKey.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        
        self.key = city.lowercased() + "-" + tmpModifiedName.lowercased() + "-" + tmpModifiedAddressKey.lowercased()
        self.name = name
        self.url = URL(fileURLWithPath: url)
        self.phoneNumber = phoneNumber
        self.address = address
        self.city = city
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let name = value["name"] as? String,
            let city = value["city"] as? String else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.name = name
        self.city = city
        
        // URL
        if let url = value["url"] as? String,
            url.lowercased().hasPrefix("http"){
            self.url = URL(string: url)
        } else {self.url = nil}
        // Phone number
        if let phone = value["phoneNumber"] as? String {self.phoneNumber = phone } else {self.phoneNumber = ""}
        if let address = value["address"] as? String {self.address = address} else {self.address = ""}
    }
    
    // Turn Ranking to a Dictionary
    func toAnyObject() -> Any {
        return[
            "name" : name,
            "city" : city,
            "url" : url.absoluteString,
            "phoneNumber" : phoneNumber,
            "address" : address
        ]
    }
}
