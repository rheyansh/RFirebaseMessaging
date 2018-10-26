//
//  RBasicUserServices.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class RBasicUserServices: NSObject {

    //MARK:- Public Functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    class func signOut(_ hud: Bool = false, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        
        if hud {
            ServiceHelper.hideAllHuds(false, type: .iLoader)
        }
        
        User.removeForRemoteNotification { (isDone, err) in
            
            if let err = err {
                if hud {
                    ServiceHelper.hideAllHuds(false, type: .iLoader)
                }
                completion(false, err)
            } else {
                
                do {
                    try Auth.auth().signOut()
                    
                    if hud {
                        ServiceHelper.hideAllHuds(true, type: .iLoader)
                    }
                    
                    completion(true, nil)
                } catch let signOutError as NSError {
                    if hud {
                        ServiceHelper.hideAllHuds(false, type: .iLoader)
                    }
                    
                    Debug.log("Error signing out: \(signOutError.localizedDescription)")
                    completion(false, signOutError)
                }
            }
        }
    }
    
    
    class func updateCurrentUser(_ hud: Bool = false, firstName: String, lastName: String, completionBlock: ((_ isSuccess: Bool, _ error: Error?)->())?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                completionBlock?(false, FirebaseUtils.netError)
                return
            }
            
            let searchName = firstName + " " + lastName

            let key =  currentUser.uid
            let userInfo = [pFirstName: firstName, pLastName: lastName, pSearchNameKey: searchName.lowercased()]
            
            if hud {
                ServiceHelper.hideAllHuds(false, type: .iLoader)
            }
            
            usersRef.child(key).updateChildValues(userInfo, withCompletionBlock: { (error, databaseReference) in
                
                if hud {
                    ServiceHelper.hideAllHuds(true, type: .iLoader)
                }

                if let error = error {
                    Debug.log("error>>>   \(String(describing: error))")
                    completionBlock?(false, error)
                } else {
                    Debug.log("databaseReference>>>   \(databaseReference)")
                    completionBlock?(true, nil)
                }
            })
        }
    }
    
    class func updateCurrentUserPushNotificationStatus(value: Bool, completionBlock: ((_ isSuccess: Bool, _ error: Error?)->())?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            let key =  "\(currentUser.uid)/\(pNotificationStatus)"
            
            if let completionBlock = completionBlock {
                
                usersRef.child(key).setValue(value, withCompletionBlock: { (error, databaseReference) in
                    if let error = error {
                        completionBlock(false, error)
                    } else {
                        completionBlock(true, nil)
                    }
                })
            } else {
                usersRef.child(key).setValue(value)
            }
        }
    }
    
    class func updateCurrentUserPassword(_ hud: Bool = true, newPassword: String, completionBlock: ((_ isSuccess: Bool, _ error: Error?)->())?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            if hud {
                ServiceHelper.hideAllHuds(false, type: .iLoader)
            }
            
            currentUser.updatePassword(to: newPassword) { error in
                
                if hud {
                    ServiceHelper.hideAllHuds(true, type: .iLoader)
                }
                
                if let error = error {
                    Debug.log("Error on update current user password:== \(error)")
                    
                    if error.code == 17014 {
                        AlertController.alert(title: error.localizedDescription, message: "", buttons: ["OK"], tapBlock: { (_, _) in
                            APPDELEGATE.logOut()
                        })
                    } else {
                        if let completionBlock = completionBlock {
                            completionBlock(false, error)
                        }
                    }
                } else {
                    Debug.log("Password changed")
                    if let completionBlock = completionBlock {
                        completionBlock(true, error)
                    }
                }
            }
        }
    }
    
    class func getCurrentNotificationStatus(_ userId: String, callBack: ((Bool)->())?) {
        
        let pathRef = usersRef.child(userId).child(pNotificationStatus)
        
        pathRef.observeSingleEvent(of: .value, with: { (snapshot) in
            Debug.log("NotificationStatus:== \(snapshot)")
            
            if let callBack = callBack {
                guard snapshot.exists() else {
                    callBack(false)
                    return
                }
                if let value = snapshot.value as? Bool {
                    callBack(value)
                }
            }
        })
    }
    
    class func muteAudience(_ value: Bool, audienceType: ChatRoomType, audienceId: String, callBack: ((_ isSuccess: Bool, _ error: Error?)->())?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            var audienceNode = muteUsersNode
            
            if audienceType == .roomType_Individual {
                audienceNode = muteUsersNode
            } else if audienceType == .roomType_Group {
                audienceNode = muteGroupsNode
            } else {
                return
            }
            
            let pathRef =  usersRef.child(currentUser.uid).child(muteAudienceNode).child(audienceNode).child(audienceId)
            
            if value {
                let data = ["status": value]
                
                pathRef.updateChildValues(data, withCompletionBlock: { (error, databaseReference) in
                    
                    if let error = error {
                        callBack?(false, error)
                    } else {
                        callBack?(true, nil)
                    }
                })
            } else {
                pathRef.removeValue(completionBlock: { (error, _) in
                    if let error = error {
                        callBack?(false, error)
                    } else {
                        callBack?(true, nil)
                    }
                })
            }
        }
    }
    
    class func getMutedAudience(_ userId: String, callback: ((MutedAudienceResult) -> Void)?) {
        
        let pathRef = usersRef.child(userId).child(muteAudienceNode)
        var result = MutedAudienceResult()
        
        if !APPDELEGATE.isReachable {
            result.error = FirebaseUtils.netError
            callback?(result)
            return
        }
        
        pathRef.observeSingleEvent(of: .value, with: { (queryResult) in
            
            guard queryResult.exists() else {
                result.mutedGroupsIds = []
                result.mutedUsersIds = []
                callback?(result)
                return
            }
            
            var mutedUsersArray = [String]()
            var mutedGroupsArray = [String]()

            if let queryDict = queryResult.value as? Dictionary<String, AnyObject> {
                if let mutedUsers = queryDict[muteUsersNode] as? Dictionary<String, AnyObject> {
                    for key in mutedUsers.keys {
                        mutedUsersArray.append(key)
                    }
                }
            }
            
            if let queryDict = queryResult.value as? Dictionary<String, AnyObject> {
                if let mutedGroups = queryDict[muteGroupsNode] as? Dictionary<String, AnyObject> {
                    for key in mutedGroups.keys {
                        mutedGroupsArray.append(key)
                    }
                }
            }
            
            Debug.log("mutedUsersArray>>>  \(mutedUsersArray)")
            Debug.log("mutedUsersArray>>>  \(mutedGroupsArray)")

            result.mutedGroupsIds = mutedGroupsArray
            result.mutedUsersIds = mutedUsersArray
            callback?(result)
        })
    }
}

