//
//  MarkerModel.swift
//  Duck
//
//  Created by Charlie Blevins on 2/12/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation

struct Marker {
    let latitude, longitude, timestamp: Double
    let photo: NSData
    let photo_md: NSData
    let photo_sm: NSData
    let tags: String
    
    var public_id: String?
    
    init(fromCoreData data: AnyObject) {
        self.latitude = data.valueForKey("latitude") as! Double
        self.longitude = data.valueForKey("longitude") as! Double
        self.photo = data.valueForKey("photo") as! NSData
        self.photo_md = data.valueForKey("photo_md") as! NSData
        self.photo_sm = data.valueForKey("photo_sm") as! NSData
        self.tags = data.valueForKey("tags") as! String
        self.timestamp = data.valueForKey("timestamp") as! Double
        
        // TODO: Assign value here if exists OR nil
        self.public_id = nil
    }
}