//
//  Util.swift
//  Duck
//
//  Created by Charlie Blevins on 12/4/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Util {
    
    // Fetch any entity from core data
    class func fetchCoreData (entityName: String) -> [AnyObject]! {
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        //3
        do {
            return try managedContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
    }
    
    // Utility
    // Delete all objects of a certain entity type from core data
    class func deleteCoreDataForEntity (entityName: String) {
        
        // Clear markers for now - NOT FOR PRODUCTION!
        let allItems: NSFetchRequest = NSFetchRequest()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        allItems.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedContext)
        allItems.includesPropertyValues = false
        //only fetch the managedObjectID
        var items: [AnyObject]
        
        do {
            items = try managedContext.executeFetchRequest(allItems)
            
            for item in items {
                managedContext.deleteObject(item as! NSManagedObject)
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        do {
            try managedContext.save()
        } catch {
            print("save failed")
        }
    }
    
    // Delete objects with a certain time stamp from core data
    class func deleteCoreDataByTime (entityName: String, timestamp: Double) {
        // Clear markers for now - NOT FOR PRODUCTION!
        let marker: NSFetchRequest = NSFetchRequest()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        marker.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedContext)
        marker.includesPropertyValues = false
        
        // Query by timestamp
        let predicate = NSPredicate(format: "timestamp = %lf", timestamp)
        marker.predicate = predicate
        
        var markers: [AnyObject]
        
        do {
            markers = try managedContext.executeFetchRequest(marker)
            
            for marker in markers {
                managedContext.deleteObject(marker as! NSManagedObject)
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        do {
            try managedContext.save()
        } catch {
            print("save failed")
        }
    }
    
    // searches tags until it finds one that matches a marker icon.
    // If none are found, return photo icon
    class func getIconForTags (tags: String) -> UIImage? {
        
        // Split string into array
        let tagArr = tags.characters.split{ $0 == "," }.map {
            item in
            String(item).stringByReplacingOccurrencesOfString("#", withString: "")
        }
        
        //check each item for matching icon
        var img: UIImage? = nil
        for tag in tagArr {
            img = UIImage(named: tag + "Marker")
            if img != nil {
                break
            }
        }
        
        // Default: photoMarker
        if img == nil {
            img = UIImage(named: "photoMarker")
        }
        
        return img
    }
    
}