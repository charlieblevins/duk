//
//  AccountViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 6/26/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit
import WebKit

class AccountViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    
    @IBOutlet var containerView: UIView! = nil
    
    var webView: WKWebView?
    
    // Store credentials when submitted (before login success)
    var tempCredentials: Credentials? = nil
    
    // Store successful credentials
    var credentials: Credentials? = nil
    
    override func loadView() {
        super.loadView()
        
        // Controller
        let controller = WKUserContentController()
        controller.addScriptMessageHandler(self, name: "signInClicked")
        
        // Configuration
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        
        // WK Webview
        self.webView = WKWebView(frame: self.view.frame, configuration: config)
        self.view = self.webView
        
        // Handle navigation delegate methods
        self.webView?.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("account view")

        
        let url = NSURL(string: "http://dukapp.io")
        let request = NSURLRequest(URL: url!)
        self.webView!.loadRequest(request)
    }
    
    // Receive message from page script
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        if let data = message.body as? NSDictionary {
            print("Data received: \(data)")
            
            self.handleScriptMessage(data)
        } else {
            print("Unrecognized message format")
        }
        
    }
    
    // Receive script data and act accordingly
    func handleScriptMessage(data: NSDictionary) {
        
        switch data["action"] as! String {
        
        case "loginAttempt":
            
            // Temporarily store username and password
            self.tempCredentials = Credentials(email: data["username"] as! String, password: data["password"] as! String)
            break;
        
        default:
            print("Could not handle script action: \(data["action"])")
        }
    }

    /**
     * Access the navigation response data to determine login success/fail
     */
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        
        let status = (navigationResponse.response as! NSHTTPURLResponse).statusCode
        
        print(status)
        
        // If a 200 status AND /home is loaded AND tempCredentials are stored: assume successful login
        if status == 200 && webView.URL?.absoluteString.rangeOfString("dukapp.io/home") != nil && self.tempCredentials != nil {
            
            // Save credentials in core data
            self.tempCredentials!.save()
            
            // Save as permanenet
            self.credentials = self.tempCredentials
            
            // Remove temp
            self.tempCredentials = nil
            
        } else {
            self.tempCredentials = nil
        }
        
        // Always allow load
        decisionHandler(.Allow)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
