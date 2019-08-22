//
//  BasicSomeAppModel.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation

class BasicModel{
    var restoList = [BasicResto]()
    init(){
        for n in 1...5{
            restoList.append(BasicResto(restoName: "resto \(n)", shortDescription: "description \(n)"))
        }
    }
}


struct BasicResto {
    var restoName:String
    var shortDescription:String
}
