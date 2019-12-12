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
    // Constants
    static let currentCityDefault = "currentCity"
    static var currentLocation:CLLocation!
    
    // DB
    private static let dbRootRef:DatabaseReference = Database.database().reference()
    static let dbFoodTypeRoot:DatabaseReference = dbRootRef.child("foodType")
    static let dbResto:DatabaseReference = dbRootRef.child("resto")
    static let dbRestoPoints:DatabaseReference = dbRootRef.child("resto-points")
    static let dbRestoAddress: DatabaseReference = dbRootRef.child("resto-address")
    static let dbUserActivity:DatabaseReference = dbRootRef.child("user-activity")
    static let dbUserData:DatabaseReference = dbRootRef.child("user-data")
    static let dbUserDevices:DatabaseReference = dbRootRef.child("user-devices")
    static let dbUserPointsMultiplier:DatabaseReference = dbRootRef.child("user-pointsmultiplier")
    static let dbUserFollowers:DatabaseReference = dbRootRef.child("user-followers")
    static let dbUserFollowing:DatabaseReference = dbRootRef.child("user-following")
    static let dbUserNbFollowers:DatabaseReference = dbRootRef.child("user-followers-nb")
    static let dbUserNbFollowing:DatabaseReference = dbRootRef.child("user-following-nb")
    static let dbUserFollowingRankings:DatabaseReference = dbRootRef.child("user-following-rankings")
    static let dbUserTimeline:DatabaseReference = dbRootRef.child("user-timeline")
    static let dbUserRankings: DatabaseReference = dbRootRef.child("user-rankings")
    static let dbUserRankingGeography: DatabaseReference = dbRootRef.child("user-ranking-geography")
    static let dbUserRankingDetails:DatabaseReference = dbRootRef.child("user-ranking-detail")
    static let dbUserReportedReviews: DatabaseReference = dbRootRef.child("user-reported-reviews")
    static let dbUserBlocked: DatabaseReference = dbRootRef.child("user-blocked")
    static let dbReportedUsers: DatabaseReference = dbRootRef.child("reported-users")
    
    // Reviews and likes
    static let dbUserReviews:DatabaseReference = dbRootRef.child("user-reviews")
    static let dbUserLikedReviews:DatabaseReference = dbRootRef.child("user-liked-reviews")
    static let dbUserReviewsLikes:DatabaseReference = dbRootRef.child("user-reviews-likes")
    static let dbUserReviewsLikesNb:DatabaseReference = dbRootRef.child("user-reviews-likes-nb")
    static let dbRestoReviews:DatabaseReference = dbRootRef.child("resto-reviews")
    static let dbRestoReviewsLikes:DatabaseReference = dbRootRef.child("resto-reviews-likes")
    static let dbRestoReviewsLikesNb:DatabaseReference = dbRootRef.child("resto-reviews-likes-nb")
    
    //rankings
    static let dbRankingFollowers:DatabaseReference = dbRootRef.child("rankings-followers")
    static let dbRankingFollowersDevices:DatabaseReference = dbRootRef.child("rankings-followers-devices")
    static let dbRankingFollowersNb:DatabaseReference = dbRootRef.child("rankings-followers-nb")
    
    //geography
    static let dbGeography:DatabaseReference = dbRootRef.child("geography")
    static let dbGeographyCountry:DatabaseReference = dbRootRef.child("geography-countries")
    static let dbGeographyStates:DatabaseReference = dbRootRef.child("geography-state")

    // MARK: storage
    static let storageRef = Storage.storage().reference()
    static let storageUsersRef = storageRef.child("users")
    static let storageFoodRef = storageRef.child("food")
    static let storageContryPicRef = storageRef.child("countries")
    
    // Hex code: #614051, RGB: (82,27,146)
    //static let themeColor:UIColor = #colorLiteral(red: 0.3236978054, green: 0.1063579395, blue: 0.574860394, alpha: 1)
    static let themeColor = UIColor.systemIndigo
    static let themeColorOpaque:UIColor = #colorLiteral(red: 0.3236978054, green: 0.1063579395, blue: 0.574860394, alpha: 0.5116117295)
    //static let selectionColor:UIColor = #colorLiteral(red: 0, green: 0.3285208941, blue: 0.5748849511, alpha: 1)
    static let selectionColor:UIColor = UIColor.systemGray

    
    // The ads
    // Test ads
    //static let adNativeUnitID = "ca-app-pub-3940256099942544/3986624511"
    //static let adBAnnerUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    // APN stuff
    static var deviceToken:String!
    static var tokenChangedFlag:Bool = false
    
    // Prod ads
    static let adBAnnerUnitID = "ca-app-pub-5723552712049473/6238131752"
    static let adNativeUnitID = "ca-app-pub-5723552712049473/6280641581"
    
    static let rankingDescription:[String] =
    ["And the winners are...",
    "People have spoken...",
    "Is your favorite place in the list?",
    "Ready, set, eat!"]
    
    static func getPhrase() -> String{
        let number = Int.random(in: 0 ..< rankingDescription.count)
        return rankingDescription[number]
    }
    
    // the fonts
    static var titleFont: UIFont{
        return UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(25.0))
    }
    
    // MARK: User timeline
    static func createUserFirstLogin(userId: String, username: String, bio: String, defaultCity:String, photoURL: String = "", deviceToken:String = ""){
        let userDataDBRef = dbUserData.child(userId)
        // Transform the data to AnyObject
        let dataToWrite = [ "nickname" : username, "bio" : bio, "default" : defaultCity, "photourl": photoURL]
        userDataDBRef.setValue(dataToWrite)
        
        SomeApp.updateDeviceToken(userId: userId, deviceToken: deviceToken)
        
        // Create the first timeline post
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        let payLoad = String.localizedStringWithFormat(NSLocalizedString("HOME_FIRST_POST", comment: "First Post"), username)
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
    
    // Update device token
    static func updateDeviceToken(userId: String, deviceToken: String){
        let deviceModel = SomeApp.getDeviceModel()
        let tmpPath = userId + "/" + deviceModel
        
        dbUserDevices.child(tmpPath).setValue(deviceToken)
        var updateObject:[String:Any] = [:]
        
        // Verify if the user is following rankings
        SomeApp.dbUserFollowingRankings.child(userId).observeSingleEvent(of: .value, with: {snapshot in
            for child in snapshot.children{
                if let countrySnap = child as? DataSnapshot{
                    let countryId = countrySnap.key
                    // States
                    for stateChild in countrySnap.children{
                        if let stateSnap = stateChild as? DataSnapshot{
                            let stateId = stateSnap.key
                            // Cities
                            for cityChild in stateSnap.children{
                                if let citySnap = cityChild as? DataSnapshot{
                                    let cityId = citySnap.key
                                    // Foodz
                                    for foodChild in citySnap.children{
                                        if let foodSnap = foodChild as? DataSnapshot{
                                            let foodId = foodSnap.key
                                            
                                            let dbPath = countryId + "/" + stateId + "/" + cityId + "/" + foodId + "/" + userId + "/" + deviceModel
                                            updateObject["rankings-followers-devices/" + dbPath] = deviceToken
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }// states
                }
            }
            dbRootRef.updateChildValues(updateObject)
        })
    }
    
    // Delete user
    static func deleteUser(userId: String){
        // Delete profile picture
        let storagePath = userId + "/profilepicture.png"
        let imageRef = SomeApp.storageUsersRef.child(storagePath)
        imageRef.delete(completion: {(error) in
            if let error = error{
                print(error.localizedDescription)
            }
        })
        // Delete user
        dbUserData.child(userId).removeValue()
    }
    
    
    // MARK: User follow users and rankings
    static func follow(userId: String, toFollowId: String){
        var updateObject:[String:Any] = [:]
        updateObject["user-following/" + userId + "/" + toFollowId] = true
        updateObject["user-followers/" + toFollowId + "/" + userId] = true
        
        dbRootRef.updateChildValues(updateObject)
    }
    
    static func unfollow(userId: String, unfollowId: String){
        var updateObject:[String:Any] = [:]
        updateObject["user-following/" + userId + "/" + unfollowId] = NSNull()
        updateObject["user-followers/" + unfollowId + "/" + userId] = NSNull()
        
        dbRootRef.updateChildValues(updateObject)
        
    }
    
    // Follow and unfollow rankings
    static func followRanking(userId: String, city: City, foodId: String){
        // Get my devices
        var updateObject:[String:Any] = [:]
        let dbPath = city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + userId
        let userFollowingPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId
        updateObject["user-following-rankings/" + userFollowingPath] = true
        updateObject["rankings-followers/" + dbPath] = true
        
        // Add the devices (if any)
        SomeApp.dbUserDevices.child(userId).observeSingleEvent(of: .value, with: {deviceSnap in
            if deviceSnap.exists(){
                for child in deviceSnap.children{
                    if let device = child as? DataSnapshot{
                        updateObject["rankings-followers-devices/" + dbPath + "/" + device.key] = device.value
                    }
                }
            }
            // Atomic comit
            dbRootRef.updateChildValues(updateObject)
        })
    }
    
    
    static func unfollowRanking(userId: String, city: City, foodId: String){
        var updateObject:[String:Any] = [:]
        let dbPath = city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + userId
        let userFollowingPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId
        updateObject["user-following-rankings/" + userFollowingPath] = NSNull()
        updateObject["rankings-followers/" + dbPath] = NSNull()
        updateObject["rankings-followers-devices/" + dbPath] = NSNull()
        
        dbRootRef.updateChildValues(updateObject)
    }
    
    // Add a new city to user (country name and state name will be added with functions)
    static func addUserCity(userId: String, city: City, countryName: String, stateName: String){
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key
        let objectToWrite: [String:Any] = ["country": countryName,
                                                 "state": stateName,
                                                 "name": city.name]
        let dbRef = SomeApp.dbUserRankingGeography.child(dbPath)
        dbRef.setValue(objectToWrite)
    }
    
    // Delete a city
    static func deleteUserCity(userId: String, city: City){
        var updateObject:[String:Any] = [:]

        // Get the (ev) rankings in that city
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key
        updateObject["user-rankings/" + dbPath] = NSNull()
        updateObject["user-ranking-geography/" + dbPath] = NSNull()
        updateObject["user-ranking-detail/" + dbPath] = NSNull()
        updateObject["user-ranking-points/" + dbPath] = NSNull()
        
        SomeApp.dbRootRef.updateChildValues(updateObject)
    }
    
    // Report User
    static func reportUser(userId:String, reportedId: String, reason: ReportActions){
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        let objectToWrite:[String:Any] = ["reportedId" : reportedId,
                                         "reason": reason.rawValue,
                                        "timestamp": timestamp]
        let dbRef = SomeApp.dbReportedUsers.child(userId)
        dbRef.setValue(objectToWrite)
    }
    
    // Block user
    static func blockUser(userId:String, blockedUserId: String){
        let dbRef = SomeApp.dbUserBlocked.child(userId)
        dbRef.child(blockedUserId).setValue(true)
    }
    
    // Unblock user
    static func unblockUser(userId:String, blockedUserId: String){
        let dbRef = SomeApp.dbUserBlocked.child(userId)
        dbRef.child(blockedUserId).setValue(NSNull())
    }
    
    // MARK: helper funcs
    static func getDeviceModel() -> String{
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
          guard let value = element.value as? Int8, value != 0 else { return identifier }
          return identifier + String(UnicodeScalar(UInt8(value)))
        }
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
    static func updateRanking(userId:String, city:City, foodId: String, ranking: [Resto]){
        var updateObject:[String:Any] = [:]
        
        // The object to update
        for index in 0..<ranking.count{
            let tmpResto = ranking[index]
            let tmpPosition = index + 1
            let dbPositionPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + tmpResto.key + "/position"
            updateObject[dbPositionPath] = tmpPosition
        }
        // Then write!
        dbUserRankingDetails.updateChildValues(updateObject)
        
    }
    
    // Delete resto
    static func deleteRestoFromRanking(userId: String, city: City, foodId: String, restoId: String){
        
        var updateObject:[String:Any] = [:]
        
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + restoId
        updateObject["user-ranking-detail/" + dbPath] = NSNull()
        updateObject["user-reviews/" + dbPath] = NSNull()
        
        SomeApp.dbRootRef.updateChildValues(updateObject)
    }
    
    // Delete ranking
    static func deleteUserRanking(userId: String, city: City, foodId: String){
        var updateObject:[String:Any] = [:]
        let dbPath = userId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId
        
        updateObject["user-rankings/" + dbPath] = NSNull()
        updateObject["user-ranking-geography/" + dbPath] = NSNull()
        updateObject["user-ranking-detail/" + dbPath] = NSNull()
        updateObject["user-ranking-points/" + dbPath] = NSNull()
        
        SomeApp.dbRootRef.updateChildValues(updateObject)
    }
    
    // Add resto to Ranking : we need to check the model first
    static func addRestoToRanking(userId: String, resto: Resto, mapItem: MKMapItem, forFood:FoodType, foodId: String,city: City){
        let dbPath = city.country + "/" + city.state + "/" + city.key
        
        // A. Check if the resto exists in the resto list
        dbResto.child(dbPath).child(resto.key).observeSingleEvent(of: .value, with: {snapshot in
            
            // If the restorant doesn't exist, we need to create it and add it
            if !snapshot.exists(){
                // Add resto details
                if mapItem.url != nil{ resto.url = mapItem.url! }
                if mapItem.phoneNumber != nil {resto.phoneNumber = mapItem.phoneNumber!}
                if mapItem.placemark.formattedAddress != nil {
                    resto.address = mapItem.placemark.formattedAddress!}
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
        
        // Verify if resto exists in ranking
        dbUserRankingDetails.child(dbPath).observeSingleEvent(of: .value, with: {snapshot in
            //Ranking doesn't exist, create the path with position 1
            if !snapshot.exists(){
                dbUserRankingDetails.child(dbPath).child(resto.key).child("position").setValue(1)
            }
                
            //Ranking exists, verify if resto is there
            else if let value = snapshot.value as? [String: Any]{
                if value[resto.key] == nil {
                    let position = snapshot.childrenCount + 1
                    // Then, add to the ranking
                    dbUserRankingDetails.child(dbPath).child(resto.key).child("position").setValue(position)
                }
            }
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
    
    // MARK: Add/update/Like/Disklike Review
    static func updateUserReview(userid: String, resto: Resto, city: City, foodId: String, text: String){
        let dbPath = userid + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key
        let dbRef = dbUserReviews.child(dbPath)
        
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        let reviewPost:[String:Any] = ["timestamp": timestamp,
                                       "text": text,
                                       "restoname": resto.name]
        dbRef.setValue(reviewPost)
    }
    
    static func reportReview(userid: String, resto: Resto, city: City, foodId: String, text: String, reportReason: String, postTimestamp: Double, reporterId: String){
        let dbPath = reporterId + "/" + userid + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key
        let dbRef = dbUserReportedReviews.child(dbPath)
        
        let reportedTimestamp = NSDate().timeIntervalSince1970 * 1000
        let reportedReview:[String:Any] = ["timestamp": postTimestamp,
                                       "text": text,
                                       "restoname": resto.name,
                                       "reportedtimestamp" : reportedTimestamp,
                                       "reason":reportReason]
        dbRef.setValue(reportedReview)
    }
    
    // Like review
    static func likeReview(userid: String, resto: Resto, city: City, foodId: String, reviewerId: String){
        var updateObject:[String:Any] = [:]
        
        // Add the like + remove the dislike to the resto review path
        let reviewPath = city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key + "/" + reviewerId + "/" + userid
        updateObject["resto-reviews-likes/" + reviewPath] = true
        
        // Add the like + remove the dislike to the user's liked / disliked
        let userLikedPath = userid + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key + "/" + reviewerId
        updateObject["user-liked-reviews/" + userLikedPath] = true
        
        // Add the like + remove the dislike to the user reviews
        let reviewerLikedPath = reviewerId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key + "/" + userid
        updateObject["user-reviews-likes/" + reviewerLikedPath] = true
        
        dbRootRef.updateChildValues(updateObject)
    }
    
    // Dislike review
    static func dislikeReview(userid: String, resto: Resto, city: City, foodId: String, reviewerId: String){
        var updateObject:[String:Any] = [:]
        
        // Add the like + remove the dislike to the resto review path
        let reviewPath = city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key + "/" + reviewerId + "/" + userid
        updateObject["resto-reviews-likes/" + reviewPath] = NSNull()
        
        // Add the like + remove the dislike to the user's liked / disliked
        let userLikedPath = userid + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key + "/" + reviewerId
        updateObject["user-liked-reviews/" + userLikedPath] = NSNull()
        
        // Add the like + remove the dislike to the user reviews
        let reviewerLikedPath = reviewerId + "/" + city.country + "/" + city.state + "/" + city.key + "/" + foodId + "/" + resto.key + "/" + userid
        updateObject["user-reviews-likes/" + reviewerLikedPath] = NSNull()

        dbRootRef.updateChildValues(updateObject)
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
    case NewYum = "newYum"
    case NativeAd = "nativeAd" 
    case FoodzGuruPost = "systemNotification"
}

enum ReportActions:String,CaseIterable{
    case FakeAccount = "Fake Account or Spam"
    case ViolentBehavior = "Violence and Criminal Behavior"
    case HatefulContent = "Harassment, Abusive or Hateful Content"
    case Pornography = "Pornographic or Abusive Material"
    case Disrespectul = "Disrespectful or Offensive"
}


