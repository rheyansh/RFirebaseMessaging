//
//  MACreateGroupVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MACreateGroupVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var groupAvatar: UIImageView!
    @IBOutlet weak var groupNameTextField: UITextField!
    
    var selectedUsers = [MAUser]()
    var groupInfo = MAChatRoom()
    
    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        initialSetup()
    }
    
    //MARK:- Private functions
    
    private func initialSetup() {
        
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableViewAutomaticDimension
        groupInfo.participants = selectedUsers
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
                        self.groupAvatar.image = pickedImage
                        self.groupInfo.groupImage = pickedImage
                    }
                })
            } else if index == 1 {
                
                FKMediaPicker.mediaPicker.pickMediaFromGallery(galleryBlock: { (info: [String : Any], pickedImage: UIImage?) in
                    if let pickedImage = pickedImage {
                        self.groupAvatar.image = pickedImage
                        self.groupInfo.groupImage = pickedImage
                    }
                })
            }
        }
    }
    
    @IBAction func onCreateGroupButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let groupName = groupNameTextField.text!.trimWhiteSpace
        
        if groupName.length == 0 {
            AlertController.alert(title: blankGroupName)
        } else {
            groupInfo.chatRoomName = groupName
            
            createButton.disable(true)
            tableView.isUserInteractionEnabled = false
            ProgressHUD.show()

            groupInfo.createGroup(callback: { (isSuccess, error) in
                
                ProgressHUD.dismiss()
                self.tableView.isUserInteractionEnabled = true
                self.createButton.disable(false)

                if let error = error {
                    AlertController.alert(title: error.localizedDescription)
                } else {
                    if isSuccess == true {
                        self.createButton.disable(true)
                        self.groupNameTextField.isUserInteractionEnabled = false
                        AlertController.alert(title: "Group created successfully.", message: "", buttons: ["OK"], tapBlock: { (_, _) in

                            self.navigationController?.popToRootViewController(animated: true)
                            /*let chatVC = chatSectionStoryboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
                            chatVC.chatRoom = self.groupInfo
                            self.navigationController?.pushViewController(chatVC, animated: true)*/
                        })
                    }
                }
            })
        }
    }
    //MARK:- UITableView
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(68, UITableViewAutomaticDimension)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:MASubTitleAvtarCell = tableView.dequeueReusableCell(withIdentifier: "MASubTitleAvtarCell", for: indexPath) as! MASubTitleAvtarCell
        
        let user = selectedUsers[indexPath.row]
        cell.titleLabel.text = user.fullName
        cell.avatar.userLoad(user.avatarUrl)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }
    
    //MARK:- UITextField Method
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.textInputMode?.primaryLanguage == "emoji") || !((textField.textInputMode?.primaryLanguage) != nil) {
            return false
        }
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= groupNameMaxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
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

