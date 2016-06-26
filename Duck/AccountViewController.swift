//
//  AccountViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 6/26/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit
import WebKit

class AccountViewController: UIViewController, WKScriptMessageHandler {
    
    @IBOutlet var containerView: UIView! = nil
    
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        
        
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.addScriptMessageHandler(self, name: "signInClicked")
        config.userContentController = controller
        self.webView = WKWebView(frame: self.view.frame, configuration: config)
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("account view")

        
        let url = NSURL(string: "http://dukapp.io")
        let request = NSURLRequest(URL: url!)
        self.webView!.loadRequest(request)
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print("RECIEVED MESSAGE: \(message)")
        
        if let data = message.body as? NSDictionary {
            
            // Temporarily store username and password
            let creds = Credentials(email: data["username"] as! String, password: data["password"] as! String)
        } else {
            print("Unrecognized message format")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
