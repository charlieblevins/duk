//
//  FavoritesModel.swift
//  Duck
//
//  Created by Charlie Blevins on 1/30/17.
//  Copyright © 2017 Charlie Blevins. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Favorite: NSObject {
    
    var public_id: String
    
    init (_ public_id: String) {
        self.public_id = public_id
    }
    
    static func getAll () -> NSArray {
    
        var favorites: NSArray = []
        
        //1
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Favorite")
        
        //4
        do {
            let items = try managedContext.fetch(fetchRequest)
            
            for item in items {
                let any_o = item as AnyObject
                if let id = any_o.value(forKey: "public_id") as? String {
                   favorites = favorites.adding(id) as NSArray
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        return favorites
    }
}
