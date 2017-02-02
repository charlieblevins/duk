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

class MyMarkersController: UITableViewController, PublishSuccessDelegate, ApiRequestDelegate {
    
    var savedMarkers: [Marker] = [Marker]()
    var deletedMarkers: [Double] = []
    
    var progressView: UIProgressView? = nil
    var myMarkersView: MyMarkersController? = nil
    
    var request: ApiRequest?
    var pending_publish: Dictionary<String, Any>?
    var movingToMarkerDetail: Bool = false
    
    static var active_requests = [Double:ApiRequest]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("My Markers loaded")
        
        // Get marker data
        savedMarkers = self.loadMarkerData()
        
        // Sync with public if credentials exist
        if let cred = Credentials() {
            let request = ApiRequest()
            request.delegate = self
            request.getMarkersByUser(cred)
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension

        // preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true

        // display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Set handler for pull to refresh
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        // Observe changes to marker data
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMarkerUpdate), name: Notification.Name("MarkerEditIdentifier"), object: nil)
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
    
    // Update marker in savedMarkers (table data source)
    func setSavedMarker(_ index: Int, marker: Marker) {
        let savable = marker
        
        // Remove large photos to save memory
        savable.photo = nil
        savable.photo_md = nil
        
        self.savedMarkers[index] = savable
    }
    
    // Sync markers from server
    func handleRefresh () {
        print("refreshing markers")
        
        self.getCredentials({ credentials in
            
            // Request marker data for this user
            let request = ApiRequest()
            request.delegate = self
            request.getMarkersByUser(credentials)
        })
    }
    
    // Called when any marker is changed on any view
    // Used to keep the map up to date with the latest marker data
    func handleMarkerUpdate (notification: Notification) {
        
        guard let message = notification.object as? MarkerUpdateMessage else {
            print("cannot convert message to MarkerUpdateMessage")
            return
        }
        
        var marker_ind: Int? = nil
        if message.editType == .update {
            
            if savedMarkers.count == 0 {
                print("No update required as no savedMarkers exist yet")
                return
            }
            
            if let timestamp = message.marker.timestamp {
                marker_ind = savedMarkers.index(where: { $0.timestamp == timestamp })
                
            } else if let public_id = message.marker.public_id {
                marker_ind = savedMarkers.index(where: { $0.public_id == public_id })
            }
            
            guard let index = marker_ind else {
                print("No matching marker found")
                return
            }
            
            savedMarkers[index].tags = message.marker.tags
            
            let path = IndexPath(item: index, section: 0)
            self.tableView.reloadRows(at: [path], with: .automatic)
        
        } else if message.editType == .delete {
            
            // If marker has public_id maintain cell but remove timestamp
            if let public_id = message.marker.public_id {
                
                if let marker_ind = savedMarkers.index(where: { $0.public_id == public_id }) {
                   savedMarkers[marker_ind].timestamp = nil
                }
            }
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
        fetchReq.propertiesToFetch = ["timestamp", "public_id", "tags", "approved"]
        
        
        do {
            let markers = try managedContext.fetch(fetchReq)
            
            for marker in markers {
                
                let new_marker = Marker(fromCoreData: marker as AnyObject)
                
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

    // Initial load of each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "MarkerTableViewCell", for: indexPath) as! MarkerTableViewCell

        // Set marker data
        let marker = savedMarkers[(indexPath as NSIndexPath).row]
        cell.setData(marker)
        
        // See if this marker has a pending/active upload and 
        // if so, continue
        var uploading = false
        if let timestamp = marker.timestamp {

            if self.isPendingPublish(cell, timestamp: timestamp) {
                self.makePublishRequest(cell)
                uploading = true
                
            } else if self.isPublishInProgress(cell, timestamp: timestamp) {
                self.reconnectPublishRequest(cell, timestamp: timestamp)
                uploading = true
                
            }
        }
        
        // No upload in progress
        if !uploading {
            cell.setPublishStatus()
        }

        cell.master = self
        
        return cell
    }
    
    // See if this cell needs to kick off an upload to the server
    func isPendingPublish(_ cell: MarkerTableViewCell, timestamp: Double) -> Bool {
        
        // Start any pending upload requests
        guard let pending = self.pending_publish else {
            print("no pending publish array")
            return false
        }
        
        guard let marker = pending["marker"] as? Marker else {
            print("Error: value in pending dictionary not castable to Marker")
            return false
        }
        
        guard let publish_timestamp = marker.timestamp else {
            print("Error: pending publish marker has no timestamp")
            return false
        }
        
        // If timestamps match, set this cell as request delegate
        if timestamp == publish_timestamp {
            return true
        }
        
        return false
    }
    
    // See if this cell is in the process of uploading data
    func isPublishInProgress (_ cell: MarkerTableViewCell, timestamp: Double) -> Bool {
        
        // If cell is currently uploading
        if MyMarkersController.active_requests[timestamp] != nil {
            return true
        }
        
        return false
    }
    
    // For cases where a user starts an upload, leaves the view and later returns,
    // restore upload status tracking for this cell
    func reconnectPublishRequest (_ cell: MarkerTableViewCell, timestamp: Double) {
        
        guard let active_req = MyMarkersController.active_requests[timestamp] else {
            print("Error: cannot get active request for marker timestamp: \(timestamp)")
            return
        }
        
        cell.updateStatus("(0)% complete")
        active_req.delegate = cell
    }

    func reconnectActiveRequests (_ cell: MarkerTableViewCell) {

        // Start or resume upload if necessary
        if let cell_timestamp = cell.markerData!.timestamp {
            

            
            // Start any pending upload requests
            if self.pending_publish != nil {
                
                let marker = self.pending_publish!["marker"] as! Marker
                let publish_timestamp = marker.timestamp
                
                
                // If timestamps match, set this cell as request delegate
                if cell_timestamp == publish_timestamp {
                    makePublishRequest(cell)
                }
            }
        }
    }
    
    func publishAction(_ cell: MarkerTableViewCell) {
        
        // Sign in credentials exist
        if Credentials() != nil {
            
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
            print(segue.identifier as Any)
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
            
            self.movingToMarkerDetail = false
            
            let editView = segue.destination as! AddMarkerController
            
            guard let marker = sender as? Marker else {
                print("could not convert sender to marker at perform segue")
                return
            }
            editView.editMarker = marker
        }
    }
    
    // Row Height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }


    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        
        guard self.tableView.cellForRow(at: indexPath) as? MarkerTableViewCell != nil else {
            print("cannot edit cell that has no MarkerTableViewCell")
            return false
        }
        
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            popDeleteAlert(rowAction: UITableViewRowAction(), indexPath: indexPath)
        }
    }
    
    // Define custom swipe actions for row
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction] {
        var actions = [UITableViewRowAction]()
        
        let marker = self.savedMarkers[indexPath.row]
        
        // Delete - only allowed if not published
        if marker.public_id == nil {
            let del = UITableViewRowAction(style: .destructive, title: "Delete", handler: self.popDeleteAlert)
            actions.append(del)
        } else {
            let unpublish = UITableViewRowAction(style: .destructive, title: "Un-publish", handler: self.popUnpublishAlert)
            actions.append(unpublish)
        }
        
        return actions
    }
    
    // On Row Select load
    // marker edit view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // get marker
        let cur_marker = savedMarkers[(indexPath as NSIndexPath).row]
        
        // If local, load data from core
        if let timestamp = cur_marker.timestamp {
            
            // Get all data for this marker
            guard let marker = Marker.getLocalByTimestamp(timestamp) else {
                print("Could not load marker with timestamp: ", timestamp)
                return
            }
            performSegue(withIdentifier: "EditMarker", sender: marker)
            
        // else load from server
        } else {
            
            self.movingToMarkerDetail = true
            
            self.showLoading("Loading marker...")
            
            guard let pid = cur_marker.public_id else {
                print("marker has no timestamp or public_id. Cannot load marker detail")
                self.hideLoading(nil)
                return
            }
            
            // Get marker data
//            let request = ApiRequest()
//            request.delegate = self
//            request.getMarkerDataById([["public_id": pid, "photo_size": "full"]])
            
            let marker_request = MarkerRequest()
            let sizes: [MarkerRequest.PhotoSizes] = [.full]
            let marker_param = MarkerRequest.LoadByIdParamsSingle(pid, sizes: sizes)
            
            marker_request.loadById([marker_param], completion: {markers in
                
                guard let marker = markers?[0] else {
                    print("No markers returned")
                    self.hideLoading(nil)
                    return
                }
                
                self.hideLoading({
                    self.performSegue(withIdentifier: "EditMarker", sender: marker)
                })
            }, failure: {
                self.hideLoading(nil)
            })
        }
    }
    
    func popUnpublishAlert(rowAction: UITableViewRowAction, indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Unpublish Marker",
                                                message: "Are you sure you want to remove this marker from public view?",
                                                preferredStyle: .actionSheet)
        
        let unpublishAction = UIAlertAction(title: "Unpublish", style: .destructive, handler: { alertAction in
            guard let cell = self.tableView.cellForRow(at: indexPath) as? MarkerTableViewCell else {
                print("cannot convert cell to MarkerTableViewCell")
                return
            }
            cell.unpublishMarker()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(unpublishAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func popDeleteAlert(rowAction: UITableViewRowAction, indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Delete Marker",
            message: "Are you sure you want to delete this marker?",
            preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { alertAction in
            self.handleDeleteMarker(rowAction: rowAction, indexPath: indexPath)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func handleDeleteMarker (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void {
        tableView.beginUpdates()
        
        // Delete from local var
        savedMarkers.remove(at: (indexPath as NSIndexPath).row)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? MarkerTableViewCell else {
            print("cannot fully delete marker: cell cannot be converted to MarkerTableViewCell")
            return
        }
        
        // Delete from table view
        tableView.deleteRows(at: [indexPath], with: .automatic)
        
        // Delete from core data
        if cell.markerData?.deleteFromCore() == false {
            print("Marker delete from core data failed")
        }
        
        tableView.endUpdates()
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
    
    
    func updateMarkerEntity (_ localTimestamp: Double, publicID: String?, approved: Marker.Approval?, user_id: String?) {
        
        // Update savedMarkers
        if let ind = savedMarkers.index(where: { $0.timestamp == localTimestamp }) {
            savedMarkers[ind].public_id = publicID
            savedMarkers[ind].approved = approved
            savedMarkers[ind].user_id = user_id
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
                managedObject.setValue(approved?.rawValue, forKey: "approved")
                managedObject.setValue(user_id, forKey: "user_id")
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
    
    // Query for a marker by publicId. If it exists, update and return true.
    // Otherwise return false
    func updateMarkerApproved (_ publicId: String, approved: Int) -> String {
        
        // Update savedMarkers
        if let ind = savedMarkers.index(where: { $0.public_id == publicId }) {
            savedMarkers[ind].approved = Marker.Approval(rawValue: approved)
        } else {
            print("could not update savedMarker: no marker with publicId \(publicId) found")
        }
        
        /// Update core data
        // Get managed object context
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        // Construct fetch request with predicate
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Marker")
        fetchRequest.predicate = NSPredicate(format: "public_id = %@", publicId)
        
        // Execute fetch
        do {
            let fetchResults = try appDel.managedObjectContext.fetch(fetchRequest) as? [NSManagedObject]
            
            // Insert new public id
            if  fetchResults != nil && fetchResults!.count > 0 {
                let managedObject = fetchResults![0]
                managedObject.setValue(approved, forKey: "approved")
                
            // Not found
            } else {
                return "not_found"
            }
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            return "fail"
        }
        
        // Save
        do {
            try context.save()
            return "success"
        } catch let error as NSError {
            print("marker save failed: \(error.localizedDescription)")
            return "fail"
        }
    }

    // Remove un-owned markers. Mutates savedMarkers array
    func removeUnownedMarkers (_ user_markers: NSDictionary) {
        
        self.savedMarkers = self.savedMarkers.filter() {
            
            // Consider un-owned if a public_id exists in core data
            // that is not returned by server
            if let id = $0.public_id {
                return user_markers[id] != nil
            } else {
                return true
            }
        }
    }
    
    // MARK: upload delegate method handlers
    func reqDidStart() {

    }
    
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        if (method == .markersByUser) {
            var new_markers = [String]()
 
            for (public_id, approved) in data {
                
                // Query core data for marker with matching public id
                // If the marker exists - update it's approved value
                guard let pid = public_id as? String, let appr = approved as? Int else {
                    print("Cannot convert marker data")
                    break
                }
                let result = self.updateMarkerApproved(pid, approved: appr)
                
                // If it does not exist, request small photo and tag data.
                if result == "not_found" {
                    new_markers.append(pid)
                }
            }
            
            // TODO: Hide any markers that do not belong to the current user account
            self.removeUnownedMarkers(data)
            
            if new_markers.count > 0 {
                self.loadNewPublicMarkers(new_markers)
            } else {
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
                self.hideLoading(nil)
            }
            
        } else if (method == .getMarkerDataById) {
            
            // Convert returned to marker objects
            guard let returned = data.value(forKey: "data") as? Array<Any> else {
                print("Returned markers could not be converted to an array")
                return
            }
            
            guard returned.count > 0 else {
                print("No public markers returned by getMArkerDataById")
                return
            }
            
            // Marker detail
            if self.movingToMarkerDetail {
                let marker_data = returned[0]
                
                guard let data_dic: NSDictionary = marker_data as? NSDictionary else {
                    print("could not cast to NSDictionary")
                    return
                }
                
                guard let marker = Marker(fromPublicData: data_dic) else {
                    print("could not convert data to marker")
                    return
                }
                
                self.hideLoading({
                    self.performSegue(withIdentifier: "EditMarker", sender: marker)
                })
                
                
            // Refreshing table
            } else {
            
                for marker_data in returned {
                    
                    guard let data_dic: NSDictionary = marker_data as? NSDictionary else {
                        print("could not cast to NSDictionary")
                        return
                    }
                    
                    if let marker = Marker(fromPublicData: data_dic) {
                        
                        if let ind = self.savedMarkers.index(where: { $0.public_id == data_dic["_id"] as? String}) {
                            self.savedMarkers[ind] = marker
                        } else {
                            self.savedMarkers.append(marker)
                        }
                    }
                }
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
                
                self.hideLoading(nil)
            }
        }
    }
    
    // Request small photo and tags for public ids
    func loadNewPublicMarkers (_ publicIds: [String]) {
        var requestMarkers: Array<Dictionary<String, String>> = []
        
        // Make array of marker requests
        for id in publicIds {
            var req: [String: String] = [:]
            req["public_id"] = id
            req["photo_size"] = "sm"
            requestMarkers.append(req)
        }
        
        let request = ApiRequest()
        request.delegate = self
        request.getMarkerDataById(requestMarkers)
    }
    
    // Show alert on failure
    func reqDidFail(_ error: String, method: ApiMethod, code: Int) {
        if method == .markersByUser {
            print("markers by user request failed: \(error)")
            self.refreshControl?.endRefreshing()
        } else if method == .getMarkerDataById {
            print("getMarkerDataById request failed: \(error)")
            self.refreshControl?.endRefreshing()
            
            if self.loader != nil {
                self.hideLoading(nil)
            }
        }
    }
}
