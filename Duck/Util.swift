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
        let allMarkers: NSFetchRequest = NSFetchRequest()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        allMarkers.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedContext)
        allMarkers.includesPropertyValues = false
        //only fetch the managedObjectID
        var markers: [AnyObject]
        
        do {
            markers = try managedContext.executeFetchRequest(allMarkers)
            
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
}