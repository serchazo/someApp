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
            restoList.append(BasicResto(restoName: "resto \(n)", shortDescription: "description \(n)",numberOfPoints: n, otherInfo: "Some info here"))
        }
    }
}


struct BasicResto {
    var restoName:String
    var shortDescription:String
    var numberOfPoints:Int
    var otherInfo:String
}

enum BasicSelection:String {
    case City
    case Food
}

enum BasicCity:String, CaseIterable{
    case Singapore = "Singapore"
    case KualaLumpur = "Kuala Lumpur"
    case Cebu = "Cebu"
    case Manila = "Manila"
    case HongKong = "Hong Kong"
}

enum BasicFood:String, CaseIterable{
    case Chinese = "Chinese"
    case Burger = "Burger"
    case Italian = "Italian"
    case Pizza = "Pizza"
    case Indian = "Indian"
    case Japanse = "Japanese"
}
