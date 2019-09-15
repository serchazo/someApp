//
//  BasicSomeAppModel.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase

class SomeApp{
    private static let dbRootRef:DatabaseReference = Database.database().reference()
    static let dbFoodTypeRoot:DatabaseReference = dbRootRef.child("foodType")
    static let dbRankingsPerUser: DatabaseReference = dbRootRef.child("rankingsPerUser")
    static let dbRanking:DatabaseReference = dbRootRef.child("rankingDetail")
    static let dbResto:DatabaseReference = dbRootRef.child("resto")
    static let dbRestoPoints:DatabaseReference = dbRootRef.child("resto-points")
    static let dbRestoAddress: DatabaseReference = dbRootRef.child("resto-address")
    static let dbComments: DatabaseReference = dbRootRef.child("comments")
    static let dbCommentsPerUser:DatabaseReference = dbRootRef.child("comments-user")
    static let dbCommentsPerResto:DatabaseReference = dbRootRef.child("comments-resto")
    static let dbUserData:DatabaseReference = dbRootRef.child("user-data")
    static let dbUserFollowers:DatabaseReference = dbRootRef.child("user-followedby")

    static let themeColor:UIColor = #colorLiteral(red: 0.3236978054, green: 0.1063579395, blue: 0.574860394, alpha: 1)
    static let themeColorOpaque:UIColor = #colorLiteral(red: 0.3236978054, green: 0.1063579395, blue: 0.574860394, alpha: 0.5116117295)

    // The adds
    /// The ad unit ID.
    static let adNativeUnitID = "ca-app-pub-3940256099942544/3986624511"
    static let adBAnnerUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    // the fonts
    static var titleFont: UIFont{
        return UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(25.0))
    }
    
}

enum BasicCity: String, CaseIterable {
    case Singapore = "Singapore"
    case KualaLumpur = "Kuala Lumpur"
    case Cebu = "Cebu"
    case Manila = "Manila"
    case HongKong = "Hong Kong"
}

/*
class BasicRanking{
    let cityOfRanking:BasicCity
    var typeOfFood = ""
    var restoList = [BasicResto]()
    
    init(cityOfRanking:BasicCity, typeOfFood:String){
        self.cityOfRanking = cityOfRanking
        self.typeOfFood = typeOfFood
    }
    
    //Add ranking to resto
    func addToRanking(resto: BasicResto) -> Bool {
        print("Add new resto \(resto.restoName), \(resto.restoCity), \(resto.tags)")
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
}*/


