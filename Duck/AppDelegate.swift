//
//  AppDelegate.swift
//  Duck
//
//  Created by Charlie Blevins on 9/20/15.
//  Copyright (c) 2015 Charlie Blevins. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps
import GooglePlaces
import Kingfisher

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // G Maps Api Key
        GMSServices.provideAPIKey("AIzaSyCx00Cy9jGzz0hIcv485TWytTq82sAQYaI")
        
        // G Places Api Key
        GMSPlacesClient.provideAPIKey("AIzaSyCx00Cy9jGzz0hIcv485TWytTq82sAQYaI")
        
        // Clear KF Image cache (disk)
        //KingfisherManager.shared.cache.clearDiskCache()

        
        // Clear downloaded files
//        let fm = FileManager.default
//        let path: [URL] = fm.urls(for: .documentDirectory, in: .userDomainMask)
//        
//        do {
//            let contents: [String] = try fm.contentsOfDirectory(atPath: path[0].absoluteString)
//            print(contents)
//        } catch {
//            print("error getting contents")
//        }
        
        //Util.updateCoreDataForEntity("Marker", fieldName: "distance_from_me", newValue: nil)
        
        

//        // Build thumbnails for existing images (one time only!)
//        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        let managedContext = appDelegate.managedObjectContext
//        
//        var all_markers = Util.fetchCoreData("Marker")
//        for marker in all_markers {
//            let img_data = marker.valueForKey("photo") as! NSData
//            let full_image = UIImage(data: img_data)
//            
//            let sm = UIImageJPEGRepresentation(Util.resizeImage(full_image!, scaledToFillSize: CGSizeMake(80, 80)), 1)
//            marker.setValue(sm, forKey: "photo_sm")
//            
//            let md = UIImageJPEGRepresentation(Util.resizeImage(full_image!, scaledToFillSize: CGSizeMake(240, 240)), 1)
//            marker.setValue(md, forKey: "photo_md")
//            
//            marker.setValue(nil, forKey: "public_id")
//        }
//        
//        do {
//            try managedContext.save()
//        } catch {
//            print("save failed")
//        }
        
        // Build thumbnails for existing images (one time only!)
//        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        let managedContext = appDelegate.managedObjectContext
//
//        var all_markers = Util.fetchCoreData("Marker", predicate: nil)
//        for marker in all_markers {
//            if let tags = marker.valueForKey("tags") as? String {
//                let new_tags = tags.stringByReplacingOccurrencesOfString("#", withString: "")
//
//                marker.setValue(new_tags, forKey: "tags")
//            }
//        }
//
//        do {
//            try managedContext.save()
//        } catch {
//            print("save failed")
//        }
 
        // Clear King fisher cache (NO PROD!!!)
//        ImageCache.default.clearMemoryCache()
//        ImageCache.default.clearDiskCache()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()

        // Delete all local data on close
        //Util.deleteCoreDataForEntity("Marker")
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.blevins.Duck" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "MarkerModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
//        self.lsDocumentsDir()
//        self.removeFile(itemName: "SingleViewCoreData", fileExtension: "sqlite-shm")
//        self.removeFile(itemName: "SingleViewCoreData", fileExtension: "sqlite-wal")
//        self.lsDocumentsDir()
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        
        // Allow automatic migration
        let mOptions = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: mOptions)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func removeFile(itemName:String, fileExtension: String) {
        let fileManager = FileManager.default
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        guard let dirPath = paths.first else {
            return
        }
        let filePath = "\(dirPath)/\(itemName).\(fileExtension)"
        do {
            try fileManager.removeItem(atPath: filePath)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    
    func lsDocumentsDir () {
        // Get the document directory url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}

struct GLOBALS {
    static var firstSearch: Bool = true
}

import ObjectiveC

//private var associationKey: UInt8 = 0
private var loadingOverlay: UIAlertController?

// Custom controller
// loading overlay spinner show and hide
extension UIViewController {
    
    private struct AssociatedKeys {
        static var Loader = "duk_loader"
    }
    
    var loader: UIAlertController? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.Loader) as? UIAlertController
        }
        set(newValue) {
            guard let alert = newValue else {
                objc_setAssociatedObject(self, &AssociatedKeys.Loader, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return
            }
            objc_setAssociatedObject(self, &AssociatedKeys.Loader, alert as UIAlertController, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func showLoading (_ message: String?) {
        let message = (message != nil) ? message : "Loading..."
        self.loader = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        self.loader!.view.tintColor = UIColor.black
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = .gray
        loadingIndicator.startAnimating();
        
        loader!.view.addSubview(loadingIndicator)
        self.present(loader!, animated: true, completion: nil)
    }
    
    func hideLoading (_ completion: (()->Void)?) {
        self.loader?.dismiss(animated: false, completion: completion)
        self.loader = nil
    }
}

