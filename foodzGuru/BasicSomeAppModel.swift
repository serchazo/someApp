//
//  BasicSomeAppModel.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 22.08.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import Foundation
import Firebase
import MapKit

class SomeApp{
    // Constant
    static let currentCityDefault = "currentCity"
    
    // DB
    private static let dbRootRef:DatabaseReference = Database.database().reference()
    static let dbFoodTypeRoot:DatabaseReference = dbRootRef.child("foodType")
    static let dbResto:DatabaseReference = dbRootRef.child("resto")
    static let dbRestoPoints:DatabaseReference = dbRootRef.child("resto-points")
    static let dbRestoAddress: DatabaseReference = dbRootRef.child("resto-address")
    static let dbRestoReviews:DatabaseReference = dbRootRef.child("resto-reviews")
    static let dbUserActivity:DatabaseReference = dbRootRef.child("user-activity")
    static let dbUserData:DatabaseReference = dbRootRef.child("user-data")
    static let dbUserFollowers:DatabaseReference = dbRootRef.child("user-followers")
    static let dbUserFollowing:DatabaseReference = dbRootRef.child("user-following")
    static let dbUserFollowingRankings:DatabaseReference = dbRootRef.child("user-following-rankings")
    static let dbUserNbFollowers:DatabaseReference = dbRootRef.child("user-nbfollowers")
    static let dbUserNbFollowing:DatabaseReference = dbRootRef.child("user-nbfollowing")
    static let dbUserTimeline:DatabaseReference = dbRootRef.child("user-timeline")
    static let dbUserRankings: DatabaseReference = dbRootRef.child("user-rankings")
    static let dbUserRankingGeography: DatabaseReference = dbRootRef.child("user-ranking-geography")
    static let dbUserRankingDetails:DatabaseReference = dbRootRef.child("user-ranking-detail")
    static let dbUserReviews:DatabaseReference = dbRootRef.child("user-reviews")
    
    //rankings
    static let dbRankingFollowers:DatabaseReference = dbRootRef.child("rankings-followers")
    
    //geography
    static let dbGeography:DatabaseReference = dbRootRef.child("geography")
    static let dbGeographyCountry:DatabaseReference = dbRootRef.child("geography-countries")
    static let dbGeographyStates:DatabaseReference = dbRootRef.child("geography-state")

    // MARK: storage
    static let storageRef = Storage.storage().reference()
    static let storageUsersRef = storageRef.child("users")
    
    // Hex code: #614051
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
    
    // MARK: User timeline
    static func createUserFirstLogin(userId: String, username: String, bio: String, defaultCity:String, photoURL: String = ""){
        let userDataDBRef = dbUserData.child(userId)
        // Transform the data to AnyObject
        let dataToWrite = [ "nickname" : username, "bio" : bio, "default" : defaultCity, "photourl": photoURL]
        userDataDBRef.setValue(dataToWrite)
        
        // Create the first timeline post
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        let payLoad = "Hello " + username + "! Welcome to foodz.guru, follow foodies and rankings and you'll see here their most important updates."
        let userTimelineDBRef = dbUserTimeline.child(userId).child("systemNotification:"+userId+":welcometofoodzguru")
        let firstTimelinePost:[String:Any] = ["timestamp": timestamp,
                                 "type" : "systemNotification",
                                 "icon" : "💬",
                                 "target" : "",
                                 "payload" : payLoad
                                    ]
        userTimelineDBRef.setValue(firstTimelinePost)
    }
    
    // Update profile picture
    static func updateProfilePic(userId: String, photoURL: String){
        let userDataDBRef = dbUserData.child(userId)
        userDataDBRef.updateChildValues(["photourl":photoURL])
    }
    
    // Update bio
    static func updateBio(userId: String, bio: String){
        let userDataDBRef = dbUserData.child(userId).child("bio")
        userDataDBRef.setValue(bio)
    }
    
    // Delete user
    static func deleteUser(userId: String){
        dbUserData.child(userId).removeValue()
    }
    
    
    // MARK: User follow users and rankings
    static func follow(userId: String, toFollowId: String){
        let followingDBReference = SomeApp.dbUserFollowing.child(userId)
        let newfollowerRef = followingDBReference.child(toFollowId)
        newfollowerRef.setValue("true")
    }
    
