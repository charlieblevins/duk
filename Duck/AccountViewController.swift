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
    
    // Flag if sign out reguested. If true, successful 
    // load of root (/) page means logout was successful
    var didReqSignOut: Bool = false
    
    // If true, pop to previous view on sign in success
    var signInSuccessHandler: ((_ credentials: Credentials) -> Void)? = nil
    
    override func loadView() {
        super.loadView()
        
        // Controller
        let controller = WKUserContentController()
        controller.add(self, name: "signInClicked")
        
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
        
            let url = URL(string: "http://dukapp.io/home")
            request = NSMutableURLRequest(url: url!)
            
            
            // Add basic auth to request header
            let loginData = "\(self.credentials!.email):\(self.credentials!.password)".data(using: String.Encoding.utf8)!
            let base64LoginString = loginData.base64EncodedString(options: .lineLength64Characters)
            
            request!.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // No credentials: Login
        } else {
            let url = URL(string: "http://dukapp.io")
            request = NSMutableURLRequest(url: url!)
        }
        
        self.webView!.load(request! as URLRequest)
    }
    
    // Receive message from page script
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if let data = message.body as? NSDictionary {
            print("Data received: \(data)")
            
            self.handleScriptMessage(data)
        } else {
            print("Unrecognized message format")
        }
        
    }
    
    // Receive script data and act accordingly
    func handleScriptMessage(_ data: NSDictionary) {
        
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
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
        
        let req_url = navigationAction.request.url?.absoluteString
        
        // If request signout page
        if req_url!.range(of: "dukapp.io/signout") != nil {
            self.didReqSignOut = true
        }
    }

    /**
     * Access the navigation response data to determine login success/fail
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        let status = (navigationResponse.response as! HTTPURLResponse).statusCode
        let url = webView.url?.absoluteString
        
        print(status)
        
        // If a 200 status AND /home is loaded AND tempCredentials are stored: assume successful login
        if status == 200 && url!.range(of: "dukapp.io/home") != nil && self.tempCredentials != nil {
            
            // Save credentials in core data
            self.tempCredentials!.save()
            
            // Save as permanenet
            self.credentials = self.tempCredentials
            
            // Remove this view and call success handler
            if self.signInSuccessHandler != nil {
                //navigationController?.popViewControllerAnimated(false)
                self.signInSuccessHandler!(self.credentials!)
                self.signInSuccessHandler = nil
            }
            
        // If loading home page and last request was signout: remove credentials
        } else if url!.range(of: "dukapp.io") != nil && self.didReqSignOut {
            self.credentials!.remove()
        }
        
        self.didReqSignOut = false
        
        // Remove temp credentials on every page load
        self.tempCredentials = nil
        
        // Always allow load
        decisionHandler(.allow)
    }

    /**
     * Catch failed load
     */
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("terminated")
        
        alertLoadFailed(error as NSError)
    }
    
    func alertLoadFailed(_ error: NSError) {
        
        var message = error.localizedDescription
        
        // newline
        message = "\(message) \n\n"
        
        message = "\(message) Your feedback makes Duk better. Tap \"Feedback\" to let us know about problems with the app."
        
        let alertController = UIAlertController(title: "Something went wrong...",
                                                message: message,
                                                preferredStyle: .alert)
        
        // Allow back navigation
        let backAction = UIAlertAction(title: "Back", style: .default, handler: {
            alertAction in
            self.previousView()
        })
        
        alertController.addAction(backAction)
        
        // Allow feedback
        let fbAction = UIAlertAction(title: "Feedback", style: .default, handler: {
            alertAction in
            UIApplication.shared.openURL(URL(string:"http://dukapp.io/feedback")!)
        })
        
        alertController.addAction(fbAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Return to previous view
    func previousView () {
        navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
