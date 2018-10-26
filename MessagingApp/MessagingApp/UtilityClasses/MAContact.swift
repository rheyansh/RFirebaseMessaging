//
//  MAContact.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import Contacts

open class MAContact {
    
    open var firstName: String
    open var lastName: String
    open var company: String
    open var thumbnailProfileImage: UIImage?
    open var profileImage: UIImage?
    open var birthday: Date?
    open var birthdayString: String?
    open var contactId: String?
    open var phoneNumbers = [(phoneNumber: String, phoneLabel: String)]()
    open var emails = [(email: String, emailLabel: String )]()
    
    public init (contact: CNContact) {
        firstName = contact.givenName
        lastName = contact.familyName
        company = contact.organizationName
        contactId = contact.identifier
        
        if let thumbnailImageData = contact.thumbnailImageData {
            thumbnailProfileImage = UIImage(data:thumbnailImageData)
        }
        
        if let imageData = contact.imageData {
            profileImage = UIImage(data:imageData)
        }
        
        if let birthdayDate = contact.birthday {
            
            birthday = Calendar(identifier: Calendar.Identifier.gregorian).date(from: birthdayDate)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = Strings.birdtdayDateFormat
            //Example Date Formats:  Oct 4, Sep 18, Mar 9
            birthdayString = dateFormatter.string(from: birthday!)
        }
        
        for phoneNumber in contact.phoneNumbers {
            var phoneLabel = "phone"
            if let label = phoneNumber.label {
                phoneLabel = label
            }
            let phone = phoneNumber.value.stringValue
            
            phoneNumbers.append((phone,phoneLabel))
        }
        
        for emailAddress in contact.emailAddresses {
            guard let emailLabel = emailAddress.label else { continue }
            let email = emailAddress.value as String
            
            emails.append((email,emailLabel))
        }
    }
    
    func getPhoneNumbers() -> Array<String> {
        
        var numbersArray = [String]()
        
        for phoneNumber in self.phoneNumbers {
            numbersArray.append(phoneNumber.phoneNumber)
        }
      
        return numbersArray
    }
    
    func getEmails() -> Array<String> {
        var emailArray = [String]()
        for email in self.emails {
            emailArray.append(email.email)
        }
        return emailArray
    }
    
    open func displayName() -> String {
        return firstName + " " + lastName
    }
    
    open func contactInitials() -> String {
        var initials = String()
        
        if let firstNameFirstChar = firstName.first {
            initials.append(firstNameFirstChar)
        }
        
        if let lastNameFirstChar = lastName.first {
            initials.append(lastNameFirstChar)
        }
        
        return initials
    }
    
}
