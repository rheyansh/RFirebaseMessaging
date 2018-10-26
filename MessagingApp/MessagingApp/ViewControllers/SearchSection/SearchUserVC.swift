//  SearchUserVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Firebase

class SearchUserVC: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    private var dataSourceArray = [MAUser]()

    //MARK:- UIViewController Life Cycle Method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetUp()
    }
    
    //MARK:- Helper Method
    
    private func initialSetUp() {
        searchTextField.becomeFirstResponder()
        let placeHolderName  = "Search Username or Contacts"
        
        // Set the Font
        searchTextField.attributedPlaceholder = NSAttributedString(string: placeHolderName,attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
    }
    
    private func loadPage() {
        fetchListFromFireBase()
    }
    
    private func fetchListFromFireBase() {
        
        let text = searchTextField.text?.trimWhiteSpace
        if text?.length != 0 {
            
            searchButton.isUserInteractionEnabled = false
            searchTextField.isUserInteractionEnabled = false
            
            RFBDataService.searchUsers(text: text!, callback: { (result) in
                self.searchButton.isUserInteractionEnabled = true
                self.searchTextField.isUserInteractionEnabled = true
                
                if let error = result.error {
                    AlertController.alert(title: error.localizedDescription)
                } else {
                    self.dataSourceArray.removeAll()
                    self.tableView.reloadData()
                    self.dataSourceArray = result.users
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    private func sendFriendRequest(_ user: MAUser, _ cell: SearchUserTableViewCell) {
        
        //self.view.endEditing(true)
        cell.startLoader = true
        
        FBFriendsServices.sendFriendRequest(user: user, callback: { (result) in
            cell.startLoader = false
            if result.isSuccess {
                let message = "Friend request sent to \(user.fullName)"
                TinyToast.shared.show(message: message, duration: .veryShort)
                if let index = self.dataSourceArray.index(where: {$0.userId == user.userId}) {
                    self.dataSourceArray.remove(at: index)
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    // MARK: - IBActions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    @IBAction func onSearchButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        loadPage()
    }
    
    //MARK: - UITableView Delegate and Datasource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        return 65
    }
    
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSourceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
        
        let user = dataSourceArray[indexPath.row]
        
        cell.nameLabel.text = user.fullName
        cell.addButton.indexPath = indexPath
        cell.cellImageView.userLoad(user.avatarUrl)

        cell.onAddButton = {
            () -> Void in
            self.sendFriendRequest(user, cell)
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }
    
    //MARk:- UITextField Delegates
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.count + string.count - range.length
        return newLength <= 60 // Bool
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