    static func unfollow(userId: String, unfollowId: String){
        let followingDBReference = SomeApp.dbUserFollowing.child(userId)
        followingDBReference.child(unfollowId).removeValue()
    }
    
    // Follow and unfollow rankings
    static func followRanking(userId: String, city: City, foodId: String){
        let dbPath = city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + userId
        let userFollowingPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId
        let userFollowingRankingRef = SomeApp.dbUserFollowingRankings.child(userFollowingPath)
        let followingRankingDBReference = SomeApp.dbRankingFollowers.child(dbPath)
        userFollowingRankingRef.setValue(true)
        followingRankingDBReference.setValue(true)
        
        
    }
    static func unfollowRanking(userId: String, city: City, foodId: String){
        let dbPath = city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + userId
        let userFollowingPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId
        let followingRankingDBReference = SomeApp.dbRankingFollowers.child(dbPath)
        let userFollowingRankingRef = SomeApp.dbUserFollowingRankings.child(userFollowingPath)
        followingRankingDBReference.removeValue()
        userFollowingRankingRef.removeValue()
    }
    
    // Add a new city to user (country name and state name will be added with functions)
    static func addUserCity(userId: String, city: City, countryName: String, stateName: String){
        print("here \(countryName)")
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key
        let objectToWrite: [String:Any] = ["country": countryName,
                                                 "state": stateName,
                                                 "name": city.name]
        let dbRef = SomeApp.dbUserRankingGeography.child(dbPath)
        dbRef.setValue(objectToWrite)
    }
    
    // MARK: ranking functions
    // Add a new ranking
    static func newUserRanking(userId: String, city: City, food: FoodType){
        let defaultDescription = "Spent all my life looking for the best " + food.name + " places in " + city.name + ". This is the definitive list."
        let newRanking = Ranking(foodKey: food.key,name: food.name, icon: food.icon, description: defaultDescription)
        // Create a child reference and update the value
        let pathId = userId + "/"+city.country+"/"+city.state+"/"+city.key
        let newRankingRef = SomeApp.dbUserRankings.child(pathId).child(newRanking.key)
        newRankingRef.setValue(newRanking.toAnyObject())
    }
    
    
    // Update the position of a resto
    static func updateRestoPositionInRanking(userId: String, city: City, foodId: String, restoId: String, position: Int){
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + restoId + "/position"
        SomeApp.dbUserRankingDetails.child(dbPath).setValue(position)
    }
    
    // Delete resto
    static func deleteRestoFromRanking(userId: String, city: City, foodId: String, restoId: String){
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + restoId
        SomeApp.dbUserRankingDetails.child(dbPath).removeValue()
    }
    
    // Delete ranking
    static func deleteUserRanking(userId: String, city: City, foodId: String){
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId
        SomeApp.dbUserRankings.child(dbPath).removeValue()
        SomeApp.dbUserRankingDetails.child(dbPath).removeValue()
    }
    
    // Add resto to Ranking : we need to check the model first
    static func addRestoToRanking(userId: String, resto: Resto, mapItem: MKMapItem, forFood:FoodType, foodId: String,city: City){
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
            addRestoUserRanking(userid: userId, resto: resto, city: city, foodId: foodId)
        })
    }
    
    
    // Add resto to ranking
    private static func addRestoUserRanking(userid: String, resto: Resto, city: City, foodId: String){
        let dbPath = userid + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId
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
    
    // MARK: Add/update Review
    static func updateUserReview(userid: String, resto: Resto, city: City, foodId: String, text: String){
        let dbPath = userid + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key
        let dbRef = dbUserReviews.child(dbPath)
        
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        let reviewPost:[String:Any] = ["timestamp": timestamp,
                                       "text": text,
                                       "restoname": resto.name]
        
        dbRef.setValue(reviewPost)
        
        
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

enum TimelineEvents:String{
    case NewFollower = "newUserFollowing"
    case NewUserRanking = "newRanking"
    case NewUserFavorite = "newUserFavorite"
    case NewBestRestoInRanking = "newBestRestoInRanking"
    case NewArrivalInRanking = "newArrivalInRanking"
    case NewUserReview = "newUserReview"
    case FoodzGuruPost = "systemNotification"
}


