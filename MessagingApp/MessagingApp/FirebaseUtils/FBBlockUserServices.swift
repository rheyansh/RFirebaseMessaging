//
//  FBBlockUserServices.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class FBBlockUserServices: NSObject {

    class func addToBlockList(user: MAUser, callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            
            let info = [pSenderId: currentUser.uid, pReceiverId: user.userId, pCreatedAt: ServerValue.timestamp()] as [String : Any]
            
            let autoKey = blockedUsersRef.childByAutoId().key
            
            blockedUsersRef.child(autoKey).setValue(info, withCompletionBlock: { (error, databaseReference) in
                
                if let error = error {
                    Debug.log("addToBlockList error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    Debug.log("databaseReference>>  \(databaseReference)")
                    callback?(true, nil)
                }
            })
        }
    }
    
    class func unblock(user: MAUser, callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            
            blockedUsersRef.child(user.parentKey).removeValue(completionBlock: { (error, _) in
                if let error = error {
                    Debug.log("unblock error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    callback?(true, nil)
                }
            })
        }
    }
    
    class func isBlockingExistsWith(user: MAUser, callback: ((CheckBlockExistingResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            var result = CheckBlockExistingResult()

            if !APPDELEGATE.isReachable {
                result.error = FirebaseUtils.netError
                callback?(result)
                return
            }

            let uid = currentUser.uid
            let query = blockedUsersRef.queryOrdered(byChild:  pSenderId).queryEqual(toValue: uid)

            query.observe(.value, with: { (queryResult) in
                
                var isBlocking = false
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    
                    var opponentId = ""
                    
                    if childSnapshot.hasChild(pReceiverId) {
                        opponentId = childSnapshot.childSnapshot(forPath: pReceiverId).value as! String
                    }
                    
                    if opponentId == user.userId {
                        isBlocking = true
                        result.isBlocked = true
                        callback?(result)
                        break
                    }
                }
                
                let query = blockedUsersRef.queryOrdered(byChild:  pReceiverId).queryEqual(toValue: uid)
                query.observe(.value, with: { (queryResult) in
                    
                    for child in queryResult.children {
                        guard let childSnapshot = child as? DataSnapshot else {
                            continue
                        }
                        
                        var opponentId = ""
                        
                        if childSnapshot.hasChild(pSenderId) {
                            opponentId = childSnapshot.childSnapshot(forPath: pSenderId).value as! String
                        }
                        
                        if opponentId == user.userId {
                            isBlocking = true
                            result.isBlocked = true
                            callback?(result)
                            break
                        }
                    }
                    
                    result.isBlocked = isBlocking
                    callback?(result)
                }) { (err) in
                    Debug.log("err>>>  \(err)")
                    result.error = err
                    callback?(result)
                }
            }) { (err) in
                Debug.log("err>>>  \(err)")
                result.error = err
                callback?(result)
            }
        }
    }
    
    class func fetchBlockedUsers(hud: Bool = true, callback: ((SearchUserResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            var result = SearchUserResult()
            
            if !APPDELEGATE.isReachable {
                result.error = FirebaseUtils.netError
                callback?(result)
                return
            }
            
            let uid = currentUser.uid
            let query = blockedUsersRef.queryOrdered(byChild:  pSenderId).queryEqual(toValue: uid)
            
            if hud {
                ProgressHUD.show()
            }
            
            query.observe(.value, with: { (queryResult) in
                
                if hud {
                    ProgressHUD.dismiss()
                }
                
                guard queryResult.childrenCount > 0 else {
                    result.users = []
                    callback?(result)
                    return
                }
                
                var users = [MAUser]()
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    
                    var opponentId = ""
                    
                    if childSnapshot.hasChild(pReceiverId) {
                        opponentId = childSnapshot.childSnapshot(forPath: pReceiverId).value as! String
                    }
                    
                    if opponentId.length == 0 {
                        continue
                    }
                    
                    let lUserRef = usersRef.child(opponentId)
                    
                    lUserRef.observeSingleEvent(of: .value, with: { userSnapshot in
                        let user = MAUser(with: userSnapshot)
                        user.parentKey = childSnapshot.key // this key will be used for deleting the request. technically deleting the node
                        
                        users.append(user)
                        
                        let userCount = UInt(users.count)
                        if userCount == queryResult.childrenCount {
                            
                            if hud {
                                ProgressHUD.dismiss()
                            }
                            
                            result.users = users
                            callback?(result)
                        }
                    })
                }
                
            }) { (err) in
                Debug.log("err>>>  \(err)")
                result.error = err
                callback?(result)
            }
        }
    }
}
