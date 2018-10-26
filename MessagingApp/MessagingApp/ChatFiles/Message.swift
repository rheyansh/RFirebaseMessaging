//
//  Message.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

enum SharedMediaType {
    case mediaTypePhoto, mediaTypeVideo
}

class Message {
    
    //MARK: Properties
    var owner: MessageOwner
    var type: MessageType
    var content: Any
    var timestamp: Int
    var isRead: Bool
    var senderIdInGroup: String?
    var videoThumbnail: String?

    var image: UIImage?
    private var toID: String?
    private var fromID: String?

    //MARK: Methods
    class func downloadAllMessages(_ hud: Bool = true, forUserID: String, completion: @escaping (Message) -> Swift.Void) {
        
        FirebaseUtils.currentUser { (currentUser) in
            let currentUserID = currentUser.uid
            
            Debug.log("forUserID>>  \(forUserID)")
          
            
            if forUserID.length == 0 {
                return
            }
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            if hud {
                ProgressHUD.show()
            }
            
            usersRef.child(currentUserID).child(conversationsNode).child(forUserID).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = data["location"]!
                    
                    Debug.log("snapshot.value>>  \(data)")
                    Debug.log("location>>  \(location)")

                    conversationsRef.child(location).observe(.childAdded, with: { (snap) in
                        
                        if hud {
                            ProgressHUD.dismiss()
                        }
                        
                        if snap.exists() {
                            let receivedMessage = snap.value as! [String: Any]
                            let messageType = receivedMessage["type"] as! String
                            var type = MessageType.text
                            switch messageType {
                            case "photo":
                                type = .photo
                            case "video":
                                type = .video
                            default: break
                            }
                            
                            let senderIdInGroup = "\(receivedMessage.validatedValue("senderIdInGroup", expected: "" as AnyObject))"
                            let content = "\(receivedMessage.validatedValue("content", expected: "" as AnyObject))"
                            let fromID = "\(receivedMessage.validatedValue("fromID", expected: "" as AnyObject))"
                            let videoThumbnail = "\(receivedMessage.validatedValue("videoThumbnail", expected: "" as AnyObject))"

                            let timestamp = receivedMessage["timestamp"] as! Int
                            if fromID == currentUserID {
                                let message = Message.init(type: type, content: content, owner: .receiver, senderIdInGroup: senderIdInGroup, timestamp: timestamp, isRead: true, videoThumbnail: videoThumbnail)
                                completion(message)
                            } else {
                                let message = Message.init(type: type, content: content, owner: .sender, senderIdInGroup: senderIdInGroup, timestamp: timestamp, isRead: true, videoThumbnail: videoThumbnail)
                                completion(message)
                            }
                        }
                    })
                } else {
                    if hud {
                        ProgressHUD.dismiss()
                    }
                }
            })
        }
    }
    
    class func getConversationId(forParticipantId: String, completion: @escaping (String) -> Swift.Void) {
        
        FirebaseUtils.currentUser { (currentUser) in
            let currentUserID = currentUser.uid
            
            usersRef.child(currentUserID).child(conversationsNode).child(forParticipantId).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = "\(data.validatedValue("location", expected: "" as AnyObject))"
                    completion(location)
                }
            })
        }
    }
    
    func downloadImage(indexpathRow: Int, completion: @escaping (Bool, Int) -> Swift.Void)  {
        if self.type == .photo {
            let imageLink = self.content as! String
            let imageURL = URL.init(string: imageLink)
            URLSession.shared.dataTask(with: imageURL!, completionHandler: { (data, response, error) in
                if error == nil {
                    self.image = UIImage.init(data: data!)
                    completion(true, indexpathRow)
                }
            }).resume()
        }
    }
    
    class func markMessagesRead(forUserID: String)  {
        
        FirebaseUtils.currentUser { (currentUser) in
            let currentUserID = currentUser.uid

            usersRef.child(currentUserID).child(conversationsNode).child(forUserID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = data["location"]!
                    conversationsRef.child(location).observeSingleEvent(of: .value, with: { (snap) in
                        if snap.exists() {
                            for item in snap.children {
                                let receivedMessage = (item as! DataSnapshot).value as! [String: Any]
                                let fromID = receivedMessage["fromID"] as! String
                                if fromID != currentUserID {
                                    conversationsRef.child(location).child((item as! DataSnapshot).key).child("isRead").setValue(true)
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    func downloadLastMessage(forLocation: String, completion: @escaping () -> Swift.Void) {
        
        FirebaseUtils.currentUser { (currentUser) in
            let currentUserID = currentUser.uid

            conversationsRef.child(forLocation).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    for snap in snapshot.children {
                        let receivedMessage = (snap as! DataSnapshot).value as! [String: Any]
                        self.content = receivedMessage["content"]!
                        self.timestamp = receivedMessage["timestamp"] as! Int
                        let messageType = receivedMessage["type"] as! String
                        let fromID = receivedMessage["fromID"] as! String
                        self.isRead = receivedMessage["isRead"] as! Bool
                        self.senderIdInGroup = "\(receivedMessage.validatedValue("senderIdInGroup", expected: "" as AnyObject))"

                        var type = MessageType.text
                        switch messageType {
                        case "text":
                            type = .text
                        case "photo":
                            type = .photo
                        case "video":
                            self.videoThumbnail = "\(receivedMessage.validatedValue("videoThumbnail", expected: "" as AnyObject))"

                            type = .video
                        default: break
                        }
                        self.type = type
                        if currentUserID == fromID {
                            self.owner = .receiver
                        } else {
                            self.owner = .sender
                        }
                        completion()
                    }
                }
            })
        }
    }
    
    // pass value in senderIdInGroup if it is group chat
    // if it is one to one chat than pass nil
    // senderIdInGroup is teh id of user who is sending the message

    class func send(message: Message, roomType: ChatRoomType, friend: MAUser?, chatRoom: MAChatRoom?, completion: @escaping (Bool) -> Swift.Void)  {
        
        
        var toID = ""
        
        if roomType == .roomType_Individual {
            if let friend = friend {
                toID = friend.userId
            }
        } else if roomType == .roomType_Group {
            if let chatRoom = chatRoom {
                toID = chatRoom.parentKey
            }
        }
        
        if toID.length == 0 {
            return
        }
        
        FirebaseUtils.currentUser { (currentUser) in
            let currentUserID = currentUser.uid
            
            switch message.type {
            case .photo:
                let imageData = UIImageJPEGRepresentation((message.content as! UIImage), 0.5)
                let child = UUID().uuidString
                
                messagePicsRef.child(child).putData(imageData!, metadata: nil, completion: { (metadata, error) in
                    if error == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        
                        let senderIdInGrp = currentUserID
                        let values = ["type": "photo", "content": path!, "fromID": currentUserID, "toID": toID, "senderIdInGroup": senderIdInGrp, "timestamp": message.timestamp, "isRead": false] as [String : Any]
                        
                        Message.uploadMessage(withValues: values, roomType: roomType, friend: friend, chatRoom: chatRoom, completion: { (status, messageId) in
                            completion(status)
                        })
                    }
                })
            case .text:
                
                let senderIdInGrp = currentUserID
                let values = ["type": "text", "content": message.content, "fromID": currentUserID, "toID": toID, "senderIdInGroup": senderIdInGrp, "timestamp": message.timestamp, "isRead": false]
                
                Message.uploadMessage(withValues: values, roomType: roomType, friend: friend, chatRoom: chatRoom, completion: { (status, messageId) in
                    completion(status)
                })
                
            case .video:
                let child = UUID().uuidString
                
                if let fileUrl = message.content as? URL {
                    messageVideoRef.child(child).putFile(from: fileUrl, metadata: nil, completion: { (metadata, error) in
                        if error == nil {
                            let path = metadata?.downloadURL()?.absoluteString

                            let senderIdInGrp = currentUserID
                            let values = ["type": "video", "content": path!, "fromID": currentUserID, "toID": toID, "senderIdInGroup": senderIdInGrp, "videoThumbnail": "", "timestamp": message.timestamp, "isRead": false] as [String : Any]

                            Message.uploadMessage(withValues: values, roomType: roomType, friend: friend, chatRoom: chatRoom, completion: { (status, messageDBRef) in
                                
                                if let messageDBRef = messageDBRef {
                                    
                                    //Upload thumbnail
                                    do {
                                        let asset = AVURLAsset(url: fileUrl , options: nil)
                                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                                        imgGenerator.appliesPreferredTrackTransform = true
                                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                                        let thumbnail = UIImage(cgImage: cgImage)
                                        
                                        if let thumbnailData = thumbnail.toData(compressionQuality: 0.3) {
                                            
                                            messagePicsRef.child(child).putData(thumbnailData, metadata: nil, completion: { (metadata, error) in
                                                
                                                if error == nil {
                                                    if let thumbnailURL = metadata?.downloadURL()?.absoluteString {
                                                        messageDBRef.updateChildValues(["videoThumbnail" : thumbnailURL])
                                                    }
                                                }
                                            })
                                        }
                                    } catch let error {
                                        Debug.log("*** Error generating thumbnail: \(error.localizedDescription)")
                                    }
                                }
                                
                                completion(status)
                            })
                        }
                    })
                }
            }
        }
    }

    class func uploadMessage(withValues: [String: Any], roomType: ChatRoomType, friend: MAUser?, chatRoom: MAChatRoom?, completion: @escaping (Bool, DatabaseReference?) -> Swift.Void) {
        
        FirebaseUtils.currentUser { (currentUser) in
            let currentUserID = currentUser.uid
            
            var toID = ""
            
            if roomType == .roomType_Individual {
                if let friend = friend {
                    toID = friend.userId
                }
            } else if roomType == .roomType_Group {
                if let chatRoom = chatRoom {
                    toID = chatRoom.parentKey
                }
            }
            
            if toID.length == 0 {
                return
            }
            
            usersRef.child(currentUserID).child(conversationsNode).child(toID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = data["location"]!
                    
                    let messageNew = conversationsRef.child(location).childByAutoId()

                    messageNew.setValue(withValues, withCompletionBlock: { (error, databaseReference) in
                        if error == nil {
                            
                            if roomType == .roomType_Individual {
                                FCMNotificationHandler.fireNotificationForNewMessageToFriend(friend!)
                            } else if roomType == .roomType_Group {
                                FCMNotificationHandler.fireNotificationForNewMessageInGroup(chatRoom!)
                            }
                            
                            completion(true, messageNew)
                        } else {
                            completion(false, messageNew)
                        }
                    })
                } else {
                    let messageNew = conversationsRef.childByAutoId().childByAutoId()
                    
                    messageNew.setValue(withValues, withCompletionBlock: { (error, reference) in
                        let mediaSearchKey = "\(currentUserID)_\(toID)"
                        
                        let data = ["location": reference.parent!.key, "mediaSearchKey": mediaSearchKey]
                        usersRef.child(currentUserID).child(conversationsNode).child(toID).updateChildValues(data)
                        usersRef.child(toID).child(conversationsNode).child(currentUserID).updateChildValues(data)
                        
                        if roomType == .roomType_Individual {
                            FCMNotificationHandler.fireNotificationForNewMessageToFriend(friend!)
                        } else if roomType == .roomType_Group {
                            if let chatRoom = chatRoom {
                                FCMNotificationHandler.fireNotificationForNewMessageInGroup(chatRoom)
                            }
                        }
                        completion(true, messageNew)
                    })
                }
            })
        }
    }
    
    class func checkAndAddGroupMemberIfNotAddedInGroupChat(_ chatRoomId: String, _ member: MAUser, _ conversationId: String) {
        
        if member.conversationIds.contains(chatRoomId) {
            // already added. Do nothing
        } else {
            //Add
            let data = ["location": conversationId]
            
            usersRef.child(member.userId).child(conversationsNode).child(chatRoomId).updateChildValues(data, withCompletionBlock: { (error, databaseReference) in
                
                if let _ = error {
                    //skip
                } else {
                    member.conversationIds.append(chatRoomId)
                }
            })
        }
    }
    
    class func addGroupMemberInGroupChat(_ chatRoomId: String, _ memberId: String, _ conversationId: String) {
        
        let mediaSearchKey = "\(chatRoomId)_\(memberId)"
        let data = ["location": conversationId, "mediaSearchKey": mediaSearchKey]

        usersRef.child(memberId).child(conversationsNode).child(chatRoomId).updateChildValues(data)
    }
    
    //MARK: Inits
    init(type: MessageType, content: Any, owner: MessageOwner, senderIdInGroup: String, timestamp: Int, isRead: Bool, videoThumbnail: String) {
        self.type = type
        self.content = content
        self.owner = owner
        self.timestamp = timestamp
        self.isRead = isRead
        self.senderIdInGroup = senderIdInGroup
        self.videoThumbnail = videoThumbnail

    }
}
