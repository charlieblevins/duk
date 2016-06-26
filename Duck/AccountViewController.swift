//
//  AccountViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 6/26/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("account view")
        
        let url = NSURL(string: "http://dukapp.io")
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
