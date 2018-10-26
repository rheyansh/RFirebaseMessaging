//
//  SearchUserTableViewCell.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

class SearchUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tickBtn: IndexPathButton!
    @IBOutlet weak var addFriendBtn: IndexPathButton!
    @IBOutlet weak var cancelFriendRequestBtn: UIButton!

    @IBOutlet weak var selectBtnView: UIView!
    @IBOutlet weak var cellImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addButton: IndexPathButton!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    typealias DidTapOnAcceptButton = () -> Void
    var onAcceptButton: DidTapOnAcceptButton?

    typealias DidTapOnRejectButton = () -> Void
    var onRejectButton: DidTapOnRejectButton?

    typealias DidTapOnAddButton = () -> Void
    var onAddButton: DidTapOnAddButton?

    
    var startLoader = false {
        
        didSet {
            
            if startLoader == true {
                addButton.isHidden = true
                activityIndicatorView.startAnimating()
            } else {
                addButton.isHidden = false
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
    
    @IBAction func onAddButtonAction(_ sender: IndexPathButton) {
        
        if let onAddButton = onAddButton {
            onAddButton()
        }
    }
    
    @IBAction func onAcceptButtonAction(_ sender: IndexPathButton) {
        if let onAcceptButton = onAcceptButton {
            onAcceptButton()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
