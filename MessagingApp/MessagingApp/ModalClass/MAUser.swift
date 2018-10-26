//
//  MAUser.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class MAUser: SnapshotParser {
    
    var userId: String
    var userName: String
    var firstName: String
    var lastName: String
    var email: String
    var avatarUrl: String
    var notification: Bool
    var parentKey: String
    var conversationIds: Array<String>
    var conversationPartialInfo: Array<ConversationPartialInfo>
    var deviceTokens: Array<String>

    var password: String // only for sign up
    var confirmPassword: String //only for sign up
    var selectionStatus: Bool = false // only for temporary use
    
    var fullName: String {
        get {
            return "\(firstName) \(lastName)"
        }
    }
    
    var displayName: String {
        get {
            if !userName.isEmpty {
                return userName
            } else {
                return firstName
            }
        }
    }
    
    init() {
        parentKey = ""
        userId = ""
        userName = ""
        firstName = ""
        lastName = ""
        email = ""
        avatarUrl = ""
        conversationIds = []
        notification = true
        
        password = ""
        confirmPassword = ""
        selectionStatus = false
        conversationPartialInfo = []
        deviceTokens = []
    }
        
    convenience required init(with snapshot: DataSnapshot, exception: String...) {
        self.init()
        
        parentKey = snapshot.key
        
        if snapshot.hasChild(pUserId) && !exception.contains(pUserId) {
            userId = snapshot.childSnapshot(forPath: pUserId).value as! String
        }
        
        if snapshot.hasChild(pFirstName) && !exception.contains(pFirstName) {
            firstName = snapshot.childSnapshot(forPath: pFirstName).value as! String
        }
        
        if snapshot.hasChild(pLastName) && !exception.contains(pLastName) {
            lastName = snapshot.childSnapshot(forPath: pLastName).value as! String
        }
        
        if snapshot.hasChild(pEmail) && !exception.contains(pEmail) {
            email = snapshot.childSnapshot(forPath: pEmail).value as! String
        }
        
        if snapshot.hasChild(pUserName) && !exception.contains(pUserName) {
            userName = snapshot.childSnapshot(forPath: pUserName).value as! String
        }
        
        if snapshot.hasChild(pAvatar_url) && !exception.contains(pAvatar_url) {
            avatarUrl = snapshot.childSnapshot(forPath: pAvatar_url).value as! String
        }
        
        if snapshot.hasChild(pNotificationStatus) && !exception.contains(pNotificationStatus) {
            notification = snapshot.childSnapshot(forPath: pNotificationStatus).value as! Bool
        }
        
        if snapshot.hasChild(conversationsNode) && !exception.contains(conversationsNode) {
            if let conversationNodeValue = snapshot.childSnapshot(forPath: conversationsNode).value as? Dictionary<String, AnyObject> {
                for key in conversationNodeValue.keys {
                    conversationIds.append(key)
                }
                var conPartialInfo = [ConversationPartialInfo]()
                for obj in conversationNodeValue.values {
                    if let obj = obj as? Dictionary<String, AnyObject> {
                        let conId = "\(obj.validatedValue("location", expected: "" as AnyObject))"
                        let mediaSearchKey = "\(obj.validatedValue("mediaSearchKey", expected: "" as AnyObject))"
                        conPartialInfo.append(ConversationPartialInfo(conId, mediaSearchKey))
                    }
                }
                conversationPartialInfo = conPartialInfo
            }
        }
        
        if snapshot.hasChild(remoteNotificationNode) && !exception.contains(remoteNotificationNode) {
            if let remoteNotificationNodeValue = snapshot.childSnapshot(forPath: remoteNotificationNode).value as? Dictionary<String, AnyObject> {
                for key in remoteNotificationNodeValue.keys {
                    deviceTokens.append(key)
                }
            }
        }
    }
}

extension MAUser {
    
