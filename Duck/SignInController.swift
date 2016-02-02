//
//  AccountViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 1/20/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit
import CoreData

class SignInController: UIViewController {

    
    // Interface elements
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var SignInBtn: UIButton!
    @IBOutlet weak var SignUpBtn: UIButton!
    @IBOutlet weak var ForgotPassBtn: UIButton!
    
    var email: String? = nil
    var password: String? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func SignIn(sender: UIButton) {

        // Basic validation
        email = emailField.text!
        if email == nil {
            popValidationAlert("Password is required.", title: "Missing password")
            return
        }
        
        if isValidEmail(email!) == false {
            popValidationAlert("Please make sure your email is correct.", title: "Invalid or missing email address")
            return
        }
        
        password = passwordField.text
        if password == nil {
            popValidationAlert("Password is required.", title: "Missing password")
            return
        }
        
        // Verify login credentials
        let apiRequest = ApiRequest()
        apiRequest.checkCredentials(email!, password: password!, successHandler: handleCredentSuccess, failureHandler: handleCredentFail)
    }
    
    func handleCredentSuccess () {
        
        // Save email/password in core data
        saveCredentials(email!, password: password!)
    }
    
    func handleCredentFail (message: String?) {
        print("Handle credent FAIL")
    }
    
    // Save login/pass in core data
    // TODO: Do not allow this function to save multiple
    func saveCredentials (email: String, password: String) {
        
        Util.deleteCoreDataForEntity("Login")
        
        // 1. Get managed object context
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // 2. Create new object as marker entity
        let entity = NSEntityDescription.entityForName("Login", inManagedObjectContext:managedContext)
        let login = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        // 3. Add username and password
        login.setValue(email, forKey: "email")
        login.setValue(password, forKey: "password")
        
        // 4. Save the marker object
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save login: \(error), \(error.userInfo)")
        }
    }
    
    func flashMessage (text: String) {
        
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
