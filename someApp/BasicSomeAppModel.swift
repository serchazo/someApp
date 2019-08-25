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
            for food in BasicFood.allCases{
                for n in 1...10 {
                    let tmpResto = BasicResto(restoCity: city, restoName: "\(food.rawValue) resto \(city.rawValue) \(n)")
                    tmpResto.shortDescription = "This is a short description of \(tmpResto.restoName) in the city of\(tmpResto.restoCity.rawValue)"
                    tmpResto.tags.append(food)
                    restoList.append(tmpResto)
                }
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

class BasicResto {
    let restoCity:BasicCity
    let restoName:String
    var shortDescription = ""
    var numberOfPoints = 0
    var otherInfo = ""
    var tags = [BasicFood]()
    
    init(restoCity:BasicCity, restoName:String){
        self.restoCity = restoCity
        self.restoName = restoName
    }
}

struct BasicRanking{
    let cityOfRanking:BasicCity
    let typeOfFood:BasicFood
    var ranking:[BasicResto]
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
