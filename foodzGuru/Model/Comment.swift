//
//  Comment.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 12.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase


class Comment{
    let ref: DatabaseReference?
    let key: String
    let username: String
    var restoname: String
    var timestamp:Double
    var text: String
    
    init(username: String, restoname: String, text:String, timestamp:Double, title: String, key:String = "") {
        self.ref = nil
        self.key = key
        self.username = username
        self.restoname = restoname
        self.text = text
        self.timestamp = timestamp
    }
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let text = value["text"] as? String,
            let timestamp = value["timestamp"] as? Double else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.text = text
        self.timestamp = timestamp
        
        if let restoname = value["restoname"] as? String {self.restoname = restoname} else {self.restoname = ""}
        if let username = value["username"] as? String {self.username = username} else {self.username = ""}
        
        }
    
    // Turn Ranking to a Dictionary
    /*func toAnyObject() -> Any {
        return[
            "restoname" : restoname,
            "username" : username,
            "title" : title,
            "text" : text,
            "timestamp" : timestamp,
        ]
    }*/
}
