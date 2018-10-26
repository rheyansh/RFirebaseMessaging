//
//  RContactHelper.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Contacts

struct RContactHelper {
    
    // MARK: - Contact Operations

    static func reloadContacts(_ controller: UIViewController,
                               callback: ((ContactsFetchResult) -> Void)?) {
        
        self.getContacts(controller, callback: callback)
    }
    
    private static func getContacts(_ controller: UIViewController,
                                    callback: ((ContactsFetchResult) -> Void)?) {
        
        //ContactStore is control for accessing the Contacts
        let contactsStore = CNContactStore()
        var orderedContacts = [String: [CNContact]]() //Contacts ordered in dicitonary alphabetically
        var sortedContactKeys = [String]()
        var result = ContactsFetchResult()
        
        //let error = NSError(domain: "EPContactPickerErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Contacts Access"])
        
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
            
        case .denied, .restricted:
            //User has denied the current app to access the contacts.
            
            let productName = Bundle.main.infoDictionary!["CFBundleName"]!
            
            let alert = UIAlertController(title: "Unable to access contacts", message: "\(productName) does not have access to contacts. Kindly enable it in privacy settings", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {  action in
                //result.error = error
                //callback?(result)
                controller.dismiss(animated: true, completion: {
                })
            })
            alert.addAction(okAction)
            controller.present(alert, animated: true, completion: nil)
            
        case .notDetermined:
            //This case means the user is prompted for the first time for allowing contacts
            contactsStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (granted, error) -> Void in
                //At this point an alert is provided to the user to provide access to contacts. This will get invoked if a user responds to the alert
                if (!granted ){
                    DispatchQueue.main.async(execute: { () -> Void in
                        result.error = error
                        callback?(result)
                    })
                } else {
                    self.getContacts(controller, callback: callback)
                }
            })
            
        case  CNAuthorizationStatus.authorized:
            //Authorization granted by user for this app.
            //var contactsArray = [CNContact]()
            
            do {
                
                let containerId = CNContactStore().defaultContainerIdentifier()
                let predicate: NSPredicate = CNContact.predicateForContactsInContainer(withIdentifier: containerId)
                
                // here is your contacts
                let contactArray = try CNContactStore().unifiedContacts(matching: predicate, keysToFetch: self.allowedContactKeys)

                // now group by alphabetically:-- Alphabate to contacts
                for contact in contactArray {
                    var key: String = "#"
                    //If ordering has to be happening via family name change it here.
                    if let firstLetter = contact.givenName[0..<1] , firstLetter.containsAlphabets() {
                        key = firstLetter.uppercased()
                    }
                    var contacts = [CNContact]()
                    
                    if let segregatedContact = orderedContacts[key] {
                        contacts = segregatedContact
                    }
                    
                    contacts.append(contact)
                    // sort array to it’s alphabetical order
                    let sortedContactsArray = contacts.sorted { $0.givenName < $1.givenName}
                    orderedContacts[key] = sortedContactsArray
                }
                
                sortedContactKeys = Array(orderedContacts.keys).sorted(by: <)
                if sortedContactKeys.first == "#" {
                    sortedContactKeys.removeFirst()
                    sortedContactKeys.append("#")
                }
                
                result.sortedContactKeys = sortedContactKeys
                result.contacts = contactArray
                result.orderedContacts = orderedContacts
                callback?(result)
            }
                //Catching exception as enumerateContactsWithFetchRequest can throw errors
            catch let error {
                print(error.localizedDescription)
                result.error = error
                callback?(result)
            }
        }
    }
    
    private static var allowedContactKeys: [CNKeyDescriptor] {
        //We have to provide only the keys which we have to access. We should avoid unnecessary keys when fetching the contact. Reducing the keys means faster the access.
        return [CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
    }
}

struct ContactsFetchResult {
    
    var sortedContactKeys = [String]()
    var contacts = [CNContact]()
    var orderedContacts = [String: [CNContact]]() //Contacts ordered in dicitonary alphabetically
    var error: Error?
}

