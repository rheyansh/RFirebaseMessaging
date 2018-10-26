//
//  VideoPlayerController.swift
//  RMessaging
//
//  Created by rajkumar.sharma on 4/25/18.
//  Copyright © 2018 Raj Sharma. All rights reserved.
//

import UIKit
import WebKit

class VideoPlayerController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var webContainer: UIView!
    private var webKitView: WKWebView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialSetup()
    }
    
    //MARK:- Public Funtions

    func loadUrl(_ url: URL) {
        self.view.bringSubview(toFront: activityIndicatorView)
        activityIndicatorView.startAnimating()
        webKitView.load(URLRequest(url: url))
    }
    
    //MARK:- Private Funtions

    private func initialSetup() {
        
        // setup WKWebView
        
        let webConfiguration = WKWebViewConfiguration()
        
        webKitView = WKWebView(frame: webContainer.bounds, configuration: webConfiguration)
        webKitView.translatesAutoresizingMaskIntoConstraints = false
        webContainer.addSubview(webKitView)
        webKitView.topAnchor.constraint(equalTo: webContainer.topAnchor).isActive = true
        webKitView.rightAnchor.constraint(equalTo: webContainer.rightAnchor).isActive = true
        webKitView.leftAnchor.constraint(equalTo: webContainer.leftAnchor).isActive = true
        webKitView.bottomAnchor.constraint(equalTo: webContainer.bottomAnchor).isActive = true
        webKitView.heightAnchor.constraint(equalTo: webContainer.heightAnchor).isActive = true
        webKitView.uiDelegate = self
        webKitView.navigationDelegate = self
    }
    
    //MARK:- IBActions
    
    @IBAction func onBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK:- WKUIDelegate
    
    func webViewDidClose(_ webView: WKWebView) {
        //        self.webKitView.stopLoading()
        //        self.webKitView.isHidden = true
    }
    
    //MARK:- WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Debug.log("loaded")
        activityIndicatorView.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicatorView.stopAnimating()
    }

    //MARK:- Memory handling

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
