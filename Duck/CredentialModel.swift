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

class Credentials {
    let email: String
    let password: String
    
    static var sharedInstance: Credentials? = nil
    
    init (email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    init(fromCoreData data: AnyObject) {
        self.email = data.value(forKey: "email") as! String
        self.password = data.value(forKey: "password") as! String
    }
    
    // Load from core data
    init?() {
        
        // Cached
        if Credentials.sharedInstance != nil {
            self.email = Credentials.sharedInstance!.email
            self.password = Credentials.sharedInstance!.password
            return
        }
        
        // Core Data lookup
        let data = Util.fetchCoreData("Login", predicate: nil)
        
        if (data?.count)! > 0 {
            self.email = data?[0].value(forKey: "email") as! String
            self.password = data?[0].value(forKey: "password") as! String
            
            Credentials.sharedInstance = self
        } else {
            return nil
        }
    }
    
    // Save login/pass in core data
    // TODO: Do not allow this function to save multiple
    func save () {
        
        Util.deleteCoreDataForEntity("Login")
        
        // 1. Get managed object context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // 2. Create new object as marker entity
        let entity = NSEntityDescription.entity(forEntityName: "Login", in:managedContext)
        let login = NSManagedObject(entity: entity!, insertInto: managedContext)
        
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
    
    // Remove credentials from core data (sign out)
    func remove () {
        Util.deleteCoreDataForEntity("Login")
        Credentials.sharedInstance = nil
    }
    
    // Load latest login credentials from core data
    static func fromCore () -> Credentials? {
        let query_res = Util.fetchCoreData("Login", predicate: nil)
        
        if  query_res?.count == 0 {
            return nil
        }
        
        return Credentials(fromCoreData: (query_res?[0])!)
    }
}

enum CredentialError: Error {
    case noLoginData
}
