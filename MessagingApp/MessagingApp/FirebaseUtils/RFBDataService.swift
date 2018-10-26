//
//  RFBDataService.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class RFBDataService: NSObject {
    
    class func searchUsers(hud: Bool = true,
                           text: String,
                            callback: ((SearchUserResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            var result = SearchUserResult()
            let searchText = text.lowercased()
            
            let currentUserId =  currentUser.uid
            
            let query = usersRef.queryOrdered(byChild:  pSearchNameKey)
            
            if hud {
                ProgressHUD.show()
            }
            
            query.queryStarting(atValue: searchText).queryEnding(atValue: searchText+"\u{f8ff}").observe(.value, with: { (snapshot) in
                
                if hud {
                    ProgressHUD.dismiss()
                }
                
                guard snapshot.childrenCount > 0 else {
                    result.users = []
                    callback?(result)
                    return
                }
                
                // fetch friend request sent, received and my friends and remove from search results
                FBFriendsServices.getUserIdsToRevoveFromsearchUsers(currentUserId, callback: { (usersIdsToRemoved) in
                    
                    //Debug.log("data>>>  \(snapshot.children.allObjects)")
                    var allUsers = [MAUser]()
                    
                    if let snapshots = snapshot.children.allObjects as? [DataSnapshot] {
                        for snap in snapshots {
                            let userInfo = MAUser(with: snap)
                            if usersIdsToRemoved.contains(userInfo.userId) {
                                //do not add and continue
                                continue
                            }
                            allUsers.append(userInfo)
                        }
                    }
                    result.users = allUsers
                    
                    for snap in allUsers {
                        Debug.log("displayName>>>  \(snap.displayName)")
                    }
                    
                    callback?(result)
                })
                
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

extension UIImage {
    
    func uploadGroupAvatar(_ hud: Bool = true, groupId: String, track: ((Progress?) -> Void)?, callback: ((MediaUploadResult) -> Void)?) {
        
        var result = MediaUploadResult()

        uploadImage(hud, storageReference: groupAvatarRef, track: { (progress) in
            track?(progress)
        }) { (uploadResult) in
            
            if uploadResult.isSuccess {
                let key =  "\(groupId)/\(pAvatar_url)"
                if let mediaUrl = uploadResult.mediaUrl {
                    result.mediaUrl = mediaUrl
                    chatRoomRef.child(key).setValue(mediaUrl.absoluteString)
                }
            }
            result.isSuccess = uploadResult.isSuccess
            result.error = uploadResult.error
            callback?(result)
        }
    }
    
    func currentUserAvatarUpload(_ hud: Bool = true, track: ((Progress?) -> Void)?, callback: ((MediaUploadResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            var result = MediaUploadResult()
            
            if !APPDELEGATE.isReachable {
                result.error = FirebaseUtils.netError
                callback?(result)
                return
            }
            
            if let imageData = self.toData(compressionQuality: 0.1) {
                
                if hud {
                    ProgressHUD.show()
                }
                
                let uid = currentUser.uid
                
                let key = Date.timeIntervalSinceReferenceDate * 1000
                let imagePath = "\(uid)/\(key).jpg"
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let task = userAvatarRef.child(imagePath).putData(imageData, metadata: metadata, completion: { metadata, error in
                    
                    if hud {
                        ProgressHUD.dismiss()
                    }
                    
                    guard error == nil else {
                        Debug.log("Failed on current user avatar upload:== \(String(describing: error))")
                        
                        result.error = error
                        callback?(result)
                        return
                    }
                    
                    guard let downloadURLString = metadata?.downloadURL()?.absoluteString else {
                        Debug.log("Failed on current user avatar upload:== Metadata or downlod url nil")
                        
                        result.error = CustomError(title: "", description: "Avatar URL does not exist", code: 9999)
                        callback?(result)
                        return
                    }
                    
                    let key =  "\(currentUser.uid)/\(pAvatar_url)"
                    usersRef.child(key).setValue(downloadURLString)
                    result.mediaUrl = metadata?.downloadURL()
                    result.isSuccess = true
                    callback?(result)
                })
                
                task.observe(.progress) { (snapshot) in
                    track!(snapshot.progress)
                }
            } else {
                result.error = CustomError(title: "", description: "Image data does not exist", code: 9999)
                callback?(result)
            }
        }
    }
    
    func uploadImage(_ hud: Bool = true,
                     storageReference: StorageReference,
                     track: ((Progress?) -> Void)?,
                     callback: ((MediaUploadResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            var result = MediaUploadResult()
            
            if !APPDELEGATE.isReachable {
                result.error = FirebaseUtils.netError
                callback?(result)
                return
            }
            
            if let imageData = self.toData(compressionQuality: 0.1) {
                
                if hud {
                    ProgressHUD.show()
                }
                
                let uid = currentUser.uid
                
                let key = Date.timeIntervalSinceReferenceDate * 1000
                let imagePath = "\(uid)/\(key).jpg"
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let task = storageReference.child(imagePath).putData(imageData, metadata: metadata, completion: { metadata, error in
                    
                    if hud {
                        ProgressHUD.dismiss()
                    }
                    
                    guard error == nil else {
                        Debug.log("Failed on current user avatar upload:== \(String(describing: error))")
                        
                        result.error = error
                        callback?(result)
                        return
                    }
                    
                    guard let downloadURLString = metadata?.downloadURL()?.absoluteString else {
                        Debug.log("Failed on current user avatar upload:== Metadata or downlod url nil")
                        
                        result.error = CustomError(title: "", description: "Avatar URL does not exist", code: 9999)
                        callback?(result)
                        return
                    }
                    
                    let key =  "\(currentUser.uid)/\(pAvatar_url)"
                    usersRef.child(key).setValue(downloadURLString)
                    result.mediaUrl = metadata?.downloadURL()
                    result.isSuccess = true
                    callback?(result)
                })
                
                task.observe(.progress) { (snapshot) in
                    track!(snapshot.progress)
                }
            } else {
                result.error = CustomError(title: "", description: "Image data does not exist", code: 9999)
                callback?(result)
            }
        }
    }
}

