//
//  ChatVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//


import UIKit
import Photos
import Firebase

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet var inputBar: UIView!
    @IBOutlet weak var navTitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override var inputAccessoryView: UIView? {
        get {
            self.inputBar.frame.size.height = self.barHeight
            self.inputBar.clipsToBounds = true
            return self.inputBar
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    var items = [Message]()
    let barHeight: CGFloat = 50
    var participant: MAUser?
    private var chatRoomType: ChatRoomType = .roomType_Individual
    
    // assign nothing if it is one to one chat
    // assign the group object if it is group chat
    var chatRoom: MAChatRoom?

    //MARK: ViewController lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.inputBar.backgroundColor = UIColor.clear
        self.view.layoutIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.showKeyboard(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        //Message.markMessagesRead(forUserID: self.participant!.userId)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetUp()
    }
    
    //MARK: Methods
    func initialSetUp() {
        
        if let chatRoom = self.chatRoom {
            chatRoomType = .roomType_Group
            self.navTitleLabel.text = "\(chatRoom.chatRoomName) (\(chatRoom.participantsIds.count))"
            
            chatRoom.fetchMembers { (result) in
                
                if let error = result.error {
                    TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
                } else {
                    
                    self.chatRoom?.participants = result.users
                    self.tableView.reloadData()
                    
                    Message.getConversationId(forParticipantId: chatRoom.parentKey, completion: { (conversationId) in
                        for user in (self.chatRoom?.participants)! {
                            Message.checkAndAddGroupMemberIfNotAddedInGroupChat(chatRoom.parentKey, user, conversationId)
                        }
                    })
                }
            }
            
            self.fetchData(chatRoom.parentKey)

        } else if let participant = self.participant {
            chatRoomType = .roomType_Individual
            self.navTitleLabel.text = participant.firstName
            self.fetchData(participant.userId)
        } else {
            dismissSelf()
        }
        
        self.tableView.estimatedRowHeight = self.barHeight
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.contentInset.bottom = self.barHeight
        self.tableView.scrollIndicatorInsets.bottom = self.barHeight
    }
    
    //Downloads messages
    func fetchData(_ idToFetch: String) {
        
        Message.downloadAllMessages(forUserID: idToFetch, completion: {[weak weakSelf = self] (message) in
            weakSelf?.items.append(message)
            weakSelf?.items.sort{ $0.timestamp < $1.timestamp }
            DispatchQueue.main.async {
                if let state = weakSelf?.items.isEmpty, state == false {
                    weakSelf?.tableView.reloadData()
                    weakSelf?.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: false)
                }
            }
        })
        //Message.markMessagesRead(forUserID: self.participant!.userId)
    }
    
    //Hides current viewcontroller
    @objc func dismissSelf() {
        self.view.endEditing(true)
        if let navController = self.navigationController {
            
            if let _ = backViewController() as? MACreateGroupVC {
                navController.popToRootViewController(animated: true)
            } else {
                navController.popViewController(animated: true)
            }
        }
    }
    
    func composeMessage(type: MessageType, content: Any)  {
        
        FirebaseUtils.currentUser { (user) in
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            let message = Message.init(type: type, content: content, owner: .sender, senderIdInGroup: user.uid, timestamp: Int(Date().timeIntervalSince1970), isRead: false, videoThumbnail: "")
            
            Message.send(message: message, roomType: self.chatRoomType, friend: self.participant, chatRoom: self.chatRoom, completion: {(_) in
            })
        }
    }
    
    func animateExtraButtons(toHide: Bool)  {
        switch toHide {
        case true:
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        default:
            self.bottomConstraint.constant = -50
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        }
    }
    
    private func getUserToShow(_ keyId: String?) -> MAUser? {
        
        if self.chatRoomType == .roomType_Individual {
            return self.participant
        } else if chatRoomType == .roomType_Group {
            guard let keyId = keyId,
                let chatRoom = self.chatRoom else {
                    return nil
            }
            
            let user = chatRoom.participants.filter{ $0.userId == keyId }.first
            
            return user
        }
        
        return nil
    }
    
    //MARK:- IBActions
    
    @IBAction func onSettingButtonAction(_ sender: UIButton) {
        
        if self.chatRoomType == .roomType_Group {
            let circleSettingsVC = connectionSectionStoryboard.instantiateViewController(withIdentifier: "MACircleSettingsVC") as! MACircleSettingsVC
            circleSettingsVC.groupInfo = self.chatRoom
            circleSettingsVC.loadedMessages = self.items
            self.navigationController?.pushViewController(circleSettingsVC, animated: true)
        } else {
            let participantDetailsVC = connectionSectionStoryboard.instantiateViewController(withIdentifier: "MAChatParticipantDetailsVC") as! MAChatParticipantDetailsVC
            participantDetailsVC.participantInfo = participant
            participantDetailsVC.participantInfo = participant
            participantDetailsVC.loadedMessages = self.items
            participantDetailsVC.isHasMessages = true
            self.navigationController?.pushViewController(participantDetailsVC, animated: true)
        }
    }
    
    @IBAction func onBackButtonAction(_ sender: UIButton) {
        dismissSelf()
    }
    
    @IBAction func showMessage(_ sender: Any) {
       self.animateExtraButtons(toHide: true)
    }
    
    @IBAction func selectGallery(_ sender: Any) {
        self.animateExtraButtons(toHide: true)
        
        FKMediaPicker.mediaPicker.pickImageFromDevice { (mediaInfo, image) in
            
            if let pickedImage = mediaInfo[UIImagePickerControllerEditedImage] as? UIImage {
                self.composeMessage(type: .photo, content: pickedImage)
            } else {
                let pickedImage = mediaInfo[UIImagePickerControllerOriginalImage] as! UIImage
                self.composeMessage(type: .photo, content: pickedImage)
            }
        }
    }
    
    @IBAction func selectCamera(_ sender: Any) {
        
        FKMediaPicker.mediaPicker.pickVideoFromDevice { (mediaInfo, image) in
            
            Debug.log("mediaInfo>>>   \(mediaInfo)")

            if let videoURL = mediaInfo[UIImagePickerControllerMediaURL] as? URL {
                Debug.log("videoURL:\(String(describing: videoURL))")
                self.composeMessage(type: .video, content: videoURL)
            }
        }
    }
    
    @IBAction func selectLocation(_ sender: Any) {
        
    }
    
    @IBAction func showOptions(_ sender: Any) {
        self.animateExtraButtons(toHide: false)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        if let text = self.inputTextField.text {
            if text.length > 0 {
                self.composeMessage(type: .text, content: self.inputTextField.text!)
                self.inputTextField.text = ""
            }
        }
    }
    
    //MARK: NotificationCenter handlers
    @objc func showKeyboard(notification: Notification) {
        if let frame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let height = frame.cgRectValue.height
            self.tableView.contentInset.bottom = height
            self.tableView.scrollIndicatorInsets.bottom = height
            if self.items.count > 0 {
                self.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    //MARK: Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if self.items[indexPath.row].type == .video {
            return 200
        }
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.items[indexPath.row].owner {
        case .receiver:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Receiver", for: indexPath) as! ReceiverCell
            cell.clearCellData()
            
            let messageDate = Date.init(timeIntervalSince1970: TimeInterval(self.items[indexPath.row].timestamp))
            cell.dateLabel.text = messageDate.timeAgo

            switch self.items[indexPath.row].type {
            case .text:
                cell.message.text = self.items[indexPath.row].content as! String
            case .photo:
                if let image = self.items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                } else {
                    cell.messageBackground.image = UIImage.init(named: "loading")
                    self.items[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
                
            case .video:
                
                cell.webKitBGView.isHidden = false
                
                if let url = self.items[indexPath.row].videoThumbnail {
                    cell.videoThumbnailImageView.normalLoad(url)
                }
                
                cell.onVideoThumbnailButton = {
                    () -> Void in
                    if let url = URL(string: self.items[indexPath.row].content as! String) {
                        if url.isValid {
                            let playerController = VideoPlayerController(nibName: "VideoPlayerController", bundle: nil)
                            playerController.modalTransitionStyle = .crossDissolve
                            self.navigationController?.pushViewController(playerController, animated: true)
                            playerController.loadUrl(url)
                        }
                    }
                }
            }
            
            return cell
        case .sender:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Sender", for: indexPath) as! SenderCell
            cell.clearCellData()
            
            let messageDate = Date.init(timeIntervalSince1970: TimeInterval(self.items[indexPath.row].timestamp))
            cell.dateLabel.text = messageDate.timeAgo
            
            if let userToLoad = getUserToShow(self.items[indexPath.row].senderIdInGroup) {
                cell.profilePic.userLoad(userToLoad.avatarUrl)
                cell.participantNameLabel.text = userToLoad.firstName
            }
            
            switch self.items[indexPath.row].type {
            case .text:
                cell.message.text = self.items[indexPath.row].content as! String
            case .photo:
                if let image = self.items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                } else {
                    cell.messageBackground.image = UIImage.init(named: "loading")
                    self.items[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
            case .video:
                
                cell.webKitBGView.isHidden = false
                
                if let url = self.items[indexPath.row].videoThumbnail {
                    cell.videoThumbnailImageView.normalLoad(url)
                }
                
                cell.onVideoThumbnailButton = {
                    () -> Void in
                    if let url = URL(string: self.items[indexPath.row].content as! String) {
                        if url.isValid {
                            let playerController = VideoPlayerController(nibName: "VideoPlayerController", bundle: nil)
                            playerController.modalTransitionStyle = .crossDissolve
                            self.navigationController?.pushViewController(playerController, animated: true)
                            playerController.loadUrl(url)
                        }
                    }
                }
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.inputTextField.resignFirstResponder()
        switch self.items[indexPath.row].type {
        case .photo:
            if let _ = self.items[indexPath.row].image {
                
                let cell = tableView.cellForRow(at: indexPath)
                
                if let cell = cell as? SenderCell {
                    self.zoomImageIn(cell.messageBackground)
                } else if let cell = cell as? ReceiverCell {
                    self.zoomImageIn(cell.messageBackground)
                }
            }
        default: break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

