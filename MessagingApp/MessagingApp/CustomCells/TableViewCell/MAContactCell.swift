//
//  MAContactCell.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

public enum SubtitleContactCellValue {
    case phoneNumber
    case email
    case birthday
    case organization
}

class MAContactCell: UITableViewCell {
    
    @IBOutlet weak var contactTextLabel: UILabel!
    //@IBOutlet weak var contactDetailTextLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactInitialLabel: UILabel!
    @IBOutlet weak var contactContainerView: UIView!
    
    var contact: MAContact?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateInitialsColorForIndexPath(_ indexpath: IndexPath) {
        //Applies color to Initial Label
        let colorArray = [Colors.amethystColor,Colors.asbestosColor,Colors.emeraldColor,Colors.peterRiverColor,Colors.pomegranateColor,Colors.pumpkinColor,Colors.sunflowerColor]
        let randomValue = (indexpath.row + indexpath.section) % colorArray.count
        contactInitialLabel.backgroundColor = colorArray[randomValue]
    }
    
    func updateContactsinUI(_ contact: MAContact, indexPath: IndexPath, subtitleType: SubtitleContactCellValue = .phoneNumber) {
        self.contact = contact
        //Update all UI in the cell here
        self.contactTextLabel?.text = contact.displayName()
        updateSubtitleBasedonType(subtitleType, contact: contact)
        if contact.thumbnailProfileImage != nil {
            self.contactImageView?.image = contact.thumbnailProfileImage
            self.contactImageView.isHidden = false
            self.contactInitialLabel.isHidden = true
        } else {
            self.contactInitialLabel.text = contact.contactInitials()
            updateInitialsColorForIndexPath(indexPath)
            self.contactImageView.isHidden = true
            self.contactInitialLabel.isHidden = false
        }
    }
    
    func updateSubtitleBasedonType(_ subtitleType: SubtitleContactCellValue , contact: MAContact) {
        
        /*switch subtitleType {
            
        case SubtitleContactCellValue.phoneNumber:
            let phoneNumberCount = contact.phoneNumbers.count
            
            if phoneNumberCount == 1  {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneNumber)"
            }
            else if phoneNumberCount > 1 {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneNumber) and \(contact.phoneNumbers.count-1) more"
            }
            else {
                self.contactDetailTextLabel.text = Strings.phoneNumberNotAvaialable
            }
        case SubtitleContactCellValue.email:
            let emailCount = contact.emails.count
            
            if emailCount == 1  {
                self.contactDetailTextLabel.text = "\(contact.emails[0].email)"
            }
            else if emailCount > 1 {
                self.contactDetailTextLabel.text = "\(contact.emails[0].email) and \(contact.emails.count-1) more"
            }
            else {
                self.contactDetailTextLabel.text = Strings.emailNotAvaialable
            }
        case SubtitleContactCellValue.birthday:
            self.contactDetailTextLabel.text = contact.birthdayString
        case SubtitleContactCellValue.organization:
            self.contactDetailTextLabel.text = contact.company
        }*/
    }
    
}

//MARK: Color Constants
struct Colors {
    static let emeraldColor = UIColor(red: (46/255), green: (204/255), blue: (113/255), alpha: 1.0)
    static let sunflowerColor = UIColor(red: (241/255), green: (196/255), blue: (15/255), alpha: 1.0)
    static let pumpkinColor = UIColor(red: (211/255), green: (84/255), blue: (0/255), alpha: 1.0)
    static let asbestosColor = UIColor(red: (127/255), green: (140/255), blue: (141/255), alpha: 1.0)
    static let amethystColor = UIColor(red: (155/255), green: (89/255), blue: (182/255), alpha: 1.0)
    static let peterRiverColor = UIColor(red: (52/255), green: (152/255), blue: (219/255), alpha: 1.0)
    static let pomegranateColor = UIColor(red: (192/255), green: (57/255), blue: (43/255), alpha: 1.0)
}

//MARK: String Constants
struct Strings {
    static let birdtdayDateFormat = "MMM d"
    static let contactsTitle = "Contacts"
    static let phoneNumberNotAvaialable = "No phone numbers available"
    static let emailNotAvaialable = "No emails available"
    static let bundleIdentifier = "EPContactsPicker"
    static let cellNibIdentifier = "EPContactCell"
}