extension User {
    
    func fetch(_ hud: Bool = false, completionBlock: ((_ isSuccess: Bool, _ modalUser: MAUser?, _ error: Error?)->())?) {
        
        if !FirebaseUtils.isReachable {
            return
        }
        
        if hud {
            ProgressHUD.show()
        }
        
        let path = self.uid
        usersRef.child(path).observeSingleEvent(of: .value, with: { (data) in
            Debug.log("Current user snapshot.value:== \(data)")
            if let completionBlock = completionBlock {
                let user = MAUser(with: data)
                completionBlock(true, user, nil)
            }
        })
    }
    
    // Add remote notification info

    func updateForRemoteNotification() {
        
        // needs to update the structure of notification
        
        let id = self.uid
        
        let remoteNotificationInfo = [pDeviceToken: RemoteNotificationHandler.FCMToken,
                    pDeviceType: kDeviceType,
                    pUserId: id,
                    pDeviceName: RemoteNotificationHandler.deviceName,
                    pLastUpdatedAt: ServerValue.timestamp()] as [String : Any]
        
        let notificationKey = userRemoteNotificationRef.childByAutoId().key
        
        userRemoteNotificationRef.child(RemoteNotificationHandler.FCMToken).child(notificationKey).updateChildValues(remoteNotificationInfo, withCompletionBlock: { (error, reference) in
            
            if let error = error {
                Debug.log("userRemoteNotificationRef Update child error>>  \(String(describing: error))")
            } else {
                let data = ["notificationKey": notificationKey]
            usersRef.child(id).child(remoteNotificationNode).child(RemoteNotificationHandler.FCMToken).updateChildValues(data)
            }
        })
    }
    
    class func removeForRemoteNotification(callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            usersRef.child(currentUser.uid).child(remoteNotificationNode).child(RemoteNotificationHandler.FCMToken).removeValue(completionBlock: { (error, _) in
                if let error = error {
                    Debug.log("deleteFriendNode error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    callback?(true, nil)
                }
            })
        }
    }
    
}

