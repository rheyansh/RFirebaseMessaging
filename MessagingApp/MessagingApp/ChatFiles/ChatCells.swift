//
//  ChatCells.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class SenderCell: UITableViewCell {
    
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var messageBackground: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var participantNameLabel: UILabel!
    @IBOutlet weak var webKitBGView: UIView!
    @IBOutlet weak var videoThumbnailImageView: UIImageView!
    
    @IBOutlet weak var videoThumbnailButton: IndexPathButton!
    
    typealias DidTapOnVideoThumbnailButton = () -> Void
    var onVideoThumbnailButton: DidTapOnVideoThumbnailButton?

    func clearCellData()  {
        self.participantNameLabel.text = nil
        self.dateLabel.text = nil
        self.message.text = nil
        self.message.isHidden = false
        self.messageBackground.image = nil
        self.webKitBGView.isHidden = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.message.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5)
        self.messageBackground.layer.cornerRadius = 15
        self.messageBackground.clipsToBounds = true
        self.webKitBGView.isHidden = true
    }
    
    //MARK:- IBActions
    
    @IBAction func onVideoThumbnailButtonAction(_ sender: IndexPathButton) {
        
        if let onVideoThumbnailButton = onVideoThumbnailButton {
            onVideoThumbnailButton()
        }
    }
    
}

class ReceiverCell: UITableViewCell {
    
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var messageBackground: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var webKitBGView: UIView!
    @IBOutlet weak var videoThumbnailImageView: UIImageView!
    @IBOutlet weak var videoThumbnailButton: IndexPathButton!
    
    typealias DidTapOnVideoThumbnailButton = () -> Void
    var onVideoThumbnailButton: DidTapOnVideoThumbnailButton?

    func clearCellData()  {
        self.dateLabel.text = nil
        self.message.text = nil
        self.message.isHidden = false
        self.webKitBGView.isHidden = true
        self.messageBackground.image = nil
        self.webKitBGView.isHidden = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.message.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5)
        self.messageBackground.layer.cornerRadius = 15
        self.messageBackground.clipsToBounds = true
        self.webKitBGView.isHidden = true
    }
    
    //MARK:- IBActions

    @IBAction func onVideoThumbnailButtonAction(_ sender: IndexPathButton) {
        
        if let onVideoThumbnailButton = onVideoThumbnailButton {
            onVideoThumbnailButton()
        }
    }
}

