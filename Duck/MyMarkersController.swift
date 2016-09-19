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
    
    var savedMarkers: [Marker] = [Marker]()
    var deleteMarkerIndexPath: IndexPath? = nil
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
        savedMarkers = self.loadMarkerData()
        
//        // Register cell class
//        self.tableView.registerClass(MarkerTableViewCell.self, forCellReuseIdentifier: "MarkerTableViewCell")
        
        self.tableView.rowHeight = UITableViewAutomaticDimension

        // preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Listen for updates on any pending publish requests
    override func viewWillAppear(_ animated: Bool) {
        
        // If a publish request is pending, reload data
        // which will trigger the request
        if self.pending_publish != nil && self.pending_publish!["indexPath"] != nil && self.pending_publish!["marker"] != nil {
            
            // Reload data in order to set cell as delegate
            self.tableView.reloadRows(at: [self.pending_publish!["indexPath"] as! IndexPath], with: .right)
        
        // Reset pending publish reference
        } else {
            self.pending_publish = nil
        }
    }
    
    func loadMarkerData () -> [Marker] {
        var data = [Marker]()
        
        // Context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // Fetch request
        let fetchReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchReq.entity = NSEntityDescription.entity(forEntityName: "Marker", in: managedContext)
        
        fetchReq.resultType = .dictionaryResultType
        fetchReq.propertiesToFetch = ["timestamp", "public_id", "tags", "photo_sm"]
        
        
        do {
            let markers = try managedContext.fetch(fetchReq)
            
            for marker in markers {
                
                var new_marker = Marker()
                new_marker.timestamp = (marker as AnyObject).value(forKey: "timestamp") as? Double
                new_marker.public_id = (marker as AnyObject).value(forKey: "public_id") as? String
                new_marker.tags = (marker as AnyObject).value(forKey: "tags") as? String
                new_marker.photo_sm = (marker as AnyObject).value(forKey: "photo_sm") as? Data
                
                data.append(new_marker)
            }

            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        return data
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return savedMarkers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "MarkerTableViewCell", for: indexPath) as! MarkerTableViewCell

        // Get marker data
        cell.markerData = savedMarkers[(indexPath as NSIndexPath).row]
        
        cell.master = self
        
        cell.indexPath = indexPath
        
        cell.tagsLabel?.text = cell.markerData!.tags
        cell.tagsLabel?.lineBreakMode = .byWordWrapping
        cell.tagsLabel?.numberOfLines = 3
        
        // Remove right side subviews
        cell.resetRight()
        
        // Public badge or publish btn
        if cell.markerData!.public_id != nil {
            appendPublicBadge((indexPath as NSIndexPath).row, cell: cell)
        } else {
            appendPublishBtn((indexPath as NSIndexPath).row, cell: cell)
        }

        // Get thumbnail
        let data: Data = cell.markerData!.photo_sm! as Data
        let image: UIImage! = UIImage(data: data)!
        cell.markerImage.image = image

        // Set cell as request delegate if pending publish
        if self.pending_publish != nil {
            
            let marker = self.pending_publish!["marker"] as! Marker
            let publish_timestamp = marker.timestamp
            let cell_timestamp = cell.markerData!.timestamp!
            
            // If timestamps match, set this cell as request delegate
            if cell_timestamp == publish_timestamp {
                makePublishRequest(cell)
            }
        }
        
        return cell
    }
    
    // Show a public badge for published markers
    func appendPublicBadge (_ row: Int, cell: MarkerTableViewCell) {
        
        // Add publish button
        let publicBadge = UILabel()
        publicBadge.frame.size = CGSize(width: 100, height: 50)
        publicBadge.text = "Public"
        
        // Forest green
        publicBadge.textColor = UIColor(red: 56, green: 150, blue: 57)
        
        publicBadge.translatesAutoresizingMaskIntoConstraints = false
        
        cell.contentView.addSubview(publicBadge)
        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: publicBadge,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: cell.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: 0
        )
        let vrtC = NSLayoutConstraint(
            item: publicBadge,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: cell.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        let hgtC = NSLayoutConstraint(
            item: publicBadge,
            attribute: .height,
            relatedBy: .equal,
            toItem: cell.contentView,
            attribute: .height,
            multiplier: 1.0,
            constant: 0
        )
        
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, vrtC, hgtC])
    }
    
    func appendPublishBtn (_ row: Int, cell: MarkerTableViewCell) {
        
        // Add publish button
        let pubBtn = UIButton()
        pubBtn.frame.size = CGSize(width: 100, height: 50)
        pubBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
        pubBtn.setTitle("Publish", for: UIControlState())
        pubBtn.backgroundColor = UIColor.blue
        pubBtn.translatesAutoresizingMaskIntoConstraints = false
        
        pubBtn.tag = row
        pubBtn.addTarget(self, action: #selector(MyMarkersController.publishAction(_:)), for: .touchUpInside)
        
        cell.contentView.addSubview(pubBtn)
        
        // Position with contraints
        let hrzC = NSLayoutConstraint(
            item: pubBtn,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: cell.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: 0
        )
        let vrtC = NSLayoutConstraint(
            item: pubBtn,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: cell.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        let hgtC = NSLayoutConstraint(
            item: pubBtn,
            attribute: .height,
            relatedBy: .equal,
            toItem: cell.contentView,
            attribute: .height,
            multiplier: 1.0,
            constant: 0
        )
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, vrtC, hgtC])
    }
    
    func publishAction(_ sender: AnyObject) {
        
        let credentArr = Util.fetchCoreData("Login", predicate: nil)
        
        // Sign in credentials exist
        if  credentArr?.count != 0 {
            
            self.loadPublishConfirm(sender)
            
        // If not signed in, send to account page
        } else {
            print("no credentials found")
            let accountView = self.storyboard!.instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController
            accountView.signInSuccessHandler = {
                self.loadPublishConfirm(sender)
            }
            self.navigationController?.pushViewController(accountView, animated: true)
        }
    }
    
    func loadPublishConfirm (_ sender: AnyObject) {
        print("credentials found")
        
        // Get and store indexpath
        if self.pending_publish == nil {
            self.pending_publish = Dictionary()
        }
        
        let button = sender as! UIButton
        let sview = button.superview!
        let cell = sview.superview as! MarkerTableViewCell
        let marker_index_path = self.tableView.indexPath(for: cell)
        self.pending_publish!["indexPath"] = marker_index_path
        
        // Load publish confirmation view
        performSegue(withIdentifier: "GoToPublish", sender: marker_index_path)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "GoToPublish" {
            print(segue.identifier)
            print(segue.destination)
            let publishView = segue.destination as! PublishConfirmController
            publishView.markerData = savedMarkers[((sender as! IndexPath) as NSIndexPath).row];
            
            // Set this view as delegate to receive future messages
            publishView.delegate = self
        } else if segue.identifier == "EditMarker" {
            
            let editView = segue.destination as! AddMarkerController
            let indexPath = sender as! IndexPath
            
            guard let timestamp = savedMarkers[(indexPath as NSIndexPath).row].timestamp else {
                print("Could not get timestamp for row: ", (indexPath as NSIndexPath).row)
                return
            }
            
            // Get all data for this marker
            if let marker = Marker.getLocalByTimestamp(timestamp) {
                editView.editMarker = marker
            } else {
                print("Could not load marker with timestamp: ", timestamp)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            //Util.deleteCoreDataForEntity()
            //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            deleteMarkerIndexPath = indexPath
            deleteMarkerTimestamp = savedMarkers[(indexPath as NSIndexPath).row].timestamp
            popAlert("Are you sure you want to delete this marker?")
        }
    }
    
    // On Row Select load
    // marker edit view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "EditMarker", sender: indexPath)
    }
    
    func popAlert(_ text:String) {
        let alertController = UIAlertController(title: "Delete Marker",
            message: text,
            preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteMarker)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func handleDeleteMarker (_ alertAction: UIAlertAction!) -> Void {
        if let indexPath = deleteMarkerIndexPath {
            tableView.beginUpdates()
            
            // Delete from local var
            savedMarkers.remove(at: (indexPath as NSIndexPath).row)
            
            // Pass deleted items to mapview for removal
            let mvc = navigationController?.viewControllers.first as! MapViewController
            mvc.deletedMarkers.append(deleteMarkerTimestamp!)
            
            // Delete from table view
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // Delete from core data
            Util.deleteCoreDataByTime("Marker", timestamp: deleteMarkerTimestamp!)
            
            tableView.endUpdates()
        }
        
    }
    

    func makePublishRequest (_ cell: MarkerTableViewCell) {
        
        // New request instance
        request = ApiRequest()
        
        // Get pending request timestamp
        let marker = self.pending_publish!["marker"] as! Marker
        
        // Set this cell as request delegate
        request!.delegate = cell

        // Get credentials
        //let credentials = self.pending_publish!["credentials"] as! Credentials
        
        // Initiate request
        if let credentials = Credentials() {
           request!.publishSingleMarker(credentials, marker: marker)
        } else {
            print("Error: Credentials nil in makePublishRequest")
            return
        }
        
        // Clear pending request data
        self.pending_publish = nil
    }
    
    // MARK: Publish delegate method
    
    // Listen for publish begin
    func publishDidBegin (_ timestamp: Double, request: ApiRequest) {
    }
    
    
    func updateMarkerEntity (_ localTimestamp: Double, publicID: String) {
        
        // Get managed object context
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        // Construct fetch request with predicate
        let fetchRequest = NSFetchRequest(entityName: "Marker")
        fetchRequest.predicate = NSPredicate(format: "timestamp = %lf", localTimestamp)
        
        // Execute fetch
        do {
            let fetchResults = try appDel.managedObjectContext.fetch(fetchRequest) as? [NSManagedObject]
            
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
            preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func popFailAlert(_ text:String) {
        let alertController = UIAlertController(title: "Upload Failure",
            message: text,
            preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    // Thumbnail size?
    func resizeImage(_ image: UIImage, scaledToFillSize size: CGSize) -> UIImage {
        
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
