//
//  User.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 12.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase

class UserDetails{
    let ref: DatabaseReference?
    let key: String
    let nickName: String
    var bio: String
    var photoURLString: String
    var defaultCity:String
    
    init(nickName: String, bio: String = " ", key: String = "", photoURL:String = "", defaultCity:String = "") {
        self.ref = nil
        self.key = key
        self.nickName = nickName
        self.bio = bio
        self.photoURLString = photoURL
        self.defaultCity = defaultCity
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let name = value["nickname"] as? String else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.nickName = name
        
        if let bio = value["bio"] as? String {self.bio = bio}
        else {self.bio = " "}
        if let tmpURL = value["photourl"] as? String {self.photoURLString = tmpURL} else {self.photoURLString = ""}
        if let tmpCity = value["default"] as? String {self.defaultCity = tmpCity} else {self.defaultCity = "sg/sg/sin/Singapore"}
    }
    
    // Turn Ranking to a Dictionary
    func toAnyObject() -> Any {
        return[
            "nickname" : nickName,
            "bio" : bio,
            "photourl" : photoURLString,
            "default" : defaultCity
        ]
    }
    
}
