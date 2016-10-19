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
    
    static var active_requests = [Double:ApiRequest]()

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
        //fetchReq.propertiesToFetch = ["timestamp", "public_id", "tags", "photo_sm"]
        fetchReq.propertiesToFetch = ["timestamp", "public_id", "tags"]
        
        
        do {
            let markers = try managedContext.fetch(fetchReq)
            
            for marker in markers {
                
                var new_marker = Marker()
                new_marker.timestamp = (marker as AnyObject).value(forKey: "timestamp") as? Double
                new_marker.public_id = (marker as AnyObject).value(forKey: "public_id") as? String
                new_marker.tags = (marker as AnyObject).value(forKey: "tags") as? String
                //new_marker.photo_sm = (marker as AnyObject).value(forKey: "photo_sm") as? Data
                
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
        
        if let tags = cell.markerData!.tags {
            cell.tagsLabel?.attributedText = Marker.formatNouns(tags)
        }
        
        cell.tagsLabel?.lineBreakMode = .byWordWrapping
        cell.tagsLabel?.numberOfLines = 3
        
        // Remove right side subviews
        cell.resetRight()


        // Get thumbnail
        var marker = cell.markerData! as Marker
        
        // Begin photo lookup on new thread
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            
            marker.loadPropFromCore(prop: "photo_sm", propLoaded: {
                data in
                
                if data == nil {
                    print("Prop lookeup for marker returned nil")
                    return
                }
                
                guard let typed_data = data as? Data else {
                    print("lookup returned data not convertible to data type")
                    return
                }
                
                // Send image back to main thread for display
                DispatchQueue.main.async {
                    cell.markerImage.image = UIImage(data: typed_data)
                }
            })
        }
        
        let cell_timestamp = cell.markerData!.timestamp!
        
        // * Set cell state
        // If active requests, set to uploading state
        if let active_req = MyMarkersController.active_requests[cell_timestamp] {
            active_req.delegate = cell
            
        // Public
        } else if cell.markerData!.public_id != nil {
            cell.appendPublicBadge()
            
        // Local
        } else {
            cell.appendPublishBtn()
        }

        // Start any pending upload requests
        if self.pending_publish != nil {
            
            let marker = self.pending_publish!["marker"] as! Marker
            let publish_timestamp = marker.timestamp
            
            
            // If timestamps match, set this cell as request delegate
            if cell_timestamp == publish_timestamp {
                makePublishRequest(cell)
            }
        }

        
        return cell
    }
    
    func publishAction(_ cell: MarkerTableViewCell) {
        
        let credentArr = Util.fetchCoreData("Login", predicate: nil)
        
        // Sign in credentials exist
        if  credentArr?.count != 0 {
            
            self.loadPublishConfirm(cell)
            
        // If not signed in, send to account page
        } else {
            print("no credentials found")
            let accountView = self.storyboard!.instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController
            accountView.signInSuccessHandler = { credentials in
                self.loadPublishConfirm(cell)
            }
            self.navigationController?.pushViewController(accountView, animated: true)
        }
    }
    
    // Get credentials or prompt user to sign in
    func getCredentials(_ completionHandler: @escaping (_ credentials: Credentials) -> Void) {
        
        // Sign in credentials exist
        if let cred = Credentials() {
            
            completionHandler(cred)
            
        // If not signed in, send to account page
        } else {
            print("no credentials found")
            let accountView = self.storyboard!.instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController
            accountView.signInSuccessHandler = { credentials in
                completionHandler(credentials)
            }
            self.navigationController?.pushViewController(accountView, animated: true)
        }
    }
    
    func loadPublishConfirm (_ cell: MarkerTableViewCell) {
        print("credentials found")
        
        // Get and store indexpath
        if self.pending_publish == nil {
            self.pending_publish = Dictionary()
        }
        
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
            
            // Get all data for this marker from core
            let marker_data = savedMarkers[((sender as! IndexPath) as NSIndexPath).row]
            
            guard let timestamp = marker_data.timestamp else {
                print("Could not find timestamp for marker")
                return
            }
            
            publishView.markerData = Marker.getLocalByTimestamp(timestamp)
            
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
        
        // Get pending request marker data
        let marker = self.pending_publish!["marker"] as! Marker
        
        // Set this cell as request delegate
        request!.delegate = cell

        guard marker.timestamp != nil else {
            fatalError("marker does not have timestamp. publish not allowed")
        }

        
        // Initiate request
        if let credentials = Credentials() {
            request!.publishSingleMarker(credentials, marker: marker)
            MyMarkersController.active_requests[marker.timestamp!] = request
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
    
    
    func updateMarkerEntity (_ localTimestamp: Double, publicID: String?) {
        
        // Update savedMarkers
        if let ind = savedMarkers.index(where: { $0.timestamp == localTimestamp }) {
            savedMarkers[ind].public_id = publicID
        } else {
            print("could not update savedMarker: no marker with timestamp \(localTimestamp) found")
        }
        
        /// Update core data
        // Get managed object context
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        // Construct fetch request with predicate
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Marker")
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
