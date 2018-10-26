//
//  UIViewExtension.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable var corner: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            
            self.layer.cornerRadius = newValue
            self.clipsToBounds = true
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            
            self.layer.borderWidth = newValue
            self.clipsToBounds = true
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor.clear
        }
        set {
            
            self.layer.borderColor = newValue?.cgColor
            self.layer.borderWidth = 1.0
        }
    }
    
    func cardShape(_ color: UIColor = UIColor.darkGray) {
        
        self.layer.cornerRadius = 2.0
        self.clipsToBounds = true

        self.aroundShadow(color)
    }
    
    func shadow(_ color: UIColor = UIColor.darkGray) {
        self.layer.shadowColor = color.cgColor;
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 1
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
    }
    
    func aroundShadow(_ color: UIColor = UIColor.darkGray) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowRadius = 3
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0.3, height: 0.3)
    }
    
    func setBorder(_ color: UIColor, borderWidth: CGFloat) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = borderWidth
        self.clipsToBounds = true
    }
    
    func vibrate() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.02
        animation.repeatCount = 2
        animation.speed = 0.5
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 2.0, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 2.0, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
    
    func shake() {
        self.transform = CGAffineTransform(translationX: 5, y: 5)
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    func setTapperTriangleShape(_ color:UIColor) {
        // Build a triangular path
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0,y: 0))
        path.addLine(to: CGPoint(x: 40,y: 40))
        path.addLine(to: CGPoint(x: 0,y: 100))
        path.addLine(to: CGPoint(x: 0,y: 0))
        
        // Create a CAShapeLayer with this triangular path
        let mask = CAShapeLayer()
        mask.frame = self.bounds
        mask.path = path.cgPath
        
        // Mask the view's layer with this shape
        self.layer.mask = mask
        
        self.backgroundColor = color
        
        // Transform the view for tapper shape
        self.transform = CGAffineTransform(rotationAngle: CGFloat(270) * CGFloat(Double.pi / 2) / 180.0)
    }
    
    class func loadNib<T: UIView>(_ viewType: T.Type) -> T {
        let className = String.className(viewType)
        return Bundle(for: viewType).loadNibNamed(className, owner: nil, options: nil)!.first as! T
    }
    
    class func loadNib() -> Self {
        return loadNib(self)
    }
}
