//
//  Comment.swift
//  someApp
//
//  Created by Sergio Ortiz on 12.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase


class Comment{
    let ref: DatabaseReference?
    let key: String
    let userid: String
    var restoid: String
    var timestamp:Double
    var text: String
    
    init(userid: String, restoid: String, text:String, timestamp:Double, key:String = "") {
        self.ref = nil
        self.key = key
        self.userid = userid
        self.restoid = restoid
        self.text = text
        self.timestamp = timestamp
    }
    
    
    init?(snapshot: DataSnapshot){
        guard
            let value = snapshot.value as? [String: AnyObject],
            let userid = value["userid"] as? String,
            let restoid = value["restoid"] as? String,
            let text = value["text"] as? String,
            let timestamp = value["timestamp"] as? Double else {
                return nil
        }
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.userid = userid
        self.restoid = restoid
        self.text = text
        self.timestamp = timestamp
        }
    
    // Turn Ranking to a Dictionary
    func toAnyObject() -> Any {
        return[
            "userid" : userid,
            "restoid" : restoid,
            "text" : text,
            "timestamp" : timestamp,
        ]
    }
}
