//
//  BasicSomeAppModel.swift
//  someApp
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase
import MapKit

class SomeApp{
    private static let dbRootRef:DatabaseReference = Database.database().reference()
    static let dbFoodTypeRoot:DatabaseReference = dbRootRef.child("foodType")
    static let dbResto:DatabaseReference = dbRootRef.child("resto")
    static let dbRestoPoints:DatabaseReference = dbRootRef.child("resto-points")
    static let dbRestoAddress: DatabaseReference = dbRootRef.child("resto-address")
    static let dbComments: DatabaseReference = dbRootRef.child("comments")
    static let dbCommentsPerUser:DatabaseReference = dbRootRef.child("comments-user")
    static let dbCommentsPerResto:DatabaseReference = dbRootRef.child("comments-resto")
    static let dbUserActivity:DatabaseReference = dbRootRef.child("user-activity")
    static let dbUserData:DatabaseReference = dbRootRef.child("user-data")
    static let dbUserFollowers:DatabaseReference = dbRootRef.child("user-followers")
    static let dbUserFollowing:DatabaseReference = dbRootRef.child("user-following")
    static let dbUserNbFollowers:DatabaseReference = dbRootRef.child("user-nbfollowers")
    static let dbUserTimeline:DatabaseReference = dbRootRef.child("user-timeline")
    static let dbUserRankings: DatabaseReference = dbRootRef.child("user-rankings")
    static let dbUserRankingDetails:DatabaseReference = dbRootRef.child("user-ranking-detail")
    
    //geography
    static let dbGeography:DatabaseReference = dbRootRef.child("geography")

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
    
    
    // Write to the DB
    static func follow(userId: String, toFollowId: String){
        let followingDBReference = SomeApp.dbUserFollowing.child(userId)
        let newfollowerRef = followingDBReference.child(toFollowId)
        newfollowerRef.setValue("true")
    }
    
    static func unfollow(userId: String, unfollowId: String){
        let followingDBReference = SomeApp.dbUserFollowing.child(userId)
        followingDBReference.child(unfollowId).removeValue()
    }
    
    // TODO : this doesn't work anymore
    static func deleteUserRanking(userId: String, rankingId: String){
        SomeApp.dbUserRankings.child(rankingId).removeValue()
        SomeApp.dbUserRankingDetails.child(userId+"-"+rankingId).removeValue()
    }
    
    // Add resto to Ranking : we need to check the model first
    static func addRestoToRanking(userId: String, resto: Resto, mapItem: MKMapItem, forFood:FoodType, ranking: Ranking,city: City){
        let dbPath = city.country + "/" + city.state + "/" + city.key
        
        // A. Check if the resto exists in the resto list
        dbResto.child(dbPath).child(resto.key).observeSingleEvent(of: .value, with: {snapshot in
            // If the restorant doesn't exist, we need to create it and add it

            if (!snapshot.exists()){
                // Add resto details
                if mapItem.url != nil{ resto.url = mapItem.url! }
                if mapItem.phoneNumber != nil {resto.phoneNumber = mapItem.phoneNumber!}
                if mapItem.placemark.formattedAddress != nil { resto.address = mapItem.placemark.formattedAddress!}
                // Write to Resto DB
                let newRestoRef = self.dbResto.child(dbPath).child(resto.key)
                newRestoRef.setValue(resto.toAnyObject())
                // Add the resto to the Address DB
                SomeApp.addrestoAddressToModel(mapItem: mapItem, resto: resto, city:city)
            }
            // Still need to add to ranking
            addRestoUserRanking(userid: userId, resto: resto, city: city, ranking: ranking)
        })
    }
    
    
    // Add resto to ranking
    private static func addRestoUserRanking(userid: String, resto: Resto, city: City, ranking: Ranking){
        let dbPath = userid + "/" + city.country + "/" + city.state + "/" + city.key + "/" + ranking.key
        // Get current number of items in the ranking
        dbUserRankingDetails.child(dbPath).observeSingleEvent(of: .value, with: {snapshot in
            let position = snapshot.childrenCount + 1
            // Then, add to the ranking
            dbUserRankingDetails.child(dbPath).child(resto.key).child("position").setValue(position)
        })
    }
    
    // Add restoAddressToModel
    private static func addrestoAddressToModel(mapItem: MKMapItem, resto: Resto, city: City){
        let dbPath = city.country + "/" + city.state + "/" + city.key
        let restoAddress = RestoMapArray(fromMapItem: mapItem)
        let encoder = JSONEncoder()
        
        do {
            let encodedMapItem = try encoder.encode(restoAddress)
            let encodedMapItemForFirebase = NSString(data: encodedMapItem, encoding: String.Encoding.utf8.rawValue)
            
            let again = dbRestoAddress.child(dbPath).child(resto.key).child("address")
            again.setValue(encodedMapItemForFirebase)
            
        } catch {
            print(error.localizedDescription)
        }
    }
}

enum DefinedOperationsInRanking:String{
    case Delete = "Delete"
    case Add = "Add"
    case Update = "Update"
}

struct RankingOperation{
    let operationType:DefinedOperationsInRanking
    let restoIdentifier:String
    let initialPlace:Int = 0
    let finalPlace:Int = 0
}

/*
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
