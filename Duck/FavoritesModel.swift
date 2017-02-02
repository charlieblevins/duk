//
//  FavoritesModel.swift
//  Duck
//
//  Created by Charlie Blevins on 1/30/17.
//  Copyright © 2017 Charlie Blevins. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Favorite: NSObject {
    
    var public_id: String
    
    init (_ public_id: String) {
        self.public_id = public_id
    }
    
    func save () {
        
        // 1. Get managed object context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // 2. Create new object as marker entity
        let entity = NSEntityDescription.entity(forEntityName: "Favorites", in:managedContext)
        let favorite = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        // 3. Add data to marker object (and validate)
        favorite.setValue(public_id, forKey: "public_id")
        
        // 4. Save the marker object
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
            return
        }
    }
    
    func delete () {
        
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        req.entity = NSEntityDescription.entity(forEntityName: "Favorites", in: managedContext)
        req.includesPropertyValues = false
        
        // Query by timestamp
        let predicate = NSPredicate(format: "public_id = %@", public_id)
        req.predicate = predicate
        
        var results: [AnyObject]
        
        do {
            results = try managedContext.fetch(req)
            
            for result in results {
                managedContext.delete(result as! NSManagedObject)
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            return
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("save of deleted context failed: \(error.localizedDescription)")
            return
        }
    }
    
    static func getAll () -> NSMutableArray {
    
        let favorites: NSMutableArray = []
        
        //1
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Favorite")
        
        //4
        do {
            let items = try managedContext.fetch(fetchRequest)
            
            for item in items {
                let any_o = item as AnyObject
                if let id = any_o.value(forKey: "public_id") as? String {
                   favorites.add(id)
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return favorites
    }
}
