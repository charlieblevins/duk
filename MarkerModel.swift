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
    let tags: String
    
    var public_id: String?
    
    init(latitude: Double, longitude: Double, photo: NSData, tags: String, timestamp: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.photo = photo
        self.tags = tags
        self.timestamp = timestamp
    }
    
    init(fromCoreData data: AnyObject) {
        self.latitude = data.latitude
        self.longitude = data.longitude
        self.photo = data.valueForKey("photo") as! NSData
        self.tags = data.valueForKey("tags") as! String
        self.timestamp = data.timestamp
        self.public_id = nil
    }
}