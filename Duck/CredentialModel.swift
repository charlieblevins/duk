//
//  File.swift
//  Duck
//
//  Created by Charlie Blevins on 2/12/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import CoreData
import UIKit

struct Credentials {
    let email: String
    let password: String
    
    init (email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    init(fromCoreData data: AnyObject) {
        self.email = data.valueForKey("email") as! String
        self.password = data.valueForKey("password") as! String
    }
    
    // Load from core data
    init?() {
        
        let data = Util.fetchCoreData("Login", predicate: nil)
        
        if data.count > 0 {
            self.email = data[0].valueForKey("email") as! String
            self.password = data[0].valueForKey("password") as! String
        } else {
            return nil
        }
    }
    
    // Save login/pass in core data
    // TODO: Do not allow this function to save multiple
    func save () {
        
        Util.deleteCoreDataForEntity("Login")
        
        // 1. Get managed object context
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // 2. Create new object as marker entity
        let entity = NSEntityDescription.entityForName("Login", inManagedObjectContext:managedContext)
        let login = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        // 3. Add username and password
        login.setValue(self.email, forKey: "email")
        login.setValue(self.password, forKey: "password")
        
        // 4. Save the marker object
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save login: \(error), \(error.userInfo)")
        }
    }
}

enum CredentialError: ErrorType {
    case NoLoginData
}