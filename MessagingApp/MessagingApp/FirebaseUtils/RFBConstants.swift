//
//  RFBConstants.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

// MARK: - references

let usersNode                                = "Users"
let remoteNotificationNode                   = "RemoteNotification"
let muteAudienceNode                         = "MuteAudience"
let muteUsersNode                            = "MutedUsers"
let muteGroupsNode                           = "MutedGroups"
let groupAvatarNode                          = "GroupAvatar"
let userAvatarNode                           = "UserAvatar"
let blockedUsersNode                         = "BlockedUsers"
let friendsNode                              = "Friends"
let chatRoomsNode                            = "ChatRooms"
let conversationsNode                        = "conversations"
let messagePicsNode                          = "messagePics"
let messageVideosNode                        = "messageVideos"

let storageRef = Storage.storage().reference()
let userAvatarRef = storageRef.child(userAvatarNode)
let groupAvatarRef = storageRef.child(userAvatarNode)
let messagePicsRef = storageRef.child(messagePicsNode)
let messageVideoRef = storageRef.child(messageVideosNode)

let rootRef = Database.database().reference()
let usersRef = rootRef.child(usersNode)
let userRemoteNotificationRef = rootRef.child(remoteNotificationNode)
let blockedUsersRef = rootRef.child(blockedUsersNode)
let friendsNodeRef = rootRef.child(friendsNode)
let chatRoomRef = rootRef.child(chatRoomsNode)
let conversationsRef = rootRef.child(conversationsNode)

let defaultPageSize: UInt = 20

//Parameters Names

let pEmail                                       = "email"
let pId                                          = "id"
let pUserName                                    = "username"
let pAvatar_url                                  = "avatar_url"
let pUserId                                      = "userId"
let pRemoteNotificationInfo                      = "remoteNotificationInfo"
let pChatRoomId                                  = "chatRoomId"
let pChatRoomName                                = "chatRoomName"
let pParticipantId                               = "participantId"
let pParticipants                                = "participants"
let pRoomType                                    = "roomType"

let pError                                       = "error"
let pCreatedBy                                   = "createdBy"
let pFirstName                                   = "firstName"
let pSearchNameKey                               = "searchNameKey"
let pLastName                                    = "lastName"
let pNotificationStatus                          = "notificationStatus"
let pCurrentUserId                               = "currentUserId"
let pBlockUserFrom                               = "blockUserFrom"
let pBlockUserTo                                 = "blockUserTo"
let pTimestamp                                   = "timestamp"
let pCreatedAt                                   = "createdAt"
let pLastUpdatedAt                               = "lastUpdatedAt"

let pReceiverId                                  = "receiverId"
let pReceiverName                                = "receiverName"
let pReceiverAvatar                              = "receiverAvatar"
let pSenderId                                    = "senderId"
let pSenderName                                  = "senderName"
let pSenderAvatar                                = "senderAvatar"
let pFriendshipStatus                            = "friendshipStatus"

let pFindSentRequestAtSender                     = "findSentRequestAtSender"
let pFindPendingRequestAtSender                  = "findPendingRequestAtSender"
let pFindSentRequestAtReceiver                   = "findSentRequestAtReceiver"
let pFindPendingRequestAtReceiver                = "findPendingRequestAtReceiver"

let pDeviceToken                                 = "deviceToken"
let pDeviceType                                  = "deviceType"
let pDeviceName                                  = "deviceName"

let pAdminId                                    = "adminId"
let pGroupName                                  = "groupName"
let pGroupParticipants                          = "groupParticipants"
let pGroupAvatar                                = "groupAvatar"
let pGroupId                                    = "groupId"

//Other constants
let kDummyDeviceToken                           = "60de1f8d628b3f265b028ab3a69223af2dfc0b56b2671244bb6910b68764e999"
let kDeviceType                                 = "iOS"
let kFriendshipStatusRequestSent                = "friendshipStatusRequestSent"
let kFriendshipStatusAccepted                   = "friendshipStatusAccepted"
let kFriendshipStatusRejected                   = "friendshipStatusRejected"
let kFindSentRequestAtSender                    = "findSentRequestAtSender"
let kFindPendingRequestAtSender                 = "findPendingRequestAtSender"
let kFindSentRequestAtReceiver                  = "findSentRequestAtReceiver"
let kFindPendingRequestAtReceiver               = "findPendingRequestAtReceiver"
let kRoomTypeIndividual                         = "roomTypeIndividual"
let kRoomTypeGroup                              = "roomTypeGroup"

class RFBConstants: NSObject {
    
}
