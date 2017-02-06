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
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        
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
    
    class func fetchCoreData (_ entityName: String, predicate: NSPredicate?, fields: [String]) -> [Dictionary<String, Any>] {
        
        var found = [Dictionary<String, Any>]()
        
        // Context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // Fetch request
        let fetchReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchReq.entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)
        
        fetchReq.resultType = .dictionaryResultType
        fetchReq.propertiesToFetch = fields
        
        do {
            let objects = try managedContext.fetch(fetchReq)
            for obj in objects {
                if let dict = obj as? Dictionary<String, Any> {
                    found.append(dict)
                }
            }
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        return found
    }
    
    // Utility
    // Update a single field value for all items of a particular entity type
    class func updateCoreDataForEntity (_ entityName: String, fieldName: String, newValue: AnyObject?) {
        
        // Clear markers for now - NOT FOR PRODUCTION!
        let allItems: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
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
    
    class func updateMarkerPropByTimestamp (_ timestamp: Double, fieldName: String, newValue: Any?) {
        
        // Clear markers for now - NOT FOR PRODUCTION!
        let marker: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        marker.entity = NSEntityDescription.entity(forEntityName: "Marker", in: managedContext)
        marker.includesPropertyValues = false
        marker.predicate = NSPredicate(format: "timestamp = %lf", timestamp)
        
        //only fetch the managedObjectID
        var items: [AnyObject]
        
        do {
            items = try managedContext.fetch(marker)
            
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
        let allItems: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
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


// Create RGB colors with numbers 1 - 256
extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
        
    }
    
}

extension UIViewController {
    
    func overlay(_ view: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: view)
        self.present(vc, animated: true, completion: nil)
    }
}
