//
//  AccountViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 1/20/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
    @IBOutlet weak var myWebView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("loaded account view")

        let url = NSURL(string: "http://dukapp.io")
        let req = NSURLRequest(URL: url!)
        myWebView.loadRequest(req)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
