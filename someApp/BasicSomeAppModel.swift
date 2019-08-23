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

enum BasicCity:String{
    case Singapore = "Singapore"
    case KualaLumpur = "Kuala Lumpur"
    case Cebu = "Cebu"
    case Manila = "Manila"
    case HongKong = "Hong Kong"
}

enum BasicFood:String{
    case Chinese = "Chinese"
    case Burger = "Burger"
    case Italian = "Italian"
    case Pizza = "Pizza"
    case Indian = "Indian"
    case Japanse = "Japanese"
}
