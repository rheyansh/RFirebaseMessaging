//
//  MASharedMediaCollectionCell.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class MASharedMediaCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var mediaContentLabel: UILabel!
    @IBOutlet weak var buttonToPlay: IndexPathButton!

    typealias DidTapOnPlayOptionButton = () -> Void
    var onPlayOptionButton: DidTapOnPlayOptionButton?

    @IBAction func onPlayOptionButtonAction(_ sender: IndexPathButton) {
     
        if let onPlayOptionButton = onPlayOptionButton {
            onPlayOptionButton()
        }
    }
}
