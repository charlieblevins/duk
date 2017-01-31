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
    var tempUser: String? = nil
    var tempPass: String? = nil
    
    // Store successful credentials
    var credentials: Credentials? = nil
    
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
        
        self.credentials = Credentials()

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
            self.tempUser = data["username"] as? String
            self.tempPass = data["password"] as? String
            break;
        
        default:
            print("Could not handle script action: \(data["action"])")
        }
    }

    /**
     * Access the navigation response data to determine login success/fail
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        // Always allow load
        decisionHandler(.allow)
        
        guard let response = navigationResponse.response as? HTTPURLResponse else {
            print("Could not get response")
            return
        }
        let headers = response.allHeaderFields as Dictionary
        
        let login = headers["login_success"] as? String
        let logout = headers["logout_success"] as? String
        
        if login == "true" {
            
            guard let user_id = headers["user_id"] as? String else {
                print("Login success header present but not user id present")
                return
            }
            
            guard let temp_user = self.tempUser, let temp_pass = self.tempPass else {
                print("No temp credentials. Cannot store new login")
                return
            }
            
            // Save credentials in core data
            let cred = Credentials(email: temp_user, password: temp_pass, id: user_id)
            cred.save()
            
            // Save as permanenet
            self.credentials = cred
            
            // Remove this view and call success handler
            if self.signInSuccessHandler != nil {
                //navigationController?.popViewControllerAnimated(false)
                self.signInSuccessHandler!(self.credentials!)
                self.signInSuccessHandler = nil
            }
            
        } else if logout == "true" {
            self.credentials?.remove()
        }
        
        // Remove temp credentials on every page load
        self.tempUser = nil
        self.tempPass = nil
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
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
