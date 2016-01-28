//
//  AccountViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 1/20/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class SignInController: UIViewController {

    
    // Interface elements
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var SignInBtn: UIButton!
    @IBOutlet weak var SignUpBtn: UIButton!
    @IBOutlet weak var ForgotPassBtn: UIButton!
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        print("loaded sign in view")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func SignIn(sender: UIButton) {
        print("sign in action")
        let email = emailField.text!
        let pass = passwordField.text!
        
        // Basic validation
        if isValidEmail(email) == false {
            popValidationAlert("Please make sure your email is correct.", title: "Invalid or missing email address")
        }
        
        if pass == "" {
            popValidationAlert("Password is required.", title: "Missing password")
        }
        
        // POST to api
        let urlPath: String = "http://dukapp.io/api/authCheck"
        let url: NSURL = NSURL(string: urlPath)!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        
        // Add basic auth to request url
        let loginString = NSString(format: "%@:%@", email, pass)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        let queue:NSOperationQueue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            print(response)
        })
        
        // If error, display message
        
        // If success, pop this view and load My Markers with alert window "Are you sure you want to publish...?"
    }
    
    // TODO: Check for top-level domain (eg. .com, .io, etc)
    func isValidEmail(testStr:String) -> Bool {
        // println("validate calendar: \(testStr)")
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    
    func popValidationAlert(text:String, title:String) {
        let alertController = UIAlertController(title: title,
            message: text,
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(okAction)
        
        presentViewController(alertController, animated: true, completion: nil)
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