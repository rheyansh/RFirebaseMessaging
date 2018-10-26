//
//  UIViewControllerExtension.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

public extension UIViewController {
    
    var isModal: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
    
    public func moveUIComponentWithValue(_ value: CGFloat, forLayoutConstraint: NSLayoutConstraint, forDuration: TimeInterval) {
        UIView.beginAnimations("MoveView", context: nil)
        UIView.setAnimationCurve(.easeInOut)
        UIView.setAnimationDuration(forDuration)
        forLayoutConstraint.constant = value
        self.view.layoutSubviews()
        self.view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    public func animateUIComponentWithValue(_ value: CGFloat, forLayoutConstraint: NSLayoutConstraint, forDuration: TimeInterval) {
        
        forLayoutConstraint.constant = value
        
        UIView.animate(withDuration: forDuration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.view.layoutSubviews()
            self.view.layoutIfNeeded()
            
        }) { (Bool) -> Void in
            // do anything on completion
        }
    }
    
    func backViewController() -> UIViewController? {
        if let stack = self.navigationController?.viewControllers {
            for count in 0...stack.count - 1 {
                if(stack[count] == self) {
                    Debug.log("viewController     \(stack[count-1])")
                    return stack[count-1]
                }
            }
        }
        return nil
    }
    
    func getToolBarWithDoneButton() -> UIToolbar {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = kAppColor
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(doneBarButtonAction(_:)))
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                          target: nil,
                                          action: nil)
        
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true

        return toolBar;

    }
    
    @objc private func doneBarButtonAction(_ button : UIButton) {
        view.endEditing(true)
    }
    
    /*func checkIfLocationServicesEnabled() {
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
                
            case .denied:
                
                let _ = AlertViewController.alert("App Permission Denied", message: "To re-enable, please go to Settings and turn on Location Service for this app. We will be using the \"Financial District\" as your default location.", buttons: ["YES", "NO"], tapBlock: { (alertAction, index) in
                    if index == 0 {
                        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    }
                })
                
                break
            case .notDetermined, .restricted:
                Debug.log("No access")
                let _ = AlertViewController.alert("", message: "Unable to update location, Please enable Location Services from your smartphone's settings menu. We will be using the \"Financial District\" as your default location.", buttons: ["YES", "NO"], tapBlock: { (alertAction, index) in
                    if index == 0 {
                        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    }
                })
                break
            case .authorizedAlways, .authorizedWhenInUse:
                logInfo("Access")
            }
        } else {
            
            let _ = AlertViewController.alert("", message: "Unable to update location, Please enable Location Services from your smartphone's settings menu. We will be using the \"Financial District\" as your default location.", buttons: ["YES", "NO"], tapBlock: { (alertAction, index) in
                if index == 0 {
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                }
            })
        }
    }
    
    func addressString(location: CLLocation, completionBlock: @escaping (String?) -> Void?) ->Void  {
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            
            if error != nil {
                Debug.log("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let placemark = placemarks![0]
                
                //address = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
                
                let addressString = placemark.name
                //Debug.log("placemarks>>>>>>>>>>   \(placemarks)")
                // see more info via log for--- placemark, placemark.addressDictionary, placemark.region, placemark.country, placemark.locality (Extract the city name), placemark.name, placemark.ocean, placemark.postalCode, placemark.subLocality, placemark.location
                completionBlock(addressString)
            } else {
                Debug.log("Problem with the data received from geocoder")
            }
        })

    }*/

    func zoomImageIn(_ imageView: UIImageView) {
        
        // Create image info
        let imageInfo = JTSImageInfo()
        imageInfo.image = imageView.image
        imageInfo.referenceRect = imageView.frame
        imageInfo.referenceView = imageView.superview

        // Setup view controller
        let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .image, backgroundStyle: .scaled)
        imageViewer?.show(from: self, transition: .fromOriginalPosition)
    }

    internal func getAlphabetical(_ dataArray:Array<MAUser>) -> (alphabetizedDictionary: Dictionary<String, Array<MAUser>>, sectionIndexTitles: Array<String>) {
        
        var sectionIndexTitles = [String]()
        var alphabetizedDictionary = [String : Array<MAUser>]()

        // sort array to it’s alphabetical order
        let sortedArray = dataArray.sorted { $0.userName < $1.userName}
        
        var groupedDict = [String : Array<MAUser>]()
        var groupedDictKeys = [String]()
        
        for user in sortedArray {
            
            let fullString = user.userName.trimWhiteSpace
            
            if fullString.length != 0 {
                let firstChar = fullString.substringToIndex(1).uppercased()
                
                if let userArray = groupedDict[firstChar] {
                    var nwArray = userArray
                    nwArray.append(user)
                    groupedDict[firstChar] = nwArray
                } else {
                    groupedDict[firstChar] = [user]
                    groupedDictKeys.append(firstChar)
                }
            }
        }
        
        alphabetizedDictionary = groupedDict
        sectionIndexTitles = groupedDictKeys
        
        return (alphabetizedDictionary, sectionIndexTitles)
    }
}
