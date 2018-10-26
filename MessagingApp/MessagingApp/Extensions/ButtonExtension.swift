//
//  ButtonExtension.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

extension UIButton {

    func underLine(state: UIControlState = .normal) {
        
        if let title = self.title(for: state) {
            
            let color = self.titleColor(for: state)

            let attrs = [
                NSAttributedStringKey.foregroundColor.rawValue : color ?? UIColor.blue,
                NSAttributedStringKey.underlineStyle : 1] as [AnyHashable : Any]
            
            let buttonTitleStr = NSMutableAttributedString(string: title, attributes: (attrs as! [NSAttributedStringKey : Any]))
            self.setAttributedTitle(buttonTitleStr, for: state)
        }
    }
    
    func disable(_ status: Bool, _ handleInteraction: Bool = true) {
        
        self.alpha = status ? 0.6 : 1
        
        if handleInteraction {
            self.isUserInteractionEnabled = !status
        }
    }
}

