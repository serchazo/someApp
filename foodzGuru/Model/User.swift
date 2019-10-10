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
    
    init(nickName: String, bio: String = "", key: String = "") {
        self.ref = nil
        self.key = key
        self.nickName = nickName
        self.bio = bio
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
        
        if let bio = value["bio"] as? String {self.bio = bio} else {self.bio = ""}
    }
    
    // Turn Ranking to a Dictionary
    func toAnyObject() -> Any {
        return[
            "nickname" : nickName,
            "bio" : bio,
        ]
    }
    
}
