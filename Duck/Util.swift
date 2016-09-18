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
import CoreLocation

class Util {
    
    // Fetch any entity from core data
    class func fetchCoreData (_ entityName: String, predicate: NSPredicate?) -> [AnyObject]! {
        //1
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        //3
        if predicate != nil {
            fetchRequest.predicate = predicate
        }
        
        //4
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
    }
    
    // Utility
    // Update a single field value for all items of a particular entity type
    class func updateCoreDataForEntity (_ entityName: String, fieldName: String, newValue: AnyObject?) {
        
        // Clear markers for now - NOT FOR PRODUCTION!
        let allItems: NSFetchRequest = NSFetchRequest()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        allItems.entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)
        allItems.includesPropertyValues = false
        //only fetch the managedObjectID
        var items: [AnyObject]
        
        do {
            items = try managedContext.fetch(allItems)
            
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
    class func deleteCoreDataForEntity (_ entityName: String) {
        
        // Clear markers for now - NOT FOR PRODUCTION!
        let allItems: NSFetchRequest = NSFetchRequest()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        allItems.entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)
        allItems.includesPropertyValues = false
        //only fetch the managedObjectID
        var items: [AnyObject]
        
        do {
            items = try managedContext.fetch(allItems)
            
            for item in items {
                managedContext.delete(item as! NSManagedObject)
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
    class func deleteCoreDataByTime (_ entityName: String, timestamp: Double) {
        // Clear markers for now - NOT FOR PRODUCTION!
        let marker: NSFetchRequest = NSFetchRequest()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        marker.entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)
        marker.includesPropertyValues = false
        
        // Query by timestamp
        let predicate = NSPredicate(format: "timestamp = %lf", timestamp)
        marker.predicate = predicate
        
        var markers: [AnyObject]
        
        do {
            markers = try managedContext.fetch(marker)
            
            for marker in markers {
                managedContext.delete(marker as! NSManagedObject)
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
    
    class func loadMarkerIcon (_ marker: DukGMSMarker, noun_tags: String) {
        
        // Set placeholder for interim
        let placeholder = UIImage(named: "photoMarker")
        marker.icon = placeholder
        
        // Split string into array
        let tagArr = noun_tags.characters.split{ $0 == " " }.map {
            item in
            String(item).replacingOccurrences(of: "#", with: "")
        }
        
        // Load image from server
        let imgView: UIImageView = UIImageView()
        
        let file = filenameFromNoun(tagArr[0])
        
        imgView.kf_setImageWithURL(
            URL(string: "http://dukapp.io/icon/\(file)")!,
            placeholderImage: nil,
            optionsInfo: nil,
            progressBlock: nil,
            completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                if error !== nil {
                    print("loadMarkerIcon Failed: \(error!.localizedDescription)")
                    return Void()
                }
                
                let imgView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
                imgView.image = image
                
                marker.iconView = imgView
            }
        )
    }
    
    
    // Thumbnail size?
    class func resizeImage(_ image: UIImage, scaledToFillSize size: CGSize) -> UIImage {
        
        let scale: CGFloat = max(size.width / image.size.width, size.height / image.size.height)
        let width: CGFloat = image.size.width * scale
        let height: CGFloat = image.size.height * scale
        
        let imageRect: CGRect = CGRect(x: (size.width - width) / 2.0, y: (size.height - height) / 2.0, width: width, height: height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        image.draw(in: imageRect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // Load an icon image from the server
    class func loadIconImage (_ noun: String, imageView: UIImageView, activitIndicator: UIActivityIndicatorView) {
        
        activitIndicator.startAnimating()
        
        let file = filenameFromNoun(noun)
        
        imageView.kf_setImageWithURL(URL(string: "http://dukapp.io/icon/\(file)")!,
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
    class func filenameFromNoun (_ noun: String) -> String {
        
        // Remove first char if it is a "#"
        var noun_no_hash = noun
        if noun[noun.startIndex] == "#" {
            noun_no_hash = noun.substring(from: noun.characters.index(after: noun.startIndex))
        }
        
        // Detect this iphone's resolution requirement
        let scale: Int = Int(UIScreen.main.scale)
        
        let file: String = "\(noun_no_hash)@\(scale)x.png"
        
        return file
    }
    
    // Show an alert overlay for long running tasks
    // Call <return_value>.dismissviewControllerAnimated(... to close
    class func showLoadingOverlay (_ viewController: UIViewController, message: String) -> UIAlertController {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        viewController.present(alert, animated: true, completion: nil)
        
        return alert
    }
    
    class func coreToDictionary (_ managedObj: NSManagedObject) -> NSDictionary {
        let keys = Array(managedObj.entity.attributesByName.keys)
        return managedObj.dictionaryWithValues(forKeys: keys) as NSDictionary
    }
    
    // Calculate distance between two points
    class func distanceFromHereTo (_ point: CLLocationCoordinate2D) {
        
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
