//
//  MAShareContactVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Contacts

class MAShareContactVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
        
        @IBOutlet weak var tableView: UITableView!
        @IBOutlet weak var searchBar: UISearchBar!

        var sortedContactKeys = [String]()
        var orderedContacts = [String : Array<CNContact>]()
        var mainArray = [CNContact]()
        var filteredArray = [CNContact]()
        var isSearchActive = false
        
        typealias DidSelectContact = (_ contact: MAContact) -> Void
        var onSelectContact: DidSelectContact?
        
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
                 AlertController.alert(title: error.localizedDescription)
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
    
     private func shareContact(toContact: MAContact) {
        self.view.endEditing(true)

        if let onSelectContact = onSelectContact {
            onSelectContact(toContact)
        }
        
        self.navigationController?.popViewController(animated: false)
     }
    
    //MARK:- IBActions
    
    @IBAction func onBackButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
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
             self.shareContact(toContact: contact)
         } else {
             let sectionIndexTitle = sortedContactKeys[indexPath.section]
             if let arraySubData = orderedContacts[sectionIndexTitle] {
                 let contact = MAContact(contact: arraySubData[indexPath.row])
                 self.shareContact(toContact: contact)
             }
         }
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
    
    // MARK:- --->UISearchBar Delegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        Debug.log("searchBarTextDidBeginEditing \(String(describing: searchBar.text))")
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        Debug.log("searchBarTextDidEndEditing \(String(describing: searchBar.text))")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchForText("")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        Debug.log("textDidChange \(searchText)")
        searchForText(searchText)
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
