//
//  FavoriteMarkersController.swift
//  Duck
//
//  Created by Charlie Blevins on 1/27/17.
//  Copyright © 2017 Charlie Blevins. All rights reserved.
//

import UIKit
import CoreData

class FavoriteMarkersController: UITableViewController {
    
    var favorites: [Marker] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        favorites = self.loadFavorites()

        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    func loadFavorites () -> [Marker] {
        
        let ids = Favorite.getAll()
        
        if ids.count == 0 {
            return favorites
        }
        
        // Context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // Fetch request
        let fetchReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchReq.entity = NSEntityDescription.entity(forEntityName: "Marker", in: managedContext)
        fetchReq.predicate = NSPredicate(format: "public_id IN %@", ids)
        
        fetchReq.resultType = .dictionaryResultType
        //fetchReq.propertiesToFetch = ["timestamp", "public_id", "tags", "photo_sm"]
        fetchReq.propertiesToFetch = ["timestamp", "public_id", "tags", "approved"]
        
        do {
            let markers = try managedContext.fetch(fetchReq)
            
            // clear old
            favorites = []
            
            for marker in markers {
                
                let new_marker = Marker(fromCoreData: marker as AnyObject)
                
                favorites.append(new_marker)
            }
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        // Make array of non-local markers
        
        // Get non-local markers from server
        
        return favorites
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
