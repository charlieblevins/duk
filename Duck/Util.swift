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
    class func fetchCoreData (entityName: String, predicate: NSPredicate?) -> [AnyObject]! {
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        //3
        if predicate != nil {
            fetchRequest.predicate = predicate
        }
        
        //4
        do {
            return try managedContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
    }
    
    // Utility
    // Update a single field value for all items of a particular entity type
    class func updateCoreDataForEntity (entityName: String, fieldName: String, newValue: AnyObject?) {
        
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
                item.setValue(newValue, forKey: fieldName)
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
    
    class func loadMarkerIcon (marker: DukGMSMarker, noun_tags: String) {
        
        // Set placeholder for interim
        let placeholder = UIImage(named: "photoMarker")
        marker.icon = placeholder
        
        // Split string into array
        let tagArr = noun_tags.characters.split{ $0 == " " }.map {
            item in
            String(item).stringByReplacingOccurrencesOfString("#", withString: "")
        }
        
        // Load image from server
        let imgView: UIImageView = UIImageView()
        
        let file = filenameFromNoun(tagArr[0])
        
        imgView.kf_setImageWithURL(
            NSURL(string: "http://dukapp.io/icon/\(file)")!,
            placeholderImage: nil,
            optionsInfo: nil,
            progressBlock: nil,
            completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                if error !== nil {
                    print("image GET failed: \(error)")
                    return Void()
                }
                
                let imgView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
                imgView.image = image
                
                marker.iconView = imgView
            }
        )
    }
    
    
    // Thumbnail size?
    class func resizeImage(image: UIImage, scaledToFillSize size: CGSize) -> UIImage {
        
        let scale: CGFloat = max(size.width / image.size.width, size.height / image.size.height)
        let width: CGFloat = image.size.width * scale
        let height: CGFloat = image.size.height * scale
        
        let imageRect: CGRect = CGRectMake((size.width - width) / 2.0, (size.height - height) / 2.0, width, height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        image.drawInRect(imageRect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // Load an icon image from the server
    class func loadIconImage (noun: String, imageView: UIImageView, activitIndicator: UIActivityIndicatorView) {
        
        activitIndicator.startAnimating()
        
        let file = filenameFromNoun(noun)
        
        imageView.kf_setImageWithURL(NSURL(string: "http://dukapp.io/icon/\(file)")!,
                                        placeholderImage: nil,
                                        optionsInfo: nil,
                                        progressBlock: nil,
                                        completionHandler: { (image, error, cacheType, imageURL) -> () in
                                            
                                            activitIndicator.stopAnimating()
                                            activitIndicator.hidden = true
                                            
                                            if error !== nil {
                                                print("image GET failed: \(error)")
                                                return Void()
                                            }
                                            
                                            imageView.image = image
        })
        
    }
    
    // Create filename string from noun
    // for use with image creation api
    class func filenameFromNoun (noun: String) -> String {
        
        // Remove first char if it is a "#"
        var noun_no_hash = noun
        if noun[noun.startIndex] == "#" {
            noun_no_hash = noun.substringFromIndex(noun.startIndex.successor())
        }
        
        // Detect this iphone's resolution requirement
        let scale: Int = Int(UIScreen.mainScreen().scale)
        
        let file: String = "\(noun_no_hash)@\(scale)x.png"
        
        return file
    }
}


extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
        
    }
    
}