//
//  MUserProfileTableViewCell.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MUserProfileTableViewCell: UITableViewCell {

    @IBOutlet weak var swtichBtn: UISwitch!
    @IBOutlet weak var buttonArrow: UIButton!
    @IBOutlet weak var circle_ImageView: UIImageView!
    @IBOutlet weak var userProfile_Label: UILabel!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var shadowLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!

    var badgeCount: Int?  {
        didSet {
            badgeLabel.isHidden = true
            
            guard let badgeCount = badgeCount else {
                return
            }
            
            if badgeCount > 0 {
                badgeLabel.isHidden = false
                if badgeCount > 99 {
                    self.badgeLabel.text = "99+"
                    return
                }
                self.badgeLabel.text = "\(badgeCount)"
                self.badgeLabel.isHidden = false
            } else {
                self.badgeLabel.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
