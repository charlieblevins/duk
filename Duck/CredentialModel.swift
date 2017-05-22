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
    let id: String
    
    static var sharedInstance: Credentials? = nil
    
    init (email: String, password: String, id: String) {
        self.email = email
        self.password = password
        self.id = id
    }
    
    // Load from core data
    init?() {
        
        // Cached
        if let cached = Credentials.sharedInstance {
            self.email = cached.email
            self.password = cached.password
            self.id = cached.id
            return
        }
        
        // Core Data lookup
        let data = Util.fetchCoreData("Login", predicate: nil)
        
        if (data?.count)! > 0 {
            
            guard let email = data?[0].value(forKey: "email") as? String else {
                return nil
            }
            self.email = email
            
            guard let password = data?[0].value(forKey: "password") as? String else {
                return nil
            }
            self.password = password
            
            guard let id = data?[0].value(forKey: "id") as? String else {
                return nil
            }
            self.id = id
            
            Credentials.sharedInstance = self
        } else {
            return nil
        }
    }
    
    // Save login/pass in core data
    // TODO: Do not allow this function to save multiple
    func save () {
        
        self.remove()
        
        // 1. Get managed object context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // 2. Create new object as marker entity
        let entity = NSEntityDescription.entity(forEntityName: "Login", in:managedContext)
        let login = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        // 3. Add username and password
        login.setValue(self.email, forKey: "email")
        login.setValue(self.password, forKey: "password")
        login.setValue(self.id, forKey: "id")
        
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

}

enum CredentialError: Error {
    case noLoginData
}
