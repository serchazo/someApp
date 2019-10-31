//
//  RestoMapArray.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 08.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import MapKit
import Firebase


struct RestoMapArray: Codable{
    var restoMapItem: MKMapItem!
    //var restoMapArray:[MKMapItem] = []
    
    enum CodingKeys: String, CodingKey {
        case map
    }
    
    init(fromMapItem: MKMapItem){
        restoMapItem = fromMapItem
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mapData = try container.decode(Data.self, forKey: .map)
        restoMapItem = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(mapData) as? MKMapItem
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let mapData = try NSKeyedArchiver.archivedData(withRootObject: restoMapItem!, requiringSecureCoding: false)
        try container.encode(mapData, forKey: .map)
    }
}


