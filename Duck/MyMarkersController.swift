//
//  MyMarkersController.swift
//  Duck
//
//  Created by Charlie Blevins on 12/4/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import UIKit

class MyMarkersController: UITableViewController {
    
    var savedMarkers: [AnyObject]!
    var deleteMarkerIndexPath: NSIndexPath? = nil
    var deleteMarkerTimestamp: Double? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("My Markers loaded")
        
        // Get marker data
        savedMarkers = Util.fetchCoreData("Marker")
        
        // Register cell class
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        // Configure the cell...
        let markerObj = savedMarkers[indexPath.row]
        cell.textLabel?.text = markerObj.valueForKey("tags") as? String
        
        
        let data: NSData = markerObj.valueForKey("photo") as! NSData
        let image: UIImage! = UIImage(data: data)
        cell.imageView!.image = image

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 84.0
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
            
            // Delete from table view
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            // Delete from core data
            Util.deleteCoreDataByTime("Marker", timestamp: deleteMarkerTimestamp!)
            
            tableView.endUpdates()
        }
        
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
