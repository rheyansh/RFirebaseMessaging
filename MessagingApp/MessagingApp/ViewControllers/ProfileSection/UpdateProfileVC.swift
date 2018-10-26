//
//  UpdateProfileVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

extension UITextField {
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedStringKey.foregroundColor: newValue!])
        }
    }
}

class UpdateProfileVC: UIViewController ,UITextFieldDelegate {
    
    @IBOutlet weak var imageBtn: UIButton!
    @IBOutlet weak var textField_FirstName: UITextField!
    @IBOutlet weak var imageView_Profile: UIImageView!
    @IBOutlet weak var textField_LastName: UITextField!
    @IBOutlet weak var editButton: UIButton!
    
    var modalUser: MAUser?
    var nwImage: UIImage?
    
    private var isEditingInProgress = false {
    
        didSet {
            
            textField_FirstName.isUserInteractionEnabled  = isEditingInProgress
            textField_LastName.isUserInteractionEnabled = isEditingInProgress
            imageBtn.isUserInteractionEnabled = isEditingInProgress
        }
    }
    
    //MARK:- UIViewController Life Cycle Method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetUp()
    }
    
    //MARK:- Helper method
    
    private func initialSetUp() {
        
        isEditingInProgress = false
        guard let modalUser = modalUser else {
            return
        }
        textField_FirstName.text = modalUser.firstName
        textField_LastName.text = modalUser.lastName
        self.imageView_Profile.userLoad(modalUser.avatarUrl)
    }
    
    @IBAction func pickerbtnAction(_ sender: UIButton) {
        self.view.endEditing(true)

        AlertController.actionSheet(title: "", message: "Please select", sourceView: self.view, buttons: ["Take Photo", "Choose from gallery", "Cancel"]) { (action, index) in
            
            if index == 0 {
                
                FKMediaPicker.mediaPicker.pickMediaFromCamera(cameraBlock: { (info: [String : Any], pickedImage: UIImage?) in
                    if let pickedImage = pickedImage {
                        self.imageView_Profile.image = pickedImage
                        self.nwImage = pickedImage
                    }
                })
            } else if index == 1 {
                
                FKMediaPicker.mediaPicker.pickMediaFromGallery(galleryBlock: { (info: [String : Any], pickedImage: UIImage?) in
                    if let pickedImage = pickedImage {
                        self.imageView_Profile.image = pickedImage
                        self.nwImage = pickedImage
                    }
                })
            }
        }
    }
    
    //MARK:- UITextField Method

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.textInputMode?.primaryLanguage == "emoji") || !((textField.textInputMode?.primaryLanguage) != nil) {
            return false
        }
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= nameMaxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next {
            let tf: UITextField? = (view.viewWithTag(textField.tag + 1) as? UITextField)
            tf?.becomeFirstResponder()
        }
        else {
            view.endEditing(true)
        }
        return true
    }
    
    //MARK:- IBAction Method
    
    @IBAction func editButtonAction(_ sender: UIButton) {
        view.endEditing(true)

        if !FirebaseUtils.isReachable {
            return
        }
        
        if editButton.isSelected {
            
            let firstName = textField_FirstName.text?.trimWhiteSpace
            let lastName = textField_LastName.text?.trimWhiteSpace

            if (firstName?.length == 0) {
                AlertController.alert(title: blankFirstName)
                return
            } else if(lastName?.length == 0) {
                AlertController.alert(title: blankLastName)
                return
            }
            
            editButton.disable(true)
            ProgressHUD.show()
            RBasicUserServices.updateCurrentUser(firstName: firstName!, lastName: lastName!, completionBlock: { (isSuccess, error) in

                ProgressHUD.dismiss()

                if let _ = self.nwImage {
                    // image is uploading.
                } else {
                    if let error = error {
                        self.editButton.disable(false)
                        AlertController.alert(title: error.localizedDescription)
                    } else {
                        if isSuccess {
                            AlertController.alert(title: "Profile updated successfully.", message: "", buttons: ["OK"], tapBlock: { (_, _) in
                                self.navigationController?.popViewController(animated: true)
                            })
                        } else {
                            self.editButton.disable(false)
                        }
                    }
                }
            })

            if let nwImage = nwImage {
                
                nwImage.currentUserAvatarUpload(track: { (progress) in
                    Debug.log("Upload progress: \(String(describing: progress))")
                }, callback: { (mediaUploadResult) in
                    if let error = mediaUploadResult.error {
                        self.editButton.disable(false)
                        AlertController.alert(title: error.localizedDescription)
                    } else {
                        if mediaUploadResult.isSuccess {
                            self.nwImage = nil
                            AlertController.alert(title: "Profile updated successfully.", message: "", buttons: ["OK"], tapBlock: { (_, _) in
                                self.navigationController?.popViewController(animated: true)
                            })
                        } else {
                            self.editButton.disable(false)
                        }
                    }
                })
            } else {
                editButton.disable(false)
            }
        } else {
            self.editButton.setTitle("Save", for: UIControlState.normal)
            editButton.isSelected = true
            self.isEditingInProgress = editButton.isSelected
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
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
