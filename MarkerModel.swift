//
//  MarkerModel.swift
//  Duck
//
//  Created by Charlie Blevins on 2/12/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import GoogleMaps

struct Marker {
    let latitude, longitude: Double
    let timestamp: Double?
    let photo: NSData
    let photo_md: NSData
    let photo_sm: NSData
    let tags: String
    
    var public_id: String?
    
    init(fromCoreData data: AnyObject) {
        self.latitude = data.valueForKey("latitude") as! Double
        self.longitude = data.valueForKey("longitude") as! Double
        self.timestamp = data.valueForKey("timestamp") as? Double
        
        self.photo = data.valueForKey("photo") as! NSData
        self.photo_md = data.valueForKey("photo_md") as! NSData
        self.photo_sm = data.valueForKey("photo_sm") as! NSData
        self.tags = data.valueForKey("tags") as! String

        
        // Local markers do not require a public_id
        self.public_id = nil
    }
    
    // Initialize from public (server) data
    init (fromPublicData data: NSDictionary) {
        self.latitude = data.valueForKey("latitude") as! Double
        self.longitude = data.valueForKey("longitude") as! Double
        
        // public markers don't have a timestamp
        self.timestamp = nil
        
        self.photo = data.valueForKey("photo") as! NSData
        self.photo_md = data.valueForKey("photo_md") as! NSData
        self.photo_sm = data.valueForKey("photo_sm") as! NSData
        self.tags = data.valueForKey("tags") as! String
        
        self.public_id = data.valueForKey("_id") as? String
    }
    
    func getMapMarker () -> DukGMSMarker? {
        let map_marker = DukGMSMarker()
        
        // Set icon
        let pinImage = Util.getIconForTags(self.tags)
        map_marker.icon = pinImage
        
        // Set position
        map_marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // If timestamp assume local
        if timestamp != nil {
            map_marker.dataLocation = .Local
            map_marker.timestamp = timestamp
            return map_marker
        }
        
        if public_id != nil {
            map_marker.dataLocation = .Public
            map_marker.public_id = public_id
            return map_marker
        }
        
        // No timestamp or public id
        return nil
    }
}