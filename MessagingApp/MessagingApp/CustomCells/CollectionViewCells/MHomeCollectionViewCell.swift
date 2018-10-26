//
//  MHomeCollectionViewCell.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MHomeCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatarButton: IndexPathButton!

    var badgeCount: UInt?  {
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
    
    var enableAvatarZoomIn = false {
        didSet {
            avatarButton.isUserInteractionEnabled = enableAvatarZoomIn
        }
    }
    
    typealias DidTapOnAvatar = (_ tappedImageView: UIImageView) -> Void
    var onTapAvatar: DidTapOnAvatar?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func onAvatarButtonAction(_ sender: IndexPathButton) {
        if let onTapAvatar = onTapAvatar {
            onTapAvatar(self.avatar)
        }
    }

}
