//
//  FBFriendsServices.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

enum FriendshipStatus {
    case friendshipStatusRequestsNone, friendshipStatusRequestsSent, friendshipStatusRequestsReceived, friendshipStatusAccepted
}

class FBFriendsServices: NSObject {
    
    class func sendFriendRequest(user: MAUser, callback: ((SendFriendRequestResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            var result = SendFriendRequestResult()

            if !APPDELEGATE.isReachable {
                result.error = FirebaseUtils.netError
                callback?(result)
                return
            }
            
            let findSentRequestAtSender = "\(currentUser.uid)/\(kFindSentRequestAtSender)"
            let findPendingRequestAtSender = "\(currentUser.uid)/\(kFindPendingRequestAtSender)"
            let findSentRequestAtReceiver = "\(user.userId)/\(kFindSentRequestAtReceiver)"
            let findPendingRequestAtReceiver = "\(user.userId)/\(kFindPendingRequestAtReceiver)"

            let info = [pSenderId: currentUser.uid,
                        pReceiverId: user.userId,
                        pFriendshipStatus: kFriendshipStatusRequestSent,
                        pFindSentRequestAtSender:findSentRequestAtSender,
                        pFindPendingRequestAtSender:findPendingRequestAtSender,
                        pFindSentRequestAtReceiver:findSentRequestAtReceiver,
                        pFindPendingRequestAtReceiver:findPendingRequestAtReceiver,
                        pCreatedAt: ServerValue.timestamp(),
                        pLastUpdatedAt: ServerValue.timestamp()] as [String : Any]
            
            Debug.log("info>>  \(info.debugDescription)")

            
            let autoKey = friendsNodeRef.childByAutoId().key
            
            friendsNodeRef.child(autoKey).setValue(info, withCompletionBlock: { (error, databaseReference) in
                
                if let error = error {
                    Debug.log("sendFriendRequest error>>  \(String(describing: error))")
                    result.error = error
                    callback?(result)
                } else {
                    Debug.log("sendFriendRequest databaseReference>>  \(databaseReference)")
                    FCMNotificationHandler.fireNotificationForFriendRequestSent(user)
                    result.isSuccess = true
                    result.friendNodeKey = autoKey
                    callback?(result)
                }
            })
        }
    }
    
    class func rejectFriendRequest(fromUser: MAUser, callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        self.deleteFriendNode(nodeKey: fromUser.parentKey, callback: callback)
    }
    
    class func deleteFriendNode(nodeKey: String, callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            
            friendsNodeRef.child(nodeKey).removeValue(completionBlock: { (error, _) in
                if let error = error {
                    Debug.log("deleteFriendNode error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    callback?(true, nil)
                }
            })
        }
    }
    
    class func acceptFriendRequest(fromUser: MAUser, callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        self.acceptFriendRequestViaNode(nodeKey: fromUser.parentKey, fromUserId: fromUser.userId) { (done, err) in
            
            if done {
                FCMNotificationHandler.fireNotificationForFriendRequestAccepted(fromUser)
            }
            
            if let callback = callback {
                callback(done,err)
            }
        }
    }
    
    class func acceptFriendRequestViaNode(nodeKey: String, fromUserId: String, callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            
            let friendKeyNode = friendsNodeRef.child(nodeKey)
            
            let findSentRequestAtSender = "\(currentUser.uid)/\(kFriendshipStatusAccepted)"
            let findPendingRequestAtSender = "\(currentUser.uid)/\(kFriendshipStatusAccepted)"
            let findSentRequestAtReceiver = "\(fromUserId)/\(kFriendshipStatusAccepted)"
            let findPendingRequestAtReceiver = "\(fromUserId)/\(kFriendshipStatusAccepted)"
            
            let friendshipStatus = "\(currentUser.uid)_\(kFriendshipStatusAccepted)/\(fromUserId)_\(kFriendshipStatusAccepted)" // for finding my friend list
            
            let updatedStatusInfo = [pFriendshipStatus: friendshipStatus,
                                     pFindSentRequestAtSender:findSentRequestAtSender,
                                     pFindPendingRequestAtSender:findPendingRequestAtSender,
                                     pFindSentRequestAtReceiver:findSentRequestAtReceiver,
                                     pFindPendingRequestAtReceiver:findPendingRequestAtReceiver,
                                     pLastUpdatedAt: ServerValue.timestamp()
                ] as [String : Any]
            
            friendKeyNode.updateChildValues(updatedStatusInfo, withCompletionBlock: { (error, databaseReference) in
                
                if let error = error {
                    Debug.log("acceptFriendRequest error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    callback?(true, nil)
                }
            })
        }
    }
    
    class func fetchFriends(hud: Bool = true,
                            friendshipStatus: FriendshipStatus,
                            callback: ((SearchUserResult) -> Void)?) {
        
        Debug.log("Initialing for friendshipStatus>> \(friendshipStatus)")

        if friendshipStatus == .friendshipStatusAccepted {
            self.fetchMyFriends(hud: hud, callback: callback)
        } else if friendshipStatus == .friendshipStatusRequestsSent
            || friendshipStatus == .friendshipStatusRequestsReceived {
            self.fetchPendingFriends(friendshipStatus: friendshipStatus, callback: callback)
        }
    }
    
    private class func fetchPendingFriends(hud: Bool = true,
                            friendshipStatus: FriendshipStatus,
                                callback: ((SearchUserResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            let uid = currentUser.uid
            
            var result = SearchUserResult()
            result.totalChildrenCount = 0

            var query: DatabaseQuery?
            
            if friendshipStatus == .friendshipStatusRequestsSent {
                
                let findSentRequestAtSender = "\(uid)/\(kFindSentRequestAtSender)"
                query = friendsNodeRef.queryOrdered(byChild:  pFindSentRequestAtSender).queryEqual(toValue: findSentRequestAtSender)
            } else if friendshipStatus == .friendshipStatusRequestsReceived {
                let findPendingRequestAtReceiver = "\(uid)/\(kFindPendingRequestAtReceiver)"
                query = friendsNodeRef.queryOrdered(byChild:  pFindPendingRequestAtReceiver).queryEqual(toValue: findPendingRequestAtReceiver)
            }
            
            if hud {
                ProgressHUD.show()
            }
            
            query!.observe(.value, with: { (queryResult) in
                
                guard queryResult.exists(), queryResult.childrenCount > 0 else {
                    
                    if hud {
                        ProgressHUD.dismiss()
                    }
                    
                    result.users = [MAUser]()
                    callback?(result)
                    return
                }
                
                result.totalChildrenCount = queryResult.childrenCount
                
                var users = [MAUser]()
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    
                    var friendId = ""
                    
                    if friendshipStatus == .friendshipStatusRequestsSent {
                        
                        if childSnapshot.hasChild(pReceiverId) {
                            friendId = childSnapshot.childSnapshot(forPath: pReceiverId).value as! String
                        }
                    } else if friendshipStatus == .friendshipStatusRequestsReceived {
                        if childSnapshot.hasChild(pSenderId) {
                            friendId = childSnapshot.childSnapshot(forPath: pSenderId).value as! String
                        }
                    }
                    
                    let lUserRef = usersRef.child(friendId)

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
                    }) /*{ (err) in
                        
                        if hud {
                            ProgressHUD.dismiss()
                        }
                        
                        Debug.log("err>>>  \(err)")
                        result.error = err
                        callback?(result)
                    }*/
                }
                
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
    
    class func fetchMyFriends(hud: Bool = true,
                                      callback: ((SearchUserResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            let uid = currentUser.uid
            var result = SearchUserResult()
            result.totalChildrenCount = 0
            
            if hud {
                ProgressHUD.show()
            }
            
            var snapshots = [DataSnapshot]()
            
            self.getPendingRequestAccpetedAtSenderSide(uid, callback: { (nodeSearchResult1) in
                snapshots.append(contentsOf: nodeSearchResult1.snapshots)
                
                self.getPendingRequestAccpetedAtReceiverSide(uid, callback: { (nodeSearchResult2) in
                    snapshots.append(contentsOf: nodeSearchResult2.snapshots)

                    if snapshots.count == 0 {
                        if hud {
                            ProgressHUD.dismiss()
                        }
                        
                        result.users = []
                        callback?(result)
                    }
                    
                    result.totalChildrenCount = UInt(snapshots.count)
                    
                    var users = [MAUser]()
                    var childSnapshotKey = [String]()

                    for child in snapshots {
                        let childSnapshot = child
                        
                        if childSnapshotKey.contains(childSnapshot.key) {
                            // already loaded ignore and continue for next
                            continue
                        }

                        var friendId = ""
                        var senderId = ""
                        var receiverId = ""
                        
                        if childSnapshot.hasChild(pSenderId) {
                            senderId = childSnapshot.childSnapshot(forPath: pSenderId).value as! String
                        }
                        
                        if childSnapshot.hasChild(pReceiverId) {
                            receiverId = childSnapshot.childSnapshot(forPath: pReceiverId).value as! String
                        }
                        
                        if uid == senderId {
                            friendId = receiverId
                        } else if uid == receiverId {
                            friendId = senderId
                        }
                        
                        if friendId.length == 0 {
                            continue
                        }
                        
                        childSnapshotKey.append(childSnapshot.key)

                        let lUserRef = usersRef.child(friendId)
                        
                        lUserRef.observeSingleEvent(of: .value, with: { userSnapshot in
                            let user = MAUser(with: userSnapshot)
                            user.parentKey = childSnapshot.key // this key will be used for deleting the request. technically deleting the node
                            
                            users.append(user)
                            
                            let userCount = UInt(users.count)

                            if userCount == childSnapshotKey.count {
                                
                                if hud {
                                    ProgressHUD.dismiss()
                                }
                                
                                result.users = users
                                callback?(result)
                            }
                        })
                    }
                })
            })
            
        }
    }
    
    private class func getPendingRequestAccpetedAtReceiverSide(_ uid: String,
                                      callback: ((NodeSearchResult) -> Void)?) {
        
            var result = NodeSearchResult()
            result.totalChildrenCount = 0
            
            let query = friendsNodeRef.queryOrdered(byChild:  pFindPendingRequestAtReceiver)
            let searchTextToGetFriends = "\(uid)/\(kFriendshipStatusAccepted)"
        
            query.queryStarting(atValue: searchTextToGetFriends).queryEnding(atValue: searchTextToGetFriends+"\u{f8ff}").observe(.value, with: { (queryResult) in
                
                guard queryResult.exists(), queryResult.childrenCount > 0 else {
                    result.snapshots = [DataSnapshot]()
                    callback?(result)
                    return
                }
                
                result.totalChildrenCount = queryResult.childrenCount
                
                var snapshots = [DataSnapshot]()
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    snapshots.append(childSnapshot)
                }
                result.snapshots = snapshots

                callback?(result)
            }) { (err) in
                result.error = err
                callback?(result)
            }
    }
    
    private class func getPendingRequestAccpetedAtSenderSide(_ uid: String,
                                                               callback: ((NodeSearchResult) -> Void)?) {
        
        var result = NodeSearchResult()
        result.totalChildrenCount = 0
        
        let query = friendsNodeRef.queryOrdered(byChild:  pFindPendingRequestAtSender)
        let searchTextToGetFriends = "\(uid)/\(kFriendshipStatusAccepted)"
        
        query.queryStarting(atValue: searchTextToGetFriends).queryEnding(atValue: searchTextToGetFriends+"\u{f8ff}").observe(.value, with: { (queryResult) in
            
            guard queryResult.exists(), queryResult.childrenCount > 0 else {
                result.snapshots = [DataSnapshot]()
                callback?(result)
                return
            }
            
            result.totalChildrenCount = queryResult.childrenCount
            var snapshots = [DataSnapshot]()
            
            for child in queryResult.children {
                guard let childSnapshot = child as? DataSnapshot else {
                    continue
                }
                snapshots.append(childSnapshot)
            }
            result.snapshots = snapshots
            
            callback?(result)
        }) { (err) in
            result.error = err
            callback?(result)
        }
    }
    
    class func getUserIdsToRevoveFromsearchUsers(_ uid: String, callback: ((_ ids: Array<String>) -> Void)?) {
        
        var uIds = [String]()
        uIds.append(uid)
        
        self.fetchUserIdsToISentRequest(uid) { (iSentArray) in
            uIds.append(contentsOf: iSentArray)
            self.fetchUserIdsToIReceivedRequest(uid) { (iReceivedArray) in
                uIds.append(contentsOf: iReceivedArray)
                self.fetchUserIdsBlockedMe(uid) { (blockedMeArray) in
                    uIds.append(contentsOf: blockedMeArray)
                    self.fetchUserIdsIBlockedTo(uid) { (iBlockArray) in
                        uIds.append(contentsOf: iBlockArray)
                        callback?(uIds)
                    }
                }
            }
        }
    }
    
    private class func fetchUserIdsToISentRequest(_ uid: String, callback: ((_ ids: Array<String>) -> Void)?) {
        
        let query = friendsNodeRef.queryOrdered(byChild:  pSenderId).queryEqual(toValue: uid)
        query.observe(.value, with: { (queryResult) in
            guard queryResult.exists(), queryResult.childrenCount > 0 else {
                callback?([])
                return
            }
            var uIds = [String]()
            for child in queryResult.children {
                guard let childSnapshot = child as? DataSnapshot else {
                    continue
                }
                if childSnapshot.hasChild(pReceiverId) {
                    let receiverId = childSnapshot.childSnapshot(forPath: pReceiverId).value as! String
                    uIds.append(receiverId)
                }
            }
            
            callback?(uIds)
        }) { (err) in
            callback?([])
        }
    }
    
    private class func fetchUserIdsToIReceivedRequest(_ uid: String, callback: ((_ ids: Array<String>) -> Void)?) {
        
        let query = friendsNodeRef.queryOrdered(byChild:  pReceiverId).queryEqual(toValue: uid)
        query.observe(.value, with: { (queryResult) in
            guard queryResult.exists(), queryResult.childrenCount > 0 else {
                callback?([])
                return
            }
            var uIds = [String]()
            for child in queryResult.children {
                guard let childSnapshot = child as? DataSnapshot else {
                    continue
                }
                if childSnapshot.hasChild(pSenderId) {
                    let senderId = childSnapshot.childSnapshot(forPath: pSenderId).value as! String
                    uIds.append(senderId)
                }
            }
            
            callback?(uIds)
        }) { (err) in
            callback?([])
        }
    }
    
    private class func fetchUserIdsBlockedMe(_ uid: String, callback: ((_ ids: Array<String>) -> Void)?) {
        
        let query = blockedUsersRef.queryOrdered(byChild:  pReceiverId).queryEqual(toValue: uid)
        query.observe(.value, with: { (queryResult) in
            guard queryResult.exists(), queryResult.childrenCount > 0 else {
                callback?([])
                return
            }
            var uIds = [String]()
            for child in queryResult.children {
                guard let childSnapshot = child as? DataSnapshot else {
                    continue
                }
                if childSnapshot.hasChild(pSenderId) {
                    let senderId = childSnapshot.childSnapshot(forPath: pSenderId).value as! String
                    uIds.append(senderId)
                }
            }
            
            callback?(uIds)
        }) { (err) in
            callback?([])
        }
    }
    
    private class func fetchUserIdsIBlockedTo(_ uid: String, callback: ((_ ids: Array<String>) -> Void)?) {
        
        let query = blockedUsersRef.queryOrdered(byChild:  pSenderId).queryEqual(toValue: uid)
        query.observe(.value, with: { (queryResult) in
            guard queryResult.exists(), queryResult.childrenCount > 0 else {
                callback?([])
                return
            }
            var uIds = [String]()
            for child in queryResult.children {
                guard let childSnapshot = child as? DataSnapshot else {
                    continue
                }
                if childSnapshot.hasChild(pReceiverId) {
                    let senderId = childSnapshot.childSnapshot(forPath: pReceiverId).value as! String
                    uIds.append(senderId)
                }
            }
            
            callback?(uIds)
        }) { (err) in
            callback?([])
        }
    }
    
    class func getFriendShipStatusWith(user: MAUser, callback: ((FriendShipStatusResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            var result = FriendShipStatusResult()
            
            if !APPDELEGATE.isReachable {
                result.error = FirebaseUtils.netError
                callback?(result)
                return
            }
            
            let uid = currentUser.uid
            let query = friendsNodeRef.queryOrdered(byChild:  pSenderId).queryEqual(toValue: uid)
            
            query.observe(.value, with: { (queryResult) in
                
                var fStatus: FriendshipStatus = .friendshipStatusRequestsNone
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    
                    var opponentId = ""
                    
                    if childSnapshot.hasChild(pReceiverId) {
                        opponentId = childSnapshot.childSnapshot(forPath: pReceiverId).value as! String
                    }
                    
                    if opponentId == user.userId {
                        
                        if childSnapshot.hasChild(pFriendshipStatus) {
                            let friendshipStatusString = childSnapshot.childSnapshot(forPath: pFriendshipStatus).value as! String
                            
                            if friendshipStatusString == kFriendshipStatusRequestSent {
                                fStatus = .friendshipStatusRequestsSent
                            } else if friendshipStatusString.contains(kFriendshipStatusAccepted) {
                                fStatus = .friendshipStatusAccepted
                            }
                            
                            if fStatus == .friendshipStatusRequestsSent || fStatus == .friendshipStatusAccepted {
                                result.friendshipStatus = fStatus
                                result.friendNodeKey = childSnapshot.key
                                callback?(result)
                                break
                            }
                        }
                    }
                }
                
                let query = friendsNodeRef.queryOrdered(byChild:  pReceiverId).queryEqual(toValue: uid)
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
                            
                            if childSnapshot.hasChild(pFriendshipStatus) {
                                let friendshipStatusString = childSnapshot.childSnapshot(forPath: pFriendshipStatus).value as! String
                                
                                if friendshipStatusString == kFriendshipStatusRequestSent {
                                    fStatus = .friendshipStatusRequestsReceived
                                } else if friendshipStatusString.contains(kFriendshipStatusAccepted) {
                                    fStatus = .friendshipStatusAccepted
                                }
                                
                                if fStatus == .friendshipStatusRequestsReceived || fStatus == .friendshipStatusAccepted {
                                    result.friendshipStatus = fStatus
                                    result.friendNodeKey = childSnapshot.key
                                    callback?(result)
                                    break
                                }
                            }
                        }
                    }
                    
                    result.friendshipStatus = fStatus
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
}

