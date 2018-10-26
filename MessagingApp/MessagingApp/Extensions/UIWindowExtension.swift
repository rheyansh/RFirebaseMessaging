//
//  UIWindowExtensions.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

extension UIWindow {
    
    static var currentController: UIViewController? {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate?.window?.currentController
    }
    
    var currentController: UIViewController? {
        if let vc = self.rootViewController {
            return getCurrentController(vc: vc)
        }
        return nil
    }
    
    static var topController: UIViewController? {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate?.window?.topController
    }
    
    var topController: UIViewController? {
        if let vc = self.rootViewController {
            return topViewController(controller: vc)
        }
        return nil
    }
    
    func getCurrentController(vc: UIViewController) -> UIViewController {
        
        if let pc = vc.presentedViewController {
            return getCurrentController(vc: pc)
        } else if let nc = vc as? UINavigationController {
            if nc.viewControllers.count > 0 {
                return getCurrentController(vc: nc.viewControllers.last!)
            } else {
                return nc
            }
        }
        
        else {
            return vc
        }
    }
    
    func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nc = controller as? UINavigationController {
            if nc.viewControllers.count > 0 {
                return topViewController(controller: nc.viewControllers.last!)
            } else {
                return nc
            }
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
