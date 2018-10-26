//
//  Conversation.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class Conversation {
    
    //MARK: Properties
    let user: MAUser
    var lastMessage: Message
    
    //MARK: Methods
    class func showConversations(completion: @escaping ([Conversation]) -> Swift.Void) {
        
        FirebaseUtils.currentUser { (currentUser) in
            let currentUserID = currentUser.uid

            var conversations = [Conversation]()
            usersRef.child(currentUserID).child(conversationsNode).observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    let fromID = snapshot.key
                    let values = snapshot.value as! [String: String]
                    let location = values["location"]!
                    
                    let lUserRef = usersRef.child(fromID)

                    lUserRef.observeSingleEvent(of: .value, with: { userSnapshot in
                        let user = MAUser(with: userSnapshot)
                        user.parentKey = userSnapshot.key
                        
                        let emptyMessage = Message.init(type: .text, content: "loading", owner: .sender, senderIdInGroup: "", timestamp: 0, isRead: true, videoThumbnail: "")
                        let conversation = Conversation.init(user: user, lastMessage: emptyMessage)
                        conversations.append(conversation)
                        conversation.lastMessage.downloadLastMessage(forLocation: location, completion: {
                            completion(conversations)
                        })
                    })
                }
            })
        }
    }
    
    //MARK: Inits
    init(user: MAUser, lastMessage: Message) {
        self.user = user
        self.lastMessage = lastMessage
    }
}
