//
//  BasicUser.swift
//  someApp
//
//  Created by Sergio Ortiz on 05.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation

class BasicUser{
    let userName:String
    var userPassword:String
    var myRankings:[BasicRanking]
    
    init(userName:String, userPassword:String){
        self.userName = userName
        self.userPassword = userPassword
        myRankings = [BasicRanking]()
    }
}
