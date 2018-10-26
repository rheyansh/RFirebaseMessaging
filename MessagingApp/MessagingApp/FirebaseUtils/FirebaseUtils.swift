//
//  FirebaseUtils.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class FirebaseUtils: NSObject {
    
    class var isReachable: Bool {
        
        if !APPDELEGATE.isReachable {
            
            AlertController.alert(title: "Connection Error!", message: "Internet connection appears to be offline. Please check your internet connection.")

            return false
        }
        
        return true
    }
    
    class var netError: OurErrorProtocol {
        
        return CustomError(title: "Connection Error!", description: "Internet connection appears to be offline. Please check your internet connection.", code: 9999)
    }
    
    class var unKnownError: OurErrorProtocol {
        
        return CustomError(title: "Error!", description: "Unknown error, please try again later.", code: 9999)
    }
    
    class func currentUser(completionBlock: ((User)->())?) {
        
        // check if user is already logged in. If logged in go inside the app directly
        
        if let user = Auth.auth().currentUser {
            if let block = completionBlock {
                block(user)
            }
        } else {
            // No User is signed in. Show user the login screen
            let errorTitle = "Authentication Error!"
            let message = "Please login and try again."
            AlertController.alert(title: errorTitle, message: message)
            APPDELEGATE.moveToLogin()
        }
    }
}

struct SearchUserResult {
    
    var users = [MAUser]()
    var error: Error?
    var totalChildrenCount: UInt?
}

struct NodeSearchResult {
    
    var snapshots = [DataSnapshot]()
    var error: Error?
    var totalChildrenCount: UInt?
}

struct MediaUploadResult {
    
    var isSuccess = false
    var error: Error?
    var mediaUrl: URL?
}

struct MyGroupResult {
    
    var groups = [MAChatRoom]()
    var error: Error?
}

struct CheckBlockExistingResult {
    
    var isBlocked: Bool?
    var error: Error?
}

struct FriendShipStatusResult {
    
    var friendNodeKey: String?
    var friendshipStatus: FriendshipStatus?
    var error: Error?
}

struct SendFriendRequestResult {
    
    var friendNodeKey: String?
    var isSuccess = false
    var error: Error?
}

struct SharedMediaResult {
    
    var mediaMessages = [Message]()
    var error: Error?
}

struct MutedAudienceResult {
    
    var mutedGroupsIds = [String]()
    var mutedUsersIds = [String]()
    var error: Error?
}

