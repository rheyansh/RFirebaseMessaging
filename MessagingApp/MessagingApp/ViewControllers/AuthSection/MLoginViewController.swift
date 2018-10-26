//
//  MLoginViewController.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import FirebaseAuth


class MLoginViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var signUpTopConstraints: NSLayoutConstraint!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var tableView: TPKeyboardAvoidingTableView!

    var emailString = ""
    var passwordString = ""
    
    //MARK:- UIViewController Life Cycle Method
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
    }
    
    //MARK: Initial methods 
    private func initialSetup() -> Void {
       
        self.loginButton.layer.cornerRadius = self.loginButton.layer.frame.height / 2
        self.signupButton.layer.cornerRadius = self.signupButton.layer.frame.height / 2
        self.signupButton.layer.borderWidth = 1
        self.signupButton.layer.borderColor = UIColor.white.cgColor

        if (kWindowWidth == 320) {
            signUpTopConstraints.constant = 40
        }
        
        if kWindowHeight < 520 {
            tableView.isScrollEnabled = true
        } else {
            tableView.isScrollEnabled = false
        }
    }

    private var isAllFieldVerified: Bool {
        
        if (emailString.trimWhiteSpace.length == 0) {
            AlertController.alert(title: blankEmail)
        } else if(!emailString.trimWhiteSpace.isEmail){
            AlertController.alert(title: invalidEmail)
        } else if(passwordString.trimWhiteSpace.length == 0){
            AlertController.alert(title: blankPassword)
        } else if(passwordString.trimWhiteSpace.length < 8){
            AlertController.alert(title: minPassword)
        } else {
            return true
        }
        return false
    }
    
    // MARK: - UITextFieldDelegate
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        if(textField.tag == 50){
            emailString = textField.text!.trimWhiteSpace
        } else {
            passwordString = textField.text!.trimWhiteSpace
        }
        
        return true;
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.textInputMode?.primaryLanguage == "emoji") || !((textField.textInputMode?.primaryLanguage) != nil) {
            return false
        }
        guard let text = textField.text else { return true }
        let maxLength = textField.tag == 50 ? emailMaxLength : passwordMaxLength
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
    
    @IBAction func forgotpasswordBtnClick(_ sender: UIButton) {
        self.view.endEditing(true)

        let forgotPasswordVC = MForgotViewController(nibName:"MForgotViewController",bundle:nil)
        self.navigationController?.pushViewController(forgotPasswordVC, animated: true)
    }
    
    @IBAction func loginAction(_ sender: Any) {
        self.view.endEditing(true)
        
        if isAllFieldVerified {

            if !FirebaseUtils.isReachable {
                return
            }
            
            ServiceHelper.hideAllHuds(false, type: .iLoader)
            
            Auth.auth().signIn(withEmail: emailString, password: passwordString) { (user, error) in
                ServiceHelper.hideAllHuds(true, type: .iLoader)
                
                if let error = error {
                    AlertController.alert(title: "Error", message: error.localizedDescription)
                } else {
                    if let user = user {
                        user.updateForRemoteNotification()
                        defaults.setValue(user.uid, forKey: pCurrentUserId)
                        APPDELEGATE.moveToHomeDashBoard()
                    }
                }
            }
        }
    }
    
    //MARK: UITableViewDataSource Methods
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return 2;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell:MLoginTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MLoginTableViewCell", for: indexPath) as! MLoginTableViewCell

        cell.loginTextField.layer.backgroundColor = UIColor.clear.cgColor
        cell.loginTextField.layer.borderColor = UIColor.white.cgColor
        cell.loginTextField.layer.borderWidth = 1;
        cell.loginTextField.layer.cornerRadius = cell.loginTextField.layer.frame.height / 2;
        cell.loginTextField.tag = indexPath.row + 50;
        cell.loginTextField.delegate = self;
       
        if (indexPath.row == 0) {
            
            cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "Email Address",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            cell.loginTextField.text = emailString
            cell.loginTextField.isSecureTextEntry = false
            cell.loginTextField.keyboardType = .emailAddress
            cell.loginTextField.returnKeyType = .next
        }else{
            
            cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "Password",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            cell.loginTextField.text = passwordString
            cell.loginTextField.isSecureTextEntry = true
            cell.loginTextField.keyboardType = .asciiCapable
            cell.loginTextField.returnKeyType = .done
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
