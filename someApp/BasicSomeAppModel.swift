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
    var foodList = [BasicFoodType]()
    
    init(){
        //Initialize restos
        for city in BasicCity.allCases{
            for n in 1...10 {
                restoList.append(BasicResto(restoCity: city, restoName: "resto \(city.rawValue) \(n)", shortDescription: "description \(n)",numberOfPoints: n, otherInfo: "City: \(city.rawValue)"))
            }
        }
        
        // Initialize food Icons
        for food in BasicFood.allCases{
            switch(food){
            case .Burger: foodList.append(BasicFoodType(foodtype: .Burger, foodDescription: food.rawValue, foodIcon: "🍔"))
            case .Italian: foodList.append(BasicFoodType(foodtype: .Italian, foodDescription: food.rawValue, foodIcon: "🍝"))
            case .Pizza: foodList.append(BasicFoodType(foodtype: .Pizza, foodDescription: food.rawValue, foodIcon: "🍕"))
            case .Mexican: foodList.append(BasicFoodType(foodtype: .Mexican, foodDescription: food.rawValue, foodIcon: "🌮"))
            case .Japanese: foodList.append(BasicFoodType(foodtype: .Japanese, foodDescription: food.rawValue, foodIcon: "🍱"))
            case .Salad: foodList.append(BasicFoodType(foodtype: .Salad, foodDescription: food.rawValue, foodIcon: "🥗"))
            case .Patisserie: foodList.append(BasicFoodType(foodtype: .Patisserie, foodDescription: food.rawValue, foodIcon: "🧁"))
            case .Cafe: foodList.append(BasicFoodType(foodtype: .Cafe, foodDescription: food.rawValue, foodIcon: "☕️"))
            case .CocktailBar: foodList.append(BasicFoodType(foodtype: .CocktailBar, foodDescription: food.rawValue, foodIcon: "🍹"))
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

struct BasicFoodType{
    let foodtype:BasicFood
    let foodDescription:String
    let foodIcon:String
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
    case Burger = "Burger"
    case Italian = "Italian"
    case Pizza = "Pizza"
    case Mexican = "Mexican"
    case Japanese = "Japanese"
    case Salad = "Salad"
    case Cafe = "Cafe"
    case CocktailBar = "Cocktail Bar"
    case Patisserie = "Patisserie"
}
