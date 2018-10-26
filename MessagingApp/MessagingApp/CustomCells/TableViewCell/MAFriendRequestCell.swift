//
//  MAFriendRequestCell.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MAFriendRequestCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var acceptButton: IndexPathButton!
    @IBOutlet weak var rejectButton: IndexPathButton!
    @IBOutlet weak var avatarButton: IndexPathButton!

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    typealias DidTapOnAcceptButton = () -> Void
    var onAcceptButton: DidTapOnAcceptButton?
    
    typealias DidTapOnRejectButton = () -> Void
    var onRejectButton: DidTapOnRejectButton?
    
    var enableAvatarZoomIn = false {
        didSet {
            avatarButton.isUserInteractionEnabled = enableAvatarZoomIn
        }
    }
    
    typealias DidTapOnAvatar = (_ tappedImageView: UIImageView) -> Void
    var onTapAvatar: DidTapOnAvatar?
    
    var startLoader = false {
        
        didSet {
            
            if startLoader == true {
                acceptButton.isHidden = true
                rejectButton.isHidden = true
                activityIndicatorView.startAnimating()
            } else {
                acceptButton.isHidden = false
                rejectButton.isHidden = false
                activityIndicatorView.stopAnimating()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func onRejectButtonAction(_ sender: IndexPathButton) {
        
        if let onRejectButton = onRejectButton {
            onRejectButton()
        }
    }
    
    @IBAction func onAcceptButtonAction(_ sender: IndexPathButton) {
        if let onAcceptButton = onAcceptButton {
            onAcceptButton()
        }
    }
    
    @IBAction func onAvatarButtonAction(_ sender: IndexPathButton) {
        if let onTapAvatar = onTapAvatar {
            onTapAvatar(self.avatar)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
