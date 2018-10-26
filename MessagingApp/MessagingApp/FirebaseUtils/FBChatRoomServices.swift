//
//  FBChatRoomServices.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class FBChatRoomServices: NSObject {
    
    class func fetchMyGroups(hud: Bool = true,
                             callback: ((MyGroupResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            var result = MyGroupResult()
            
            let currentUserId =  currentUser.uid
            let searchText = kRoomTypeGroup
            
            let query = chatRoomRef.queryOrdered(byChild:  pRoomType)
            
            if hud {
                ProgressHUD.show()
            }
            
            query.queryStarting(atValue: searchText).queryEnding(atValue: searchText+"\u{f8ff}").observe(.value, with: { (queryResult) in
                
                if hud {
                    ProgressHUD.dismiss()
                }
                
                guard queryResult.childrenCount > 0 else {
                    result.groups = []
                    callback?(result)
                    return
                }
                
                // eliminate group in which I am not a member
                var myGroups = [MAChatRoom]()
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    
                    if childSnapshot.hasChild(pParticipants) {
                        if let participants = childSnapshot.childSnapshot(forPath: pParticipants).value as? Array<String> {
                            if participants.contains(currentUserId) {
                                let group = MAChatRoom(with: childSnapshot)
                                myGroups.append(group)
                            }
                        }
                    }
                }
                
                result.groups = myGroups
                callback?(result)
                
            }) { (err) in
                
                if hud {
                    ProgressHUD.dismiss()
                }
                
                Debug.log("err>>>  \(err)")
                result.error = err
                callback?(result)
            }
        }
    }
    
    class func fetchCommonGroupsWithUser(hud: Bool = true, user: MAUser,
                                         callback: ((MyGroupResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            var result = MyGroupResult()
            
            let currentUserId =  currentUser.uid
            let searchText = kRoomTypeGroup
            
            let query = chatRoomRef.queryOrdered(byChild:  pRoomType)
            
            if hud {
                ProgressHUD.show()
            }
            
            query.queryStarting(atValue: searchText).queryEnding(atValue: searchText+"\u{f8ff}").observe(.value, with: { (queryResult) in
                
                if hud {
                    ProgressHUD.dismiss()
                }
                
                guard queryResult.childrenCount > 0 else {
                    result.groups = []
                    callback?(result)
                    return
                }
                
                // eliminate group in which I am not a member
                var myGroups = [MAChatRoom]()
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    
                    if childSnapshot.hasChild(pParticipants) {
                        if let participants = childSnapshot.childSnapshot(forPath: pParticipants).value as? Array<String> {
                            if participants.contains(currentUserId) && participants.contains(user.userId) {
                                let group = MAChatRoom(with: childSnapshot)
                                myGroups.append(group)
                            }
                        }
                    }
                }
                
                result.groups = myGroups
                callback?(result)
                
            }) { (err) in
                
                if hud {
                    ProgressHUD.dismiss()
                }
                
                Debug.log("err>>>  \(err)")
                result.error = err
                callback?(result)
            }
        }
    }
}
