//
//  FCMNotificationHandler.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

let notiType_friendRequestSent = "friendRequestSent"
let notiType_friendRequestAccepted = "friendRequestAccepted"
let notiType_receivedNewMessageArrivedInGroup = "receivedNewMessageArrivedInGroup"
let notiType_receivedNewMessageArrivedFromIndivisual = "receivedNewMessageArrivedFromIndivisual"


let fcmServerKey: String = ""


class FCMNotificationHandler: NSObject {
    
    class func connectToFCM() {
        if (InstanceID.instanceID().token() != nil) {
            return
        }
        Messaging.messaging().shouldEstablishDirectChannel = false
        Messaging.messaging().shouldEstablishDirectChannel = true
        
        Debug.log("connectToFCM called")

        if let user = Auth.auth().currentUser {
            if let _ = defaults.object(forKey: pCurrentUserId) {
                // User is signed in. Show home screen
                user.updateForRemoteNotification()
            }
        }
    }
    
    class private func postNotification(_ message: String,
                                        _ type: String,
                                        _ token: String,
                                        _ actionId: String) {

        FirebaseUtils.currentUser { (currentUser) in

            //let msgId = UUID().uuidString

            var request = URLRequest(url: URL(string: "https://fcm.googleapis.com/fcm/send")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("key=\(fcmServerKey)", forHTTPHeaderField: "Authorization")
            
            let notiDict = [
                "body" : message,
            ]
            
            var dataDict = [
                "type" : type
            ]
            
            if actionId.length != 0 {
                dataDict["aId"] = actionId
            }
            
            let json = [
                "to" : token,
                "priority" : "high",
                "notification" : notiDict,
                "data" : dataDict
                ] as [String : Any]
            
            Debug.log("json>>> \(json)")
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                request.httpBody = jsonData
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, error == nil else {
                        Debug.log("Error=\(error.debugDescription)")
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        // check for http errors
                        Debug.log("Status Code should be 200, but is \(httpStatus.statusCode)")
                        Debug.log("Response = \(response.debugDescription)")
                    }
                    let responseString = String(data: data, encoding: .utf8)
                    Debug.log("responseString = \(responseString.debugDescription)")
                }
                task.resume()
            }
            catch {
                Debug.log("Error=\(error)")
            }
        }
    }
    
    class private func initiateNotification(_ message: String,
                                        _ type: String,
                                        _ user: MAUser,
                                        _ actionId: String = "") {
        
        self.getCurrentUser { (currentUser) in
           
            // ignore if notification if off
            // fetch current status
            RBasicUserServices.getCurrentNotificationStatus(user.userId, callBack: { (notificationStatus) in
                if notificationStatus {
                    // check if participant is muted the current user
                    RBasicUserServices.getMutedAudience(user.userId, callback: { (result) in
                        if result.mutedUsersIds.contains(currentUser.userId) {
                            // skip to send notification
                        } else {
                            for registeredDeviceToken in user.deviceTokens {
                                self.postNotification(message, type, registeredDeviceToken, actionId)
                            }
                        }
                    })
                }
            })
        }
    }
    
    class func fireNotificationForFriendRequestAccepted(_ user: MAUser) {
        
        self.getCurrentUser { (currentUser) in
            let message = "\(currentUser.fullName) accepted your friend request"
            self.initiateNotification(message, notiType_friendRequestAccepted, user)
        }
    }
    
    class func fireNotificationForFriendRequestSent(_ user: MAUser) {
        
        self.getCurrentUser { (currentUser) in
            let message = "\(currentUser.fullName) sent you friend request"
            self.initiateNotification(message, notiType_friendRequestSent, user)
        }
    }
    
    class func fireNotificationForNewMessageToFriend(_ friend: MAUser) {
  
        self.getCurrentUser { (currentUser) in
            let message = "\(currentUser.fullName) sent you a new message"
            self.initiateNotification(message, notiType_receivedNewMessageArrivedFromIndivisual, friend, currentUser.userId)
        }
    }
    
    class func fireNotificationForNewMessageInGroup(_ group: MAChatRoom) {
        
        self.getCurrentUser { (currentUser) in

            for participant in group.participants {

                if participant.userId == currentUser.userId {
                    // skip current user
                    continue
                }
                
                // check if participant is muted the group or not
                RBasicUserServices.getMutedAudience(participant.userId, callback: { (result) in
                    if result.mutedGroupsIds.contains(group.parentKey) {
                        // skip the notification to send
                    } else {
                        let message = "You have new message in \(group.chatRoomName)"
                        self.initiateNotification(message, notiType_receivedNewMessageArrivedInGroup, participant, group.parentKey)
                    }
                })
            }
        }
    }
    
    class func getCurrentUser(completionBlock: ((MAUser)->())?) {
        
        if let user = APPDELEGATE.appUser {
            if let block = completionBlock {
                block(user)
            }
        } else {
            FirebaseUtils.currentUser { (currentUser) in
                currentUser.fetch(completionBlock: { (isSuccess, modalUser, error) in
                    if let modalUser = modalUser {
                        APPDELEGATE.appUser = modalUser
                        if let block = completionBlock {
                            block(modalUser)
                        }
                    }
                })
            }
        }
    }
    
    class func receivedRemoteNotification(userInfo: [AnyHashable : Any]) {
        Debug.log("\(userInfo.debugDescription)")
        
        if UIApplication.shared.applicationState == .background {
            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        } else if UIApplication.shared.applicationState == .active {
            
            if let apsDict = userInfo["aps"] as? Dictionary<String, AnyObject> {
                let message = "\(apsDict.validatedValue("alert", expected: "" as AnyObject))"
                let notiType = "\(userInfo.validatedValue("type", expected: "" as AnyObject))"
                let actionId = "\(userInfo.validatedValue("aId", expected: "" as AnyObject))"

                if notiType == notiType_receivedNewMessageArrivedFromIndivisual
                    || notiType == notiType_receivedNewMessageArrivedInGroup {

                    if let controller = UIWindow.topController as? ChatVC {
                        if notiType == notiType_receivedNewMessageArrivedInGroup {
                            if let chatRoom = controller.chatRoom {
                                if actionId == chatRoom.parentKey {
                                    // skip as in the same chat
                                    return
                                }
                            }
                        } else if notiType == notiType_receivedNewMessageArrivedFromIndivisual {
                            if let opponentUser = controller.participant {
                                if actionId == opponentUser.userId {
                                    // skip as in the same chat
                                    return
                                }
                            }
                        }
                    }
                }
                showNotification(message)
            }
        }
    }
    
    class func showNotification(_ message: String) {
        
        ISMessages.showCardAlert(withTitle: "Notification!", message: message, duration: 5.0, hideOnSwipe: true, hideOnTap: true, alertType: .info, alertPosition: .top) { (finished) in
            Debug.log("Alert did hide for message \(message)")
        }
    }
}
