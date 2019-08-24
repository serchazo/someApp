//
//  BasicSomeAppModel.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation

class BasicModel{
    
    // This part will in theory disappear with the DB
    var restoList = [BasicResto]()
    var userList = [BasicUser]()
    
    init(){
        //Initialize restos
        for city in BasicCity.allCases{
            for n in 1...10 {
                restoList.append(BasicResto(restoCity: city, restoName: "resto \(city.rawValue) \(n)", shortDescription: "description \(n)",numberOfPoints: n, otherInfo: "City: \(city.rawValue)"))
            }
        }
        
        //Initialize Users
        for n in 1...5{
            userList.append(BasicUser(userName: "user\(n)", userPassword: "user\(n)"))
        }
    }
    // Some getters
    func getSomeRestoList(fromCity: BasicCity) -> [BasicResto]{
        return restoList.filter {$0.restoCity == fromCity}
    }
}
var basicModel = BasicModel()

// This part will be improved later on
struct BasicUser{
    let userName:String
    var userPassword:String
}

struct BasicResto {
    let restoCity:BasicCity
    let restoName:String
    var shortDescription:String
    var numberOfPoints:Int
    var otherInfo:String
}

enum BasicSelection:String {
    case City
    case Food
}

struct BasicPoint {
    let typeOfFood: BasicFood
    var nbPoints: Int
}

enum BasicCity: String, CaseIterable {
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
