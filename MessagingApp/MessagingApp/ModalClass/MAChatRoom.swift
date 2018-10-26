//
//  MAChatRoom.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

enum ChatRoomType {
    case roomType_Unknown, roomType_Individual, roomType_Group
}

class MAChatRoom: SnapshotParser {
    
    var adminId: String
    var chatRoomName: String
    var avatarUrl: String
    var roomType: ChatRoomType
    
    var parentKey: String
    var participants: Array<MAUser>
    var participantsIds: Array<String>
    
    var groupImage: UIImage? // Temporary field for creating group
    
    init() {
        parentKey = ""
        roomType = .roomType_Unknown
        adminId = ""
        chatRoomName = ""
        avatarUrl = ""
        participants = [MAUser]()
        participantsIds = [String]()
    }
    
    convenience required init(with snapshot: DataSnapshot, exception: String...) {
        self.init()
        
        parentKey = snapshot.key
        
        if snapshot.hasChild(pAdminId) && !exception.contains(pAdminId) {
            adminId = snapshot.childSnapshot(forPath: pAdminId).value as! String
        }
        
        if snapshot.hasChild(pGroupName) && !exception.contains(pGroupName) {
            chatRoomName = snapshot.childSnapshot(forPath: pGroupName).value as! String
        }
        
        if snapshot.hasChild(pAvatar_url) && !exception.contains(pAvatar_url) {
            avatarUrl = snapshot.childSnapshot(forPath: pAvatar_url).value as! String
        }
        
        if snapshot.hasChild(pRoomType) && !exception.contains(pRoomType) {
            let roomTypeString = snapshot.childSnapshot(forPath: pRoomType).value as! String
            if roomTypeString == kRoomTypeIndividual {
                roomType = .roomType_Individual
            } else if roomTypeString == kRoomTypeGroup {
                roomType = .roomType_Group
            }
        }
        
        if snapshot.hasChild(pParticipants) && !exception.contains(pParticipants) {
            if let participants = snapshot.childSnapshot(forPath: pParticipants).value as? Array<String> {
                participantsIds = participants
            }
        }
    }
}


extension MAChatRoom {
    
    func createGroup(callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            
            let uid = currentUser.uid
            
            var participantsArray = [String]()
            participantsArray.append(uid)

            for user in self.participants {
                participantsArray.append(user.userId)
            }
            
            let info = [pAdminId: uid,
                        pGroupName: self.chatRoomName,
                        pSearchNameKey: self.chatRoomName.lowercased(),
                        pParticipants:participantsArray,
                        pAvatar_url:"",
                        pRoomType:kRoomTypeGroup,
                        pCreatedBy:uid,
                        pCreatedAt: ServerValue.timestamp(),
                        pLastUpdatedAt: ServerValue.timestamp()] as [String : Any]
            
            Debug.log("info>>  \(info.debugDescription)")
            
            let autoKey = chatRoomRef.childByAutoId().key
            
            chatRoomRef.child(autoKey).setValue(info, withCompletionBlock: { (error, databaseReference) in
             
                if let error = error {
                    Debug.log("createGroup error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    
                    self.parentKey = databaseReference.key
                    self.participantsIds = participantsArray
                    
                    if let image = self.groupImage {
                        image.uploadGroupAvatar(false, groupId: databaseReference.key, track: { (progress) in
                            Debug.log("progress group avatar upload>>  \(String(describing: progress))")
                        }, callback: { (uploadResult) in
                            Debug.log("Group avatar uploadResult>>  \(uploadResult)")
                            if uploadResult.isSuccess {
                                if let urlString = uploadResult.mediaUrl {
                                    self.avatarUrl = urlString.absoluteString
                                }
                            }
                        })
                    }
                    
                    Debug.log("createGroup databaseReference>>  \(databaseReference.key)")
                    callback?(true, nil)
                }
            })
        }
    }
    
  func fetchMembers(hud: Bool = true, callback: ((SearchUserResult) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            var result = SearchUserResult()
            result.totalChildrenCount = 0
            
            if hud {
                ProgressHUD.show()
            }
            
            var users = [MAUser]()

            for participantsId in self.participantsIds {
                
                Debug.log("participantsId>>>   \(participantsId)")
                
                if participantsId.length == 0 {
                    continue
                }
                
                let lUserRef = usersRef.child(participantsId)
                
                lUserRef.observeSingleEvent(of: .value, with: { userSnapshot in
                    let user = MAUser(with: userSnapshot)
                    
                    users.append(user)
                    
                    let userCount = UInt(users.count)
                    
                    if userCount == users.count {
                        
                        if hud {
                            ProgressHUD.dismiss()
                        }
                        result.totalChildrenCount = userCount
                        result.users = users
                        callback?(result)
                    }
                })
            }
        }
    }
    
    func addParticipants(nwParticipants: Array<MAUser>, callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            let friendKeyNode = chatRoomRef.child(self.parentKey)
            
            var updatedParticipantsArray = [String]()
            
            for user in self.participants {
                updatedParticipantsArray.append(user.userId)
            }
            for user in nwParticipants {
                updatedParticipantsArray.append(user.userId)
            }
            
            let updatedStatusInfo = [pParticipants:updatedParticipantsArray,
                        pLastUpdatedAt: ServerValue.timestamp()] as [String : Any]
            
            friendKeyNode.updateChildValues(updatedStatusInfo, withCompletionBlock: { (error, databaseReference) in
                
                if let error = error {
                    Debug.log("addParticipants error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    self.participantsIds = updatedParticipantsArray
                    self.participants.append(contentsOf: nwParticipants)
                    callback?(true, nil)
                }
            })
        }
    }
    
    func exitGroup(callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            
            let friendKeyNode = chatRoomRef.child(self.parentKey)
            
            var updatedParticipantsArray = [String]()
            
            for uid in self.participantsIds {
                
                if uid != currentUser.uid { // skip me
                    updatedParticipantsArray.append(uid)
                }
            }
           
            if updatedParticipantsArray.count == 0 {
                callback?(false, FirebaseUtils.unKnownError)
                return
            }
            
            let amIAdmin = self.adminId == currentUser.uid ? true : false
            
            var updatedStatusInfo = [pParticipants:updatedParticipantsArray,
                                     pLastUpdatedAt: ServerValue.timestamp()] as [String : Any]
            
            // If current user is admin, assign any other member as admin
            if amIAdmin {
                var nwAdmin = ""
                if let aMemberId = updatedParticipantsArray.first {
                    nwAdmin = aMemberId
                }
                updatedStatusInfo[pAdminId] = nwAdmin
            }
            
            friendKeyNode.updateChildValues(updatedStatusInfo, withCompletionBlock: { (error, databaseReference) in
                
                if let error = error {
                    Debug.log("exitGroup error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    self.participantsIds = updatedParticipantsArray
                    //self.participants.append(contentsOf: nwParticipants)
                    callback?(true, nil)
                }
            })
        }
    }
    
    func deleteGroup(callback: ((_ isSuccess: Bool, _ error: Error?) -> Void)?) {
        
        FirebaseUtils.currentUser { (currentUser) in
            
            if !APPDELEGATE.isReachable {
                callback?(false, FirebaseUtils.netError)
                return
            }
            
            chatRoomRef.child(self.parentKey).removeValue(completionBlock: { (error, _) in
                if let error = error {
                    Debug.log("deleteGroup error>>  \(String(describing: error))")
                    callback?(false, error)
                } else {
                    callback?(true, nil)
                }
            })
        }
    }
}
