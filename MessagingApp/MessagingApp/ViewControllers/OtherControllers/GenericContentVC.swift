//
//  GenericContentVC.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit


enum ContentType {
    case ContentType_Unknown, ContentType_TOS, ContentType_PrivacyPolicy, ContentType_AboutUs
}

class GenericContentVC: UIViewController {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var webView: UIWebView!
    @IBOutlet weak var navBarTitleLabel: UILabel!
    
    var contentType: ContentType = .ContentType_Unknown

    var isFromMenu = false {
        
        didSet {
            
        }
    }
    
    // MARK: - UIViewController Life Cycle Functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
    }
    
    // MARK: - Private Functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    fileprivate func initialSetup() {
        
        // load local file
        if let url = Bundle.main.url(forResource: "DummyHtml", withExtension: "html") {
            webView.loadRequest(URLRequest(url: url))
        }
        
        if contentType == .ContentType_TOS {
            navBarTitleLabel.text = "Terms and Conditions"
        } else if contentType == .ContentType_PrivacyPolicy {
            navBarTitleLabel.text = "Privacy Policy"
        }
        
        self.activityIndicatorView.isHidden = true
    }
    
    // MARK: - IBActions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UIWebView Delegates

    @objc func webViewDidStartLoad(_ webView: UIWebView) {
        /*DispatchQueue.main.sync(execute: { () -> Void in
            self.activityIndicatorView.startAnimating()
        })*/
    }
    
    @objc func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        /*DispatchQueue.main.sync(execute: { () -> Void in
            self.activityIndicatorView.stopAnimating()
        })*/
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        /*DispatchQueue.main.sync(execute: { () -> Void in
            self.activityIndicatorView.stopAnimating()
        })*/
    }
    
    // MARK: - Memory Managment >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
