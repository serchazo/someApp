//
//  Resto.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 06.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase
import GooglePlaces

class Resto{
    // Must haves
    let ref: DatabaseReference?
    let key: String
    let name: String
    
    // Helper fields
    var url: URL!
    var nbPoints:Int = 0
    var nbReviews:Int = 0
    var phoneNumber: String!
    var address: String!
    var location:CLLocationCoordinate2D!
    var openingHours: GMSOpeningHours!
    var priceLevel: GMSPlacesPriceLevel!
    var attributions: NSAttributedString!
    var openStatus: String!
    
    init(key: String, name: String) {
        self.ref = nil
        
        self.key = key
        self.name = name
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let name = value["name"] as? String else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.name = name
    }
}
