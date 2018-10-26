//
//  MAChatParticipantDetailsVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MAChatParticipantDetailsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var friendStatusButton: UIButton!
    @IBOutlet weak var avatarButton: UIButton!
    
    var titleArray = [String]()
    var participantInfo: MAUser?
    var friendshipStatus: FriendshipStatus = .friendshipStatusRequestsNone
    var friendNodeKey: String?
    var isFetchedFriendShipStatus = false
    
    private var muteStatus = false
    private var isMuteStatusFetched = false

    // for chat to participant details and than go shared media
    var isHasMessages = false
    var loadedMessages = [Message]()

    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        initialSetup()
    }
    
    //MARK:- Private functions
    
    private func initialSetup() {
        
        tableView.estimatedRowHeight = 52
        tableView.rowHeight = UITableViewAutomaticDimension
        friendStatusButton.isHidden = true
        friendStatusButton.isUserInteractionEnabled = false
        
        guard let participantInfo = self.participantInfo else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        nameLabel.text = participantInfo.fullName
        avatar.normalLoad(participantInfo.avatarUrl)
        
        ProgressHUD.show()

        FBBlockUserServices.isBlockingExistsWith(user: participantInfo) { (result) in
            
            ProgressHUD.dismiss()

            if let isBlocked = result.isBlocked {
                if isBlocked == false {
                    self.friendStatusButton.isHidden = false
                    self.titleArray = ["Send Message", "Share Contact", "Shared Media", "Groups In Common", "Notifications", "Block User"]
                    self.tableView.reloadData()
                    
                    self.checkForMute()
                    
                    ProgressHUD.show()
                    FBFriendsServices.getFriendShipStatusWith(user: participantInfo) { (result) in
                        
                        ProgressHUD.dismiss()
                        
                        if let friendshipStatus = result.friendshipStatus {
                            self.isFetchedFriendShipStatus = true
                            self.friendStatusButton.isHidden = false
                            self.friendshipStatus = friendshipStatus
                            self.friendNodeKey = result.friendNodeKey
                            if friendshipStatus == .friendshipStatusRequestsNone {
                                self.friendStatusButton.isUserInteractionEnabled = true
                                self.friendStatusButton.setTitle("+ Add", for: .normal)
                            } else if friendshipStatus == .friendshipStatusRequestsSent {
                                self.friendStatusButton.setTitle("Pending", for: .normal)
                            } else if friendshipStatus == .friendshipStatusRequestsReceived {
                                self.friendStatusButton.isUserInteractionEnabled = true
                                self.friendStatusButton.setTitle("Respond", for: .normal)
                            } else if friendshipStatus == .friendshipStatusAccepted {
                                self.friendStatusButton.setTitle("Friend", for: .normal)
                            }
                            
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    private func checkForMute() {
        
        guard let participantInfo = self.participantInfo else {
            return
        }
        
        FirebaseUtils.currentUser { (user) in
            RBasicUserServices.getMutedAudience(user.uid, callback: { (result) in
                
                if result.error == nil {
                    self.isMuteStatusFetched = true
                    if result.mutedUsersIds.contains(participantInfo.userId) {
                        self.muteStatus = true
                    } else {
                        self.muteStatus = false
                    }
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    private func startBlocking(_ participantInfo: MAUser) {
        
        ProgressHUD.show()
        self.tableView.isUserInteractionEnabled = false
        FBBlockUserServices.addToBlockList(user: participantInfo) { (isSuccess, error) in
            ProgressHUD.dismiss()
            self.tableView.isUserInteractionEnabled = true
            if let error = error {
                TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
            } else {
                if isSuccess {
                    let message = "\(participantInfo.firstName) has been blocked"
                    TinyToast.shared.show(message: message, duration: .veryShort)
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    private func blockUser() {
        
        guard let participantInfo = self.participantInfo else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        let title = "Are you sure you want to block \(participantInfo.firstName)?"
        
        AlertController.alert(title: title, message: "", buttons: ["NO", "YES"], tapBlock: { (_, index) in
            if (index != 0) {
                // delete friend node first if exist
                
                if let friendNodeKey = self.friendNodeKey {
                    ProgressHUD.show()
                    FBFriendsServices.deleteFriendNode(nodeKey: friendNodeKey, callback: { (isSuccess, error) in
                        ProgressHUD.dismiss()
                        if isSuccess {
                            self.startBlocking(participantInfo)
                        }
                    })
                } else {
                    self.startBlocking(participantInfo)
                }
            }
        })
    }
    
    //MARK:- IBActions
    
    @IBAction func onBackButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onFriendStatusButtonAction(_ sender: UIButton) {
        
        guard let user = self.participantInfo else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        if friendshipStatus == .friendshipStatusRequestsNone {
            self.friendStatusButton.isUserInteractionEnabled = false
            ProgressHUD.show()

            FBFriendsServices.sendFriendRequest(user: user, callback: { (result) in
                ProgressHUD.dismiss()
                if result.isSuccess {
                    let message = "Friend request sent to \(user.fullName)"
                    TinyToast.shared.show(message: message, duration: .veryShort)
                    self.friendNodeKey = result.friendNodeKey
                    self.friendStatusButton.setTitle("Pending", for: .normal)
                    self.friendshipStatus = .friendshipStatusRequestsSent
                }
            })
           
        } else if friendshipStatus == .friendshipStatusRequestsReceived {
            
            guard let friendNodeKey = self.friendNodeKey else {
                return
            }
            
            AlertController.alert(title: "Respond", message: "", buttons: ["Delete Request", "Accept Request", "Cancel"], tapBlock: { (_, index) in
                
                if (index == 0) {
                    
                    self.friendStatusButton.isUserInteractionEnabled = false
                    ProgressHUD.show()

                    FBFriendsServices.deleteFriendNode(nodeKey: friendNodeKey, callback: { (isSuccess, error) in
                        ProgressHUD.dismiss()
                        
                        if isSuccess {
                            self.friendStatusButton.isUserInteractionEnabled = true
                            let message = "You have rejected request from \(user.fullName)"
                            TinyToast.shared.show(message: message, duration: .veryShort)
                            self.friendStatusButton.setTitle("+ Add", for: .normal)
                            self.friendshipStatus = .friendshipStatusRequestsNone
                        }
                    })
                    
                } else if (index == 1) {
                    
                    self.friendStatusButton.isUserInteractionEnabled = false
                    ProgressHUD.show()

                    FBFriendsServices.acceptFriendRequestViaNode(nodeKey: friendNodeKey, fromUserId: user.userId, callback: { (isSuccess, error) in
                        ProgressHUD.dismiss()
                        
                        if isSuccess {
                            let message = "You have accepted request from \(user.fullName)"
                            TinyToast.shared.show(message: message, duration: .veryShort)
                            self.friendStatusButton.setTitle("Friend", for: .normal)
                            self.friendshipStatus = .friendshipStatusAccepted
                            FCMNotificationHandler.fireNotificationForFriendRequestAccepted(user)
                        }
                    })
                }
            })
        }
    }
    
    @IBAction func onAvatarButtonAction(_ sender: UIButton) {
        
        guard let participantInfo = self.participantInfo else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        if let url = URL(string: participantInfo.avatarUrl) {
            if url.isValid {
                self.zoomImageIn(self.avatar)
            }
        }
    }
    
    private func moveToSendMessage() {
        
        if self.backViewController() is ChatVC {
            self.navigationController?.popViewController(animated: true)
        } else {
            let chatVC = chatSectionStoryboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
            chatVC.participant = participantInfo
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    private func moveToShareContact() {
        
        let shareContactVC = circleSectionStoryboard.instantiateViewController(withIdentifier: "MAShareContactVC") as! MAShareContactVC
        self.navigationController?.pushViewController(shareContactVC, animated: true)
        
        shareContactVC.onSelectContact = {
            (contact) -> Void in
            
            delay(delay: 0.1, closure: {
                
                if self.backViewController() is ChatVC {
                    let chatVC = self.backViewController() as! ChatVC
                    
                    let message: String = "\(contact.displayName()) \nPhones: \(contact.getPhoneNumbers().joined(separator: ", ")) \nEmails: \(contact.getEmails().joined(separator: ", "))"
                    chatVC.composeMessage(type: .text, content: message)

                    self.navigationController?.popViewController(animated: true)
                } else {
                    let chatVC = chatSectionStoryboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
                    chatVC.participant = self.participantInfo
                    self.navigationController?.pushViewController(chatVC, animated: true)
                    
                    let message: String = "\(contact.displayName()) \nPhones: \(contact.getPhoneNumbers().joined(separator: ", ")) \nEmails: \(contact.getEmails().joined(separator: ", "))"
                    chatVC.composeMessage(type: .text, content: message)
                }
            })
        }
    }
   
    private func moveForSharedMedia() {
        
        let sharedMediaBaseVC = sharedMediaSectionStoryboard.instantiateViewController(withIdentifier: "MASharedMediaBaseVC") as! MASharedMediaBaseVC
        sharedMediaBaseVC.participantInfo = participantInfo
        sharedMediaBaseVC.isHasMessages = isHasMessages
        sharedMediaBaseVC.loadedMessages = loadedMessages

        self.navigationController?.pushViewController(sharedMediaBaseVC, animated: true)
    }
    
    private func moveToCommonGroups() {
        
        let commonGroupsVC = self.storyboard?.instantiateViewController(withIdentifier: "MACommonGroupsVC") as! MACommonGroupsVC
        commonGroupsVC.participantInfo = self.participantInfo
        self.navigationController?.pushViewController(commonGroupsVC, animated: true)
    }
    
    @IBAction func onSwitch(_ sender: UISwitch) {
        
        guard let participantInfo = self.participantInfo else {
            return
        }
        
        let mute = !sender.isOn
        
        RBasicUserServices.muteAudience(mute , audienceType: .roomType_Individual, audienceId: participantInfo.userId) { (isSuccess, error) in
            
            if isSuccess {
                self.muteStatus = mute
                self.tableView.reloadData()
            }
        }
    }
    
    private func cellIdForIndexPath(_ indexPath: IndexPath) -> String {
        
        var cellId = "MAParticipantDetailsOrangeCell"

        switch indexPath.section {
        case 2: fallthrough
        case 3: cellId = "MAParticipantDetailsBlackCell"
        case 4: cellId = "MAParticipantDetailsNotificationCell"
        case 5: cellId = "MAParticipantDetailsBlockUserCell"

        default:
            break
        }
        
        return cellId
    }
    
    //MARK:- UITableView
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // ignore blocking feature until the friend node status is fetched
        
        if isFetchedFriendShipStatus == false && indexPath.section == 5 {
            return 0
        }
        
        return max(52, UITableViewAutomaticDimension)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:MAParticipantDetailsCell = tableView.dequeueReusableCell(withIdentifier: cellIdForIndexPath(indexPath), for: indexPath) as! MAParticipantDetailsCell
        
        cell.titleLabel.text = titleArray[indexPath.section]
        
        if cell.separatorLabel != nil {
            if indexPath.section == 1 || indexPath.section == 4 {
                cell.separatorLabel.isHidden = true
            } else {
                cell.separatorLabel.isHidden = false
            }
        }
        
        if indexPath.section == 4 {
            cell.cellSwitch.isHidden = !isMuteStatusFetched
            cell.cellSwitch.isOn = !self.muteStatus
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0: moveToSendMessage()
        case 1: moveToShareContact()
        case 2: moveForSharedMedia()
        case 3: moveToCommonGroups()
        case 5: blockUser()
            
        default:
            break
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 || section == 2 || section == 5 {
            return 34
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")
        return cell?.contentView
    }
    
    //MARK:- Memory handling
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
