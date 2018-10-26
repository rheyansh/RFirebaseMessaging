//
//  ChangePasswordVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChangePasswordVC: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var textField_ConfirmPassword: UITextField!
    @IBOutlet weak var textField_NewPassword: UITextField!
    @IBOutlet weak var textField_OldPassword: UITextField!
    
    var oldPasswordString = ""
    var nwPasswordString = ""
    var confirmPasswordString = ""

    //MARK:- UIViewController Life Cycle Method
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    //MARK: - UITextFieldDelegates Methods.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.textInputMode?.primaryLanguage == "emoji") || !((textField.textInputMode?.primaryLanguage) != nil) {
            return false
        }
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= passwordMaxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next {
            let tf: UITextField? = (view.viewWithTag(textField.tag + 1) as? UITextField)
            tf?.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
        return true
    }
    
    //MARK:- Validation Method
    func isAllFieldsVerified() -> Bool {
        
        var isVerified = false
        
        let oldPassword = textField_OldPassword.text!.trimWhiteSpace
        let nwPassword = textField_NewPassword.text!.trimWhiteSpace
        let confirmPassword = textField_ConfirmPassword.text!.trimWhiteSpace
        
        oldPasswordString = oldPassword // only fot test case
        nwPasswordString = nwPassword // only fot test case
        confirmPasswordString = confirmPassword // only fot test case
        
        if oldPassword.length == 0 {
            AlertController.alert(title: blankCurrentPassword)
        } else if oldPassword.length < 8 {
            AlertController.alert(title: minPassword)
        } else if nwPassword.length == 0 {
            AlertController.alert(title: blankNewPassword)
        } else if nwPassword.length < 8 {
            AlertController.alert(title: minNewPassword)
        } else if confirmPassword.length == 0 {
            AlertController.alert(title: blankConfirmPassword)
        } else if nwPassword != confirmPassword  {
            AlertController.alert(title: mismatchNewPassowrdAndConfirmPassword)
        } else {
            isVerified = true
        }
        
        return isVerified
    }

    //MARK:- IBAction method
    @IBAction func editButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        if isAllFieldsVerified() {
            
            let newPassword = self.textField_NewPassword.text!.trimWhiteSpace
            
            RBasicUserServices.updateCurrentUserPassword(newPassword: newPassword, completionBlock: { (isSuccess, error) in
                
                if let error = error {
                    AlertController.alert(title: error.localizedDescription)
                } else {
                    if isSuccess == true {
                        AlertController.alert(title: "Password has been changed successfully.", message: "", buttons: ["OK"], tapBlock: { (_, _) in
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                }
            })
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
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
