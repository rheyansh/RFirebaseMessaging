//
//  ImageViewExtension.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit

extension UIImageView {
    
    //@@@@ Load from actual url string
    
    func normalLoad(_ string: String) {
        
        if let url = URL(string: string) {
            //self.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder")!, options: .refreshCached)
            self.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder")!)
        } else {
            self.image = UIImage(named: "placeholder")!
        }
    }

    func userLoad(_ string: String) {
        
        if let url = URL(string: string) {
            
            self.sd_setImage(with: url, placeholderImage: UIImage(named: "userPlaceholder")!, options: .refreshCached)
            
        } else {
            self.image = UIImage(named: "userPlaceholder")!
        }
    }
    
    func userLoadUrl(_ url: URL?) {
        
        if let url = url {
            self.sd_setImage(with: url, placeholderImage: UIImage(named: "userPlaceholder")!, options: .refreshCached)
        } else {
            self.image = UIImage(named: "userPlaceholder")!
        }
    }
    
    //@@@@ Load by foramtting the url string for image resizing.
    //The image will load based on height and width of imageview on which it is loading.
    //Default placeholder image will be there while on loading
    
    func load(_ urlString:String) {
        
        //normalLoad(urlString)
        
        load(self.frame.size.height, width: self.frame.size.width, urlString: urlString, placeHolderImage: UIImage(named: "placeholder")!)
    }
    
    //@@@@ Load by formatting the url string for image resizing.
    //The image will load based on height and width of imageview on which it is loading.
    //Passed placeholder image will be there while on loading
    
    func load(_ urlString:String, placeHolderImage: UIImage) {
        
        load(self.frame.size.height, width: self.frame.size.width, urlString: urlString, placeHolderImage: placeHolderImage)
    }
    
    //@@@@ Load by foramtting the url string for image resizing.
    //The image will load based on passed height and width from server.
    //Default placeholder image will be there while on loading
    
    func load(_ height:CGFloat, width:CGFloat, urlString:String) {
        
        load(height, width: width, urlString: urlString, placeHolderImage: UIImage(named: "placeholder")!)
    }
    
    //@@@@ Load by foramtting the url string for image resizing.
    //The image will load based on passed height and width from server.
    //Placeholder image will be there based on passed argument while on loading
    
    func load(_ height:CGFloat, width:CGFloat, urlString:String, placeHolderImage:UIImage) {
        
        normalLoad(urlString)
    }
}
