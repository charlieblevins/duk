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
        
        self.loadFavorites({ possible_markers in
            
            self.tableView.reloadData()
            print("favorite load complete")
        })

        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favorites.count
    }
    
    func loadFavorites (_ completion: @escaping (_ markers: [Marker]?) -> Void) {
        
        let ids = Favorite.getAll()
        
        if ids.count == 0 {
            completion(favorites)
            return
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
                
                // Make array of markers not found
                guard let pubid = new_marker.public_id else {
                    print("Error: no public_id on returned marker")
                    break
                }
                
                let ind: Int = ids.index(of: pubid)
                if ind != NSNotFound {
                    ids.removeObject(at: ind)
                }
            }
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        // Get non-local markers from server
        let req = MarkerRequest()
        
        var requested_markers: [MarkerRequest.LoadByIdParamsSingle] = []
        
        for id in ids {
            let sizes: [MarkerRequest.PhotoSizes] = [.sm]
            guard let cast_id = id as? String else {
                print("Error: could not cast array value to string")
                break
            }
            requested_markers.append(MarkerRequest.LoadByIdParamsSingle(cast_id, sizes: sizes))
        }
        
        req.loadById(requested_markers, completion: { markers in
            
            if let markers_array = markers {
                self.favorites.append(contentsOf: markers_array)
            }
            completion(self.favorites)
            
        }, failure: {
            print("Could not get markers from server")
            completion(self.favorites)
        })
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MarkerTableViewCell", for: indexPath) as! MarkerTableViewCell
        
        // Set marker data
        let marker = favorites[(indexPath as NSIndexPath).row]
        cell.setData(marker)

        return cell
    }
    
    // Row Height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }


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
