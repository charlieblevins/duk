//
//  MyMarkersController.swift
//  Duck
//
//  Created by Charlie Blevins on 12/4/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class MyMarkersController: UITableViewController, PublishSuccessDelegate {
    
    var savedMarkers: [AnyObject]!
    var deleteMarkerIndexPath: NSIndexPath? = nil
    var deleteMarkerTimestamp: Double? = nil
    var deletedMarkers: [Double] = []
    
    var progressView: UIProgressView? = nil
    var myMarkersView: MyMarkersController? = nil
    
    var request: ApiRequest?
    var pending_publish: Dictionary<String, Any>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("My Markers loaded")
        
        // Temporary!! Removing public id's
        //Util.updateCoreDataForEntity("Marker", fieldName: "public_id", newValue: nil)
        
        // Get marker data
        savedMarkers = Util.fetchCoreData("Marker", predicate: nil)
        
//        // Register cell class
//        self.tableView.registerClass(MarkerTableViewCell.self, forCellReuseIdentifier: "MarkerTableViewCell")
        
        self.tableView.rowHeight = UITableViewAutomaticDimension

        // preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Listen for updates on any pending publish requests
    override func viewWillAppear(animated: Bool) {
        
        // If a publish request is pending, reload data
        // which will trigger the request
        if self.pending_publish != nil && self.pending_publish!["indexPath"] != nil && self.pending_publish!["marker"] != nil {
            
            // Reload data in order to set cell as delegate
            self.tableView.reloadRowsAtIndexPaths([self.pending_publish!["indexPath"] as! NSIndexPath], withRowAnimation: .Right)
        
        // Reset pending publish reference
        } else {
            self.pending_publish = nil
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if savedMarkers != nil {
            return savedMarkers.count
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("MarkerTableViewCell", forIndexPath: indexPath) as! MarkerTableViewCell

        // Get marker data
        cell.markerData = savedMarkers[indexPath.row]
        
        cell.master = self
        
        cell.indexPath = indexPath
        
        cell.tagsLabel?.text = cell.markerData!.valueForKey("tags") as? String
        cell.tagsLabel?.lineBreakMode = .ByWordWrapping
        cell.tagsLabel?.numberOfLines = 3
        
        // Remove right side subviews
        cell.resetRight()
        
        // Public badge or publish btn
        if cell.markerData!.valueForKey("public_id") != nil {
            appendPublicBadge(indexPath.row, cell: cell)
        } else {
            appendPublishBtn(indexPath.row, cell: cell)
        }

        // Get thumbnail
        let data: NSData = cell.markerData!.valueForKey("photo_sm") as! NSData
        let image: UIImage! = UIImage(data: data)!
        cell.markerImage.image = image

        // Set cell as request delegate if pending publish
        if self.pending_publish != nil {
            
            let marker = self.pending_publish!["marker"] as! Marker
            let publish_timestamp = marker.timestamp
            let cell_timestamp = cell.markerData!.valueForKey("timestamp") as! Double
            
            // If timestamps match, set this cell as request delegate
            if cell_timestamp == publish_timestamp {
                makePublishRequest(cell)
            }
        }
        
        return cell
    }
    
    // Show a public badge for published markers
    func appendPublicBadge (row: Int, cell: MarkerTableViewCell) {
        
        // Add publish button
        let publicBadge = UILabel()
        publicBadge.frame.size = CGSizeMake(100, 50)
        publicBadge.text = "Public"
        
        // Forest green
        publicBadge.textColor = UIColor(red: 56, green: 150, blue: 57)
        
        publicBadge.translatesAutoresizingMaskIntoConstraints = false
        
        cell.contentView.addSubview(publicBadge)
        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: publicBadge,
            attribute: .Trailing,
            relatedBy: .Equal,
            toItem: cell.contentView,
            attribute: .Trailing,
            multiplier: 1.0,
            constant: 0
        )
        let vrtC = NSLayoutConstraint(
            item: publicBadge,
            attribute: .CenterY,
            relatedBy: .Equal,
            toItem: cell.contentView,
            attribute: .CenterY,
            multiplier: 1.0,
            constant: 0
        )
        let hgtC = NSLayoutConstraint(
            item: publicBadge,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: cell.contentView,
            attribute: .Height,
            multiplier: 1.0,
            constant: 0
        )
        
        
        // Activate all constraints
        NSLayoutConstraint.activateConstraints([hrzC, vrtC, hgtC])
    }
    
    func appendPublishBtn (row: Int, cell: MarkerTableViewCell) {
        
        // Add publish button
        let pubBtn = UIButton()
        pubBtn.frame.size = CGSizeMake(100, 50)
        pubBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
        pubBtn.setTitle("Publish", forState: .Normal)
        pubBtn.backgroundColor = UIColor.blueColor()
        pubBtn.translatesAutoresizingMaskIntoConstraints = false
        
        pubBtn.tag = row
        pubBtn.addTarget(self, action: #selector(MyMarkersController.publishAction(_:)), forControlEvents: .TouchUpInside)
        
        cell.contentView.addSubview(pubBtn)
        
        // Position with contraints
        let hrzC = NSLayoutConstraint(
            item: pubBtn,
            attribute: .Trailing,
            relatedBy: .Equal,
            toItem: cell.contentView,
            attribute: .Trailing,
            multiplier: 1.0,
            constant: 0
        )
        let vrtC = NSLayoutConstraint(
            item: pubBtn,
            attribute: .CenterY,
            relatedBy: .Equal,
            toItem: cell.contentView,
            attribute: .CenterY,
            multiplier: 1.0,
            constant: 0
        )
        let hgtC = NSLayoutConstraint(
            item: pubBtn,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: cell.contentView,
            attribute: .Height,
            multiplier: 1.0,
            constant: 0
        )
        
        // Activate all constraints
        NSLayoutConstraint.activateConstraints([hrzC, vrtC, hgtC])
    }
    
    func publishAction(sender: AnyObject) {
        
        let credentArr = Util.fetchCoreData("Login", predicate: nil)
        
        // Sign in credentials exist
        if  credentArr.count != 0 {
            
            print("credentials found")
            
            let credentEntry: AnyObject? = credentArr[0]
            
            // Create array with marker and login data
            let loginAndMarker: [AnyObject] = [savedMarkers[sender.tag], credentEntry!]
            
            // Get and store indexpath
            if self.pending_publish == nil {
               self.pending_publish = Dictionary()
            }
            
            let button = sender as! UIButton
            let sview = button.superview!
            let cell = sview.superview as! MarkerTableViewCell
            self.pending_publish!["indexPath"] = self.tableView.indexPathForCell(cell)
            
            // Load publish confirmation view
            performSegueWithIdentifier("GoToPublish", sender: loginAndMarker)
            
        // If not signed in, send to account page
        } else {
            print("no credentials found")
            let SignInView = self.storyboard!.instantiateViewControllerWithIdentifier("SignInController")
            self.navigationController?.pushViewController(SignInView, animated: true)
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let loginAndMarker = sender as! NSArray

        if segue.identifier == "GoToPublish" {
            print(segue.identifier)
            print(segue.destinationViewController)
            let publishView = segue.destinationViewController as! PublishConfirmController
            publishView.markerData = loginAndMarker[0];
            publishView.loginData = loginAndMarker[1];
            
            // Set this view as delegate to receive future messages
            publishView.delegate = self
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            //Util.deleteCoreDataForEntity()
            //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            deleteMarkerIndexPath = indexPath
            deleteMarkerTimestamp = savedMarkers[indexPath.row].valueForKey("timestamp") as? Double
            popAlert("Are you sure you want to delete this marker?")
        }
    }
    
    func popAlert(text:String) {
        let alertController = UIAlertController(title: "Delete Marker",
            message: text,
            preferredStyle: .ActionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: handleDeleteMarker)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func handleDeleteMarker (alertAction: UIAlertAction!) -> Void {
        if let indexPath = deleteMarkerIndexPath {
            tableView.beginUpdates()
            
            // Delete from local var
            savedMarkers.removeAtIndex(indexPath.row)
            
            // Pass deleted items to mapview for removal
            let mvc = navigationController?.viewControllers.first as! MapViewController
            mvc.deletedMarkers.append(deleteMarkerTimestamp!)
            
            // Delete from table view
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            // Delete from core data
            Util.deleteCoreDataByTime("Marker", timestamp: deleteMarkerTimestamp!)
            
            tableView.endUpdates()
        }
        
    }
    

    func makePublishRequest (cell: MarkerTableViewCell) {
        
        // New request instance
        request = ApiRequest()
        
        // Get pending request timestamp
        let marker = self.pending_publish!["marker"] as! Marker
        
        // Set this cell as request delegate
        request!.delegate = cell

        // Get credentials
        let credentials = self.pending_publish!["credentials"] as! Credentials
        
        // Initiate request
        request!.publishSingleMarker(credentials, marker: marker)
        
        // Clear pending request data
        self.pending_publish = nil
    }
    
    // MARK: Publish delegate method
    
    // Listen for publish begin
    func publishDidBegin (timestamp: Double, request: ApiRequest) {

        
    }
    
    
    func updateMarkerEntity (localTimestamp: Double, publicID: String) {
        
        // Get managed object context
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        // Construct fetch request with predicate
        let fetchRequest = NSFetchRequest(entityName: "Marker")
        fetchRequest.predicate = NSPredicate(format: "timestamp = %lf", localTimestamp)
        
        // Execute fetch
        do {
            let fetchResults = try appDel.managedObjectContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            
            // Insert new public id
            if  fetchResults != nil && fetchResults!.count > 0 {
                let managedObject = fetchResults![0]
                managedObject.setValue(publicID, forKey: "public_id")
            }
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        // Save
        do {
            try context.save()
        } catch let error as NSError {
            print("marker save failed: \(error.localizedDescription)")
        }
    }
    
    func popSuccessAlert() {
        let alertController = UIAlertController(title: "Upload Successful!",
            message: "Your marker was uploaded successfully.",
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(okAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func popFailAlert(text:String) {
        let alertController = UIAlertController(title: "Upload Failure",
            message: text,
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    // Thumbnail size?
    func resizeImage(image: UIImage, scaledToFillSize size: CGSize) -> UIImage {
        
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

    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
