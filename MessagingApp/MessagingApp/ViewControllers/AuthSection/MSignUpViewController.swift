//  MSignUpViewController.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//


import UIKit
import FirebaseAuth
import Firebase

class MSignUpViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var staticContentLinkLabel: MZSelectableLabel!
    
    var modalUser = MAUser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialSetup()
    }
    
    //MARK: Initial methods
    private func initialSetup() -> Void {
        
        self.registerButton.layer.cornerRadius = self.registerButton.layer.frame.height / 2
        
        let tNcString = "Terms and Conditions"
        let privacyPolicyString = "Privacy Policy"

        self.staticContentLinkLabel.makeSelectable(tNcString, in: self.staticContentLinkLabel.attributedText?.string)
        self.staticContentLinkLabel.makeSelectable(privacyPolicyString, in: self.staticContentLinkLabel.attributedText?.string)

        staticContentLinkLabel.selectionHandler = {range,string in
            
            if string == tNcString {
                
                self.view.endEditing(true)
                
                let genericContentVC = mainStoryboard.instantiateViewController(withIdentifier: "GenericContentVC") as! GenericContentVC
                genericContentVC.contentType = .ContentType_TOS
                self.navigationController?.pushViewController(genericContentVC, animated: true)
                
            } else if string == privacyPolicyString {
                self.view.endEditing(true)
                let genericContentVC = mainStoryboard.instantiateViewController(withIdentifier: "GenericContentVC") as! GenericContentVC
                genericContentVC.contentType = .ContentType_PrivacyPolicy
                self.navigationController?.pushViewController(genericContentVC, animated: true)
            }
        }
    }
    
    private var isAllFieldVerified: Bool {
        
        var isVerified = false
        
        if (modalUser.firstName.length == 0) {
            AlertController.alert(title: blankFirstName)
        } else if(modalUser.lastName.length == 0) {
            AlertController.alert(title: blankLastName)
        } else if(modalUser.email.length == 0) {
            AlertController.alert(title: blankEmail)
        } else if(!modalUser.email.isEmail){
            AlertController.alert(title: invalidEmail)
        } else if(modalUser.password.length == 0){
            AlertController.alert(title: blankPassword)
        } else if(modalUser.password.length < 8){
            AlertController.alert(title: minPassword)
        } else if(modalUser.confirmPassword.length == 0){
            AlertController.alert(title: blankConfirmPassword)
        } else if(!(modalUser.password == modalUser.confirmPassword)) {
            AlertController.alert(title: mismatchPassowrdAndConfirmPassword)
        } else {
            isVerified = true
        }
        
        return isVerified
    }
    
    //MARK: - TextField Delegates >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        switch textField.tag {
        case 100:
            modalUser.firstName = textField.text!.trimWhiteSpace
            break
        case 101:
            modalUser.lastName = textField.text!.trimWhiteSpace
            break
        case 102:
            modalUser.email = textField.text!.trimWhiteSpace
            break
        case 103:
            modalUser.password = textField.text!.trimWhiteSpace
            break
        case 104:
            modalUser.confirmPassword = textField.text!.trimWhiteSpace
            break
        default:
            break
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.textInputMode?.primaryLanguage == "emoji") || !((textField.textInputMode?.primaryLanguage) != nil) {
            return false
        }
        
        guard let text = textField.text else { return true }
        var maxLength = emailMaxLength
        if textField.tag == 103 || textField.tag == 104 {
            maxLength = passwordMaxLength
        }
        let newLength = text.count + string.count - range.length
        return newLength <= maxLength // Bool
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
    
    //MARK: IBAction Methods    
    @IBAction func registerBtnAction(_ sender: Any) {
        self.view.endEditing(true)

        if isAllFieldVerified {
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            registerButton.disable(true)
            tableView.isUserInteractionEnabled = false

            modalUser.register(callback: { (createUserResult) in
                self.registerButton.disable(false)
                self.tableView.isUserInteractionEnabled = true

                if createUserResult.isSuccess {
                    if let user = createUserResult.user {
                        defaults.setValue(user.uid, forKey: pCurrentUserId)
                        APPDELEGATE.moveToHomeDashBoard()
                    }
                }
            })
        }
    }
    
    @IBAction func crossButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: UITableViewDataSource Methods
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return 5;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell:MLoginTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MLoginTableViewCell", for: indexPath) as! MLoginTableViewCell

        cell.loginTextField.layer.backgroundColor = UIColor.clear.cgColor
        cell.loginTextField.layer.borderColor = UIColor.white.cgColor
        cell.loginTextField.layer.borderWidth = 1;
        cell.loginTextField.layer.cornerRadius = cell.loginTextField.layer.frame.height / 2;
        cell.loginTextField.tag = indexPath.row + 100;
        cell.loginTextField.delegate = self;
        cell.loginTextField.isSecureTextEntry = false
        cell.loginTextField.autocapitalizationType = .none

        switch indexPath.row {
        case 0:
            cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "First Name",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            cell.loginTextField.text = modalUser.firstName
            cell.loginTextField.keyboardType = .default
            cell.loginTextField.returnKeyType = .next
            cell.loginTextField.autocapitalizationType = .words
            break
        case 1:
            cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "Last Name",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            cell.loginTextField.text = modalUser.lastName
            cell.loginTextField.keyboardType = .default
            cell.loginTextField.returnKeyType = .next
            cell.loginTextField.autocapitalizationType = .words
            break
        case 2:
            cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "Email Address",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            cell.loginTextField.text = modalUser.email
            cell.loginTextField.keyboardType = .emailAddress
            cell.loginTextField.returnKeyType = .next
            break
        case 3:
            cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "Password",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            cell.loginTextField.text = modalUser.password
            cell.loginTextField.isSecureTextEntry = true
            cell.loginTextField.keyboardType = .asciiCapable
            cell.loginTextField.returnKeyType = .next
            break
        case 4:
            cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "Confirm Password",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            cell.loginTextField.text = modalUser.confirmPassword
            cell.loginTextField.isSecureTextEntry = true
            cell.loginTextField.keyboardType = .asciiCapable
            cell.loginTextField.returnKeyType = .done
            break
        default:
            break
        }
        
        return cell;
    }
    
    //MARK: UITableViewDelegate Methods
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        return 62.0;
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
