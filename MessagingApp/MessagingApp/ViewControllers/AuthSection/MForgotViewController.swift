//
//  MForgotViewController.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import FirebaseAuth
class MForgotViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var footerView: UIView!
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var loginButton: UIButton!

    var emailString = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialSetup()
    }
    
    //MARK: Initial methods
    private func initialSetup() -> Void {
    
        self.loginButton.layer.cornerRadius = self.loginButton.layer.frame.height / 2
    }
    
    // MARK: - UITextFieldDelegate
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        emailString = textField.text!.trimWhiteSpace
        return true;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.textInputMode?.primaryLanguage == "emoji") || !((textField.textInputMode?.primaryLanguage) != nil) {
            return false
        }
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= emailMaxLength // Bool
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
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: UITableViewDataSource Methods
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return 1;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell:MLoginTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MLoginTableViewCell", for: indexPath) as! MLoginTableViewCell
        
        cell.loginTextField.layer.backgroundColor = UIColor.clear.cgColor
        cell.loginTextField.layer.borderColor = UIColor.white.cgColor
        cell.loginTextField.layer.borderWidth = 1;
        cell.loginTextField.layer.cornerRadius = cell.loginTextField.layer.frame.height / 2;
        cell.loginTextField.tag = indexPath.row + 50;
        cell.loginTextField.delegate = self;
        
        cell.loginTextField.attributedPlaceholder = NSAttributedString(string: "Email Address",attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        cell.loginTextField.text = emailString
        cell.loginTextField.isSecureTextEntry = false
        cell.loginTextField.keyboardType = .emailAddress
        cell.loginTextField.returnKeyType = .done
        
        return cell;
    }
    
    //MARK: UITableViewDelegate Methods
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        return 60.0;
    }

    @IBAction func forgotPassword(_ sender: Any) {
        self.view.endEditing(true)
        
        if (emailString.trimWhiteSpace.length == 0) {
            AlertController.alert(title: blankEmail)
        } else if(!emailString.isEmail) {
            AlertController.alert(title: invalidEmail)
        } else {
            
            if !FirebaseUtils.isReachable {
                return
            }
            
            loginButton.disable(true)
            tableView.isUserInteractionEnabled = false
            ProgressHUD.show()
            Auth.auth().sendPasswordReset(withEmail: emailString, completion: { (error) in
                ProgressHUD.dismiss()
                self.loginButton.disable(false)
                self.tableView.isUserInteractionEnabled = true
                if let error = error {
                    AlertController.alert(title: error.localizedDescription)
                } else {
                    AlertController.alert(title: forgotPasswordSuccess, message: "", buttons: ["OK"], tapBlock: { (_, _) in
                        self.navigationController?.popViewController(animated: true)
                    })
                }
            })
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
