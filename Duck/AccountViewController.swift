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
    
    var didReqSignOut: Bool = false
    
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
        
        var request: NSMutableURLRequest? = nil
        
        print("account view")
        
        self.credentials = Credentials.fromCore()

        // If credentials exist
        if self.credentials != nil {
        
            let url = NSURL(string: "http://dukapp.io/home")
            request = NSMutableURLRequest(URL: url!)
            
            
            // Add basic auth to request header
            let loginData = "\(self.credentials!.email):\(self.credentials!.password)".dataUsingEncoding(NSUTF8StringEncoding)!
            let base64LoginString = loginData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            
            request!.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // No credentials: Login
        } else {
            let url = NSURL(string: "http://dukapp.io")
            request = NSMutableURLRequest(URL: url!)
        }
        
        self.webView!.loadRequest(request!)
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
    
    // Flag signout attempt
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.Allow)
        
        let req_url = navigationAction.request.URL?.absoluteString
        
        // If request signout page
        if req_url!.rangeOfString("dukapp.io/signout") != nil {
            self.didReqSignOut = true
        }
    }

    /**
     * Access the navigation response data to determine login success/fail
     */
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        
        let status = (navigationResponse.response as! NSHTTPURLResponse).statusCode
        let url = webView.URL?.absoluteString
        
        print(status)
        
        // If a 200 status AND /home is loaded AND tempCredentials are stored: assume successful login
        if status == 200 && url!.rangeOfString("dukapp.io/home") != nil && self.tempCredentials != nil {
            
            // Save credentials in core data
            self.tempCredentials!.save()
            
            // Save as permanenet
            self.credentials = self.tempCredentials

            
        // If loading home page and last request was signout: remove credentials
        } else if url!.rangeOfString("dukapp.io") != nil && self.didReqSignOut {
            self.credentials!.remove()
        }
        
        self.didReqSignOut = false
        
        // Remove temp credentials on every page load
        self.tempCredentials = nil
        
        // Always allow load
        decisionHandler(.Allow)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