    func register(callback: ((CreateUserResult) -> Void)?) {
        
        ProgressHUD.show()
        var result = CreateUserResult()
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            ProgressHUD.dismiss()

            if let error = error {
                result.error = error
                callback?(result)
                AlertController.alert(title: error.localizedDescription)
            } else {
                
                guard let authUser = user else {
                    Debug.log("Authenticated user not found.")
                    AlertController.alert(title: "Authenticated user not found.")
                    result.error = CustomError(title: "", description: "Authenticated user not found.", code: 401)
                    callback?(result)
                    return
                }
                
                let id = authUser.uid
                
                let searchName = self.firstName + " " + self.lastName
                
                let userInfo = [pFirstName: self.firstName, pLastName: self.lastName, pUserId: id, pEmail: self.email, pNotificationStatus: true, pUserName: self.email, pSearchNameKey: searchName.lowercased(), pAvatar_url: ""] as [String : Any]
                
                usersRef.child(id).setValue(userInfo, withCompletionBlock: { (error, databaseReference) in
                    if let error = error {
                        Debug.log("userRemoteNotificationRef Update child error>>  \(String(describing: error))")
                    } else {
                        authUser.updateForRemoteNotification()
                    }
                })
                
                result.isSuccess = true
                result.user = authUser
                callback?(result)
            }
        }
    }
    
    func getSharedMediaWithCurrentUser(hud: Bool = true,
                        mediaType: SharedMediaType,
                        callback: ((SharedMediaResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            var conversationId = ""
            let currentUserId =  currentUser.uid

            let userToId = "\(currentUserId)_\(self.userId)"
            let userToIdReverse = "\(self.userId)_\(currentUserId)"

            let conInfoArray = self.conversationPartialInfo.filter({ return (($0.mediaSearcheKey == userToId) || ($0.mediaSearcheKey == userToIdReverse))})
            
            if let conInfo = conInfoArray.first {
                conversationId = conInfo.conversationId
            }
            
            if conversationId.length == 0 {
                return
            }
            
            Debug.log("conversationId>>  \(conversationId)")
            var result = SharedMediaResult()
            var searchText = "photo"
            if mediaType == .mediaTypeVideo {
                 searchText = "video"
            }
            let query = conversationsRef.child(conversationId).queryOrdered(byChild:  "type")
            
            if hud {
                ProgressHUD.show()
            }
            
            query.queryStarting(atValue: searchText).queryEnding(atValue: searchText+"\u{f8ff}").observe(.value, with: { (queryResult) in
                
                if hud {
                    ProgressHUD.dismiss()
                }
                
                guard queryResult.childrenCount > 0 else {
                    result.mediaMessages = []
                    callback?(result)
                    return
                }
                
                // eliminate group in which I am not a member
                var messages = [Message]()
                
                for child in queryResult.children {
                    guard let childSnapshot = child as? DataSnapshot else {
                        continue
                    }
                    let mediaMessage = childSnapshot.value as! [String: Any]
                    let messageType = "\(mediaMessage.validatedValue("type", expected: "" as AnyObject))"
                    var type = MessageType.text
                    switch messageType {
                    case "photo":
                        type = .photo
                    case "video":
                        type = .video
                    default: break
                    }
                    
                    let senderIdInGroup = "\(mediaMessage.validatedValue("senderIdInGroup", expected: "" as AnyObject))"
                    let content = "\(mediaMessage.validatedValue("content", expected: "" as AnyObject))"
                    let fromID = "\(mediaMessage.validatedValue("fromID", expected: "" as AnyObject))"
                    let videoThumbnail = "\(mediaMessage.validatedValue("videoThumbnail", expected: "" as AnyObject))"
                    
                    let timestamp = mediaMessage["timestamp"] as! Int
                    if fromID == currentUserId {
                        let message = Message.init(type: type, content: content, owner: .receiver, senderIdInGroup: senderIdInGroup, timestamp: timestamp, isRead: true, videoThumbnail: videoThumbnail)
                        messages.append(message)
                    } else {
                        let message = Message.init(type: type, content: content, owner: .sender, senderIdInGroup: senderIdInGroup, timestamp: timestamp, isRead: true, videoThumbnail: videoThumbnail)
                        messages.append(message)
                    }
                }
                
                result.mediaMessages = messages
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


struct CreateUserResult {
    
    var isSuccess: Bool = false
    var user: User?
    var error: Error?
}

class ConversationPartialInfo: NSObject {
    
    var conversationId: String
    var mediaSearcheKey: String
    
    init(_ conversationId: String, _ mediaSearcheKey: String) {
        self.conversationId = conversationId
        self.mediaSearcheKey = mediaSearcheKey
    }
}
