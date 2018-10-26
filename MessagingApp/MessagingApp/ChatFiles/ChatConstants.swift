//
//  ChatConstants.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

enum MessageType {
    case photo
    case text
    case video
}

enum MessageOwner {
    case sender
    case receiver
}

enum ShowExtraView {
    case contacts
    case profile
    case preview
    case map
}

class RoundedImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let radius: CGFloat = self.bounds.size.width / 2.0
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
}
