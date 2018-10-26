//
//  MACircleSettingsVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class MACircleSettingsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var groupAvatar: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var exitCircleButton: UIButton!
    @IBOutlet weak var notificationSwitch: UISwitch!
    
    var groupMembers = [MAUser]()
    var groupInfo: MAChatRoom?
    var loadedMessages = [Message]()

    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        initialSetup()
    }
    
    //MARK:- Private functions
    
    private func initialSetup() {
        
        tableView.estimatedRowHeight = 47
        tableView.rowHeight = UITableViewAutomaticDimension
        
        guard let group = self.groupInfo else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        groupNameTextField.text = group.chatRoomName
        groupAvatar.normalLoad(group.avatarUrl)
        self.groupMembers = group.participants
        self.notificationSwitch.isOn = true
        self.notificationSwitch.isHidden = true
        checkForMute()
    }
    
    private func uploadGroupImage(_ image: UIImage) {
        guard let group = self.groupInfo else { return }
        self.groupAvatar.image = image
        image.uploadGroupAvatar(false, groupId: group.parentKey, track: nil, callback: nil)
    }
    
    private func checkForMute() {
        
        guard let group = self.groupInfo else { return }

        FirebaseUtils.currentUser { (user) in
            RBasicUserServices.getMutedAudience(user.uid, callback: { (result) in
                
                if result.error == nil {
                    self.notificationSwitch.isHidden = false
                    if result.mutedGroupsIds.contains(group.parentKey) {
                        self.notificationSwitch.isOn = false
                    } else {
                        self.notificationSwitch.isOn = true
                    }
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    //MARK:- IBActions
    
    @IBAction func onBackButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onUploadGroupAvatarButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        AlertController.actionSheet(title: "", message: "Please select", sourceView: self.view, buttons: ["Take Photo", "Choose from gallery", "Cancel"]) { (action, index) in
            
            if index == 0 {
                
                FKMediaPicker.mediaPicker.pickMediaFromCamera(cameraBlock: { (info: [String : Any], pickedImage: UIImage?) in
                    if let pickedImage = pickedImage {
                        self.uploadGroupImage(pickedImage)
                    }
                })
            } else if index == 1 {
                
                FKMediaPicker.mediaPicker.pickMediaFromGallery(galleryBlock: { (info: [String : Any], pickedImage: UIImage?) in
                    if let pickedImage = pickedImage {
                        self.uploadGroupImage(pickedImage)
                    }
                })
            }
        }
    }
    
    @IBAction func onSharedMediaButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let sharedMediaBaseVC = sharedMediaSectionStoryboard.instantiateViewController(withIdentifier: "MASharedMediaBaseVC") as! MASharedMediaBaseVC
        sharedMediaBaseVC.isHasMessages = true
        sharedMediaBaseVC.loadedMessages = loadedMessages
        self.navigationController?.pushViewController(sharedMediaBaseVC, animated: true)
    }
    
    @IBAction func onAddMemberButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let selectUsersVC = circleSectionStoryboard.instantiateViewController(withIdentifier: "MASelectUsersVC") as! MASelectUsersVC
        selectUsersVC.groupInfo = self.groupInfo
        selectUsersVC.screenType = .SelectUsersScreenType_AddMemberInGroup
        self.navigationController?.pushViewController(selectUsersVC, animated: true)
        
        selectUsersVC.onAddedNewParticipants = {
            (arrayParticipants) -> Void in
            
            guard let group = self.groupInfo else {
                return
            }
            
            Message.getConversationId(forParticipantId: group.parentKey, completion: { (conversationId) in
                
                if conversationId.length != 0 {
                    for user in arrayParticipants {
                        Message.checkAndAddGroupMemberIfNotAddedInGroupChat(group.parentKey, user, conversationId)
                    }
                }
            })
            self.groupMembers.append(contentsOf: arrayParticipants)
            self.tableView.reloadData()
        }
    }

    @IBAction func onExitCircleButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        AlertController.alert(title: "Are you sure you want to exit circle?", message: "", buttons: ["NO", "YES"], tapBlock: { (_, index) in
            if (index != 0) {
                
                guard let group = self.groupInfo else { return }
                group.exitGroup(callback: { (isSuccess, error) in
                    
                    if let error = error {
                        TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
                    } else {
                        if isSuccess {
                            TinyToast.shared.show(message: "You are no longer connected to this group", duration: .veryShort)
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                })
            }
        })
    }
    
    @IBAction func onSwitch(_ sender: UISwitch) {
        self.view.endEditing(true)
        guard let group = self.groupInfo else { return }
        
        RBasicUserServices.muteAudience(!sender.isOn, audienceType: .roomType_Group, audienceId: group.parentKey) { (isSuccess, error) in
        }
    }
    
    //MARK:- UITableView
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(47, UITableViewAutomaticDimension)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:MASubTitleAvtarCell = tableView.dequeueReusableCell(withIdentifier: "MASubTitleAvtarCell", for: indexPath) as! MASubTitleAvtarCell
        
        let user = groupMembers[indexPath.row]
        
        if self.groupInfo?.adminId == user.userId {
            let nameString = user.fullName + " (Admin)"
            cell.titleLabel.attributedText = nameString.getAttributedString("(Admin)", color: UIColor.darkGray, font: UIFont(name: "AvenirNext-Medium", size: 12)!)
        } else {
            cell.titleLabel.text = user.fullName
        }
        
        if let firstNameFirstChar = user.fullName.first {
            cell.alphaLabel.text = "\(firstNameFirstChar)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        
        let user = groupMembers[indexPath.row]
        
        if let currentUser = Auth.auth().currentUser {
            if currentUser.uid == user.userId {
                return
            } else {
                let participantDetailsVC = self.storyboard?.instantiateViewController(withIdentifier: "MAChatParticipantDetailsVC") as! MAChatParticipantDetailsVC
                participantDetailsVC.participantInfo = user
                self.navigationController?.pushViewController(participantDetailsVC, animated: true)
            }
        }
    }
    
    // MARK:- --->UIResponder function
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //MARK:- Memory handling
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

