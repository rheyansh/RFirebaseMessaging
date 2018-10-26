//
//  MAContactListVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Contacts

class MAContactListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sortedContactKeys = [String]()
    var orderedContacts = [String : Array<CNContact>]()
    var mainArray = [CNContact]()
    var filteredArray = [CNContact]()
    var isSearchActive = false

    //MARK:- UIViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        initialSetup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isSearchActive = false
        self.tableView.reloadData()
    }
    
    //MARK:- Public functions
    
    func searchForText(_ text: String) {
        
        if text.trimWhiteSpace.length != 0 {
            isSearchActive = true
            filteredArray = mainArray.filter {
                $0.givenName.contains(text.trimWhiteSpace)
                    || $0.familyName.contains(text.trimWhiteSpace)
            }
            
            self.tableView.reloadData()
        } else {
            isSearchActive = false
            self.tableView.reloadData()
        }
    }
    
    //MARK:- private functions
    
    private func initialSetup() {
        
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableViewAutomaticDimension
        
        RContactHelper.reloadContacts(self) { (result) in
            
            if let error = result.error {
                TinyToast.shared.show(message: error.localizedDescription, duration: .veryShort)
            } else {
                self.mainArray = result.contacts
                self.filteredArray = self.mainArray
                self.sortedContactKeys = result.sortedContactKeys
                self.orderedContacts = result.orderedContacts
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    private func sendInivitation(toContact: MAContact) {
        
        var invitationArray = [String]()
        invitationArray.append(contentsOf: toContact.getEmails())
        invitationArray.append(contentsOf: toContact.getPhoneNumbers())
        
        if invitationArray.count == 0 {
            TinyToast.shared.show(message: "No data found to invite", duration: .veryShort)
            return
        }
        
        let cancelTitle = "Cancel"
        invitationArray.append(cancelTitle)
        AlertController.actionSheet(title: "Invite", message: "", sourceView: self.view, buttons: invitationArray) { (action, index) in
            let buttonTitle = invitationArray[index]
            if buttonTitle == cancelTitle {
                // Do nothing
            } else {
                let productName = Bundle.main.infoDictionary!["CFBundleName"]!
                let message = "\(productName) invitation"
                Debug.log("message>>>  \(buttonTitle)")
                
                if buttonTitle.isEmail {
                    RGeneralActions.action.sendMail(recipients: [buttonTitle], subject: message, body: iTunesAppLink,  block: nil)
                } else {
                    let phoneNumber = buttonTitle.extractNumber
                    RGeneralActions.action.sendSMS(recipients: [phoneNumber], subject: message, body: iTunesAppLink,  block: nil)
                }
            }
        }
    }
    
    //MARK:- UITableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if isSearchActive {
            return 1
        } else {
            return sortedContactKeys.count
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(68, UITableViewAutomaticDimension)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearchActive {
            return filteredArray.count
        } else {
            let sectionIndexTitle = sortedContactKeys[section]
            return orderedContacts[sectionIndexTitle]!.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:MAContactCell = tableView.dequeueReusableCell(withIdentifier: "MAContactCell", for: indexPath) as! MAContactCell
        
        if isSearchActive {
            let contact = MAContact(contact: filteredArray[indexPath.row])
            cell.updateContactsinUI(contact, indexPath: indexPath)
        } else {
            let sectionIndexTitle = sortedContactKeys[indexPath.section]
            if let arraySubData = orderedContacts[sectionIndexTitle] {
                
                let contact = MAContact(contact: arraySubData[indexPath.row])
                cell.updateContactsinUI(contact, indexPath: indexPath)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isSearchActive {
            let contact = MAContact(contact: filteredArray[indexPath.row])
            self.sendInivitation(toContact: contact)
        } else {
            let sectionIndexTitle = sortedContactKeys[indexPath.section]
            if let arraySubData = orderedContacts[sectionIndexTitle] {
                let contact = MAContact(contact: arraySubData[indexPath.row])
                self.sendInivitation(toContact: contact)
            }
        }
        
        guard let friendBaseVC = self.parent?.parent?.parent as? MAFriendBaseVC else {
            return
        }
        friendBaseVC.dismissKeyboard()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if isSearchActive {
            return nil
        } else {
            let cell:MAContactCell = tableView.dequeueReusableCell(withIdentifier: "MAContactHeaderCell") as! MAContactCell
            cell.contactTextLabel.text = sortedContactKeys[section]
            return cell.contentView
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if isSearchActive {
            return nil
        } else {
            return sortedContactKeys
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSearchActive {
            return 0
        } else {
            return 28
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
