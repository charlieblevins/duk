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
    let photo: NSData?
    let photo_md: NSData?
    let photo_sm: NSData?
    let tags: String
    
    var public_id: String?
    
    init(fromCoreData data: AnyObject) {
        self.latitude = data.valueForKey("latitude") as! Double
        self.longitude = data.valueForKey("longitude") as! Double
        self.timestamp = data.valueForKey("timestamp") as? Double
        
        self.photo = data.valueForKey("photo") as? NSData
        self.photo_md = data.valueForKey("photo_md") as? NSData
        self.photo_sm = data.valueForKey("photo_sm") as? NSData
        self.tags = data.valueForKey("tags") as! String

        
        // Store public id if available
        if let pid = data.valueForKey("public_id") as? String {
            self.public_id = pid
        }
    }
    
    // Initialize from public (server) data
    init?(fromPublicData data: NSDictionary) {
        
        let geometry = data.valueForKey("geometry")
        if geometry == nil {
            print("no geometry provided")
            return nil
        }
        
        let coords = geometry!.valueForKey("coordinates")
        if coords == nil {
            print("no coords provided to marker init")
            return nil
        }
        
        let coords_array = (coords as! NSArray) as Array
        
        if coords_array.count != 2 {
            print("coords array missing data")
            return nil
        }
        
        self.latitude = coords_array[1] as! Double
        self.longitude = coords_array[0] as! Double
        
        // public markers don't have a timestamp
        self.timestamp = nil
        
        self.photo = nil
        self.photo_md = nil
        self.photo_sm = nil
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
        
        // No timestamp or public id
        if timestamp == nil && public_id == nil {
            return nil
        }
        
        // If timestamp assume local
        if timestamp != nil {
            map_marker.dataLocation = .Local
            map_marker.timestamp = timestamp
        } else {
            map_marker.dataLocation = .Public
        }
        
        // Add public id if present
        if public_id != nil {
            map_marker.public_id = public_id
        }
        
        // Add tags for info window display
        map_marker.tags = self.tags
        
        return map_marker
    }
    
    // Find and return marker with provided timestamp
    static func getLocalByTimestamp (timestamp: Double) -> Marker? {
        
        let pred = NSPredicate(format: "timestamp == %lf", timestamp)
        let markers_from_core = Util.fetchCoreData("Marker", predicate: pred)
        
        if markers_from_core.count == 0 {
            return nil
        } else {
            return Marker(fromCoreData: markers_from_core[0])
        }
    }
    
    // Get an array of local markers that have been published (made public)
    static func getLocalPublicIds () -> [String] {
        var public_ids: [String] = []
        
        let markers_from_core = Util.fetchCoreData("Marker", predicate: nil)
        
        if markers_from_core.count == 0 {
            return public_ids
        }
        
        for marker_data in markers_from_core {
            
            let marker = Marker(fromCoreData: marker_data)
            
            if marker.public_id != nil {
                public_ids.append(marker.public_id!)
            }
        }
        
        // Nothing found
        return public_ids
    }
}