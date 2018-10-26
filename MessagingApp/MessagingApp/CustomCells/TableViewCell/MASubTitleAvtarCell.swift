//
//  MASubTitleAvtarCell.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MASubTitleAvtarCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var avatarButton: IndexPathButton!
    @IBOutlet weak var statusButton: IndexPathButton!
    @IBOutlet weak var alphaLabel: UILabel!
    
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}

