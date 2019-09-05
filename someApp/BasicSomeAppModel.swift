//
//  BasicSomeAppModel.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import MapKit
import Firebase

class BasicModel{
    
    // This part will in theory disappear with the DB
    var modelRestoList = [BasicResto]()
    var userList = [BasicUser]()
    var old_foodList = [BasicFoodType]()
    var foodList: [FoodType] = []
    
    init(){
        // test part
        let dbRootRef = Database.database().reference()
        let dbFoodTypeRoot = dbRootRef.child("foodType")
        
        dbFoodTypeRoot.observe(.value, with: {snapshot in
            var tmpFoodList: [FoodType] = []
            
            for child in snapshot.children{
                if let childSnapshot = child as? DataSnapshot,
                    let foodItem = FoodType(snapshot: childSnapshot){
                    tmpFoodList.append(foodItem)
                }
            }
            self.foodList = tmpFoodList
            
            for food in self.foodList{
                print("name \(food.name) with icon \(food.icon)")
            }
        })
        
        
        
        
        // Old one
        for city in BasicCity.allCases{
            for food in BasicFood.allCases{
                for n in 1...5 {
                    let tmpResto = BasicResto(restoCity: city, restoName: "\(food.rawValue) resto \(city.rawValue) \(n)")
                    tmpResto.shortDescription = "This is a short description of \(tmpResto.restoName) in the city of\(tmpResto.restoCity.rawValue)"
                    tmpResto.restoURL = URL(string: "https://www.google.com")
                    tmpResto.tags.append(food)
                    tmpResto.comments.append(Comment(date: Date(), user: "user1", commentText: "Terrific restorant!"))
                    modelRestoList.append(tmpResto)
                }
            }
        }
        
        // Initialize food Icons
        for food in BasicFood.allCases{
            switch(food){
            case .Burger: old_foodList.append(BasicFoodType(foodType: .Burger, foodDescription: food.rawValue, foodIcon: "🍔"))
            case .Italian: old_foodList.append(BasicFoodType(foodType: .Italian, foodDescription: food.rawValue, foodIcon: "🍝"))
            case .Pizza: old_foodList.append(BasicFoodType(foodType: .Pizza, foodDescription: food.rawValue, foodIcon: "🍕"))
            case .Mexican: old_foodList.append(BasicFoodType(foodType: .Mexican, foodDescription: food.rawValue, foodIcon: "🌮"))
            case .Japanese: old_foodList.append(BasicFoodType(foodType: .Japanese, foodDescription: food.rawValue, foodIcon: "🍱"))
            case .Salad: old_foodList.append(BasicFoodType(foodType: .Salad, foodDescription: food.rawValue, foodIcon: "🥗"))
            case .Patisserie: old_foodList.append(BasicFoodType(foodType: .Patisserie, foodDescription: food.rawValue, foodIcon: "🧁"))
            case .Cafe: old_foodList.append(BasicFoodType(foodType: .Cafe, foodDescription: food.rawValue, foodIcon: "☕️"))
            case .CocktailBar: old_foodList.append(BasicFoodType(foodType: .CocktailBar, foodDescription: food.rawValue, foodIcon: "🍹"))
            }
        }
        
        //Initialize Users
        for n in 1...5{
            userList.append(BasicUser(userName: "user\(n)", userPassword: "user\(n)"))
        }
        
        userList[0].myRankings.append(BasicRanking(cityOfRanking: .Singapore, typeOfFood: .Burger))
        userList[0].myRankings.append(BasicRanking(cityOfRanking: .Singapore, typeOfFood: .Italian))
    }
    // Some getters
    func getSomeRestoList(fromCity: BasicCity) -> [BasicResto]{
        return modelRestoList.filter {$0.restoCity == fromCity}
    }
    func getSomeRestoList(fromCity:BasicCity, ofFoodType: BasicFood) -> [BasicResto] {
        return modelRestoList.filter {$0.restoCity == fromCity && $0.tags.contains(ofFoodType)}
    }
    // Some setters
    func addRestoToModel(resto: BasicResto) {
        if (modelRestoList.filter {$0.restoCity == resto.restoCity && $0.restoName == resto.restoName}).count == 0{
            modelRestoList.append(resto)
        }
    }
    //
    func updateScore(forResto: BasicResto, withPoints: Int){
        (modelRestoList.filter {$0.restoCity == forResto.restoCity && $0.restoName == forResto.restoName})[0].numberOfPoints += withPoints
    }
    
}
var basicModel = BasicModel()

// This part will be improved later on


class BasicResto {
    let restoCity:BasicCity
    let restoName:String
    var shortDescription = ""
    var numberOfPoints = 0
    var restoURL: URL?
    var comments: [Comment] = []
    
    var address:String{
        get{
            switch(mapItems.count){
            case 0: return "No address available."
            case 1:
                if mapItems[0].placemark.formattedAddress != nil {
                    return mapItems[0].placemark.formattedAddress!
                }else{
                    return "No address available."
                }
            default: return "Multiple adresses."
            }
        }
    }
    var mapItems: [MKMapItem] = []
    var tags: [BasicFood] = []
    
    init(restoCity:BasicCity, restoName:String){
        self.restoCity = restoCity
        self.restoName = restoName
    }
    // Add a new placemark
    func addPlaceItemToResto(placeItem: MKMapItem){
        if !(mapItems.filter({$0.placemark.hashValue == placeItem.hashValue}).count > 0){
            mapItems.append(placeItem)
        }
    }
}

// Comment class
class Comment{
    let date: Date
    let user: String
    let commentText: String
    var likes:[String] = []
    var dislikes:[String] = []
    init(date: Date, user: String, commentText: String){
        self.date = date
        self.user = user
        self.commentText = commentText
    }
}

class BasicRanking{
    let cityOfRanking:BasicCity
    let typeOfFood:BasicFood
    var restoList = [BasicResto]()
    init(cityOfRanking:BasicCity, typeOfFood:BasicFood){
        self.cityOfRanking = cityOfRanking
        self.typeOfFood = typeOfFood
    }
    
    //Add ranking to resto
    func addToRanking(resto: BasicResto) -> Bool {
        if (restoList.filter {$0.restoCity == resto.restoCity && $0.restoName == resto.restoName}).count > 0{
            return false
        }else{
            restoList.append(resto)
            basicModel.addRestoToModel(resto: resto)
            basicModel.updateScore(forResto: resto, withPoints: 10-restoList.count)
            return true
        }
    }
    
    //Update ranking
    func updateList(sourceIndex: Int, destinationIndex: Int){
        //Update the number of points
        if sourceIndex<destinationIndex{
            for index in (sourceIndex+1)...destinationIndex{
                restoList[index].numberOfPoints += 1
            }
            restoList[sourceIndex].numberOfPoints -= (destinationIndex - sourceIndex)
        }else{
            for index in destinationIndex...(sourceIndex-1){
                restoList[index].numberOfPoints -= 1
            }
            restoList[sourceIndex].numberOfPoints += (sourceIndex - destinationIndex)
        }
        
        //Update the list
        let tempResto = restoList[sourceIndex]
        restoList.remove(at: sourceIndex)
        restoList.insert(tempResto, at: destinationIndex)
    }
}

struct BasicFoodType{
    let foodType:BasicFood
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
