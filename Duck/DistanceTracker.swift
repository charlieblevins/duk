//
//  DistanceTracker.swift
//  Duck
//
//  Created by Charlie Blevins on 7/3/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import GoogleMaps
import CoreLocation
import CoreData

protocol DistanceTrackerDelegate {
    func distanceTracker (updateDidComplete distanceTracker: DistanceTracker)
}

let LocationNotifKey = "com.duk.DistanceNotifKey"

class DistanceTracker: NSObject, CLLocationManagerDelegate {
    
    static let sharedInstance = DistanceTracker.init()
    
    var firstUpdateComplete: Bool = false
    var updating: Bool = false
    
    var delegate: DistanceTrackerDelegate? = nil
    
    var locationManager: CLLocationManager
    
    var markersByDistance = [Marker]()
    
    override init () {
        self.locationManager = CLLocationManager()
        
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func start () {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Change of user location permissions
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            // Receive updates for location change
            self.locationManager.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(LocationNotifKey, object: self)
        
        // Don't handle new update if still updating
        if self.updating {
            return
        }
        
        self.updating = true
            
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            // Update with latest coordinate
            self.update(locations[locations.count - 1].coordinate)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.updating = false
                if self.delegate != nil {
                    self.firstUpdateComplete = true
                    self.delegate!.distanceTracker(updateDidComplete: self)
                }
            }
        }
    }

    func update (point: CLLocationCoordinate2D) {

        // Context
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        

        // Fetch request
        let fetchReq: NSFetchRequest = NSFetchRequest()
        fetchReq.entity = NSEntityDescription.entityForName("Marker", inManagedObjectContext: managedContext)
        //fetchReq.fetchBatchSize = 5
        //fetchReq.fetchLimit = result_limit
        fetchReq.resultType = .DictionaryResultType
        fetchReq.propertiesToFetch = ["latitude", "longitude", "timestamp", "public_id", "tags"]


        do {
            let markers = try managedContext.executeFetchRequest(fetchReq)
            var markers_with_distance = [Marker]()

            for marker in markers {
                let lat = marker["latitude"] as! CLLocationDegrees
                let lng = marker["longitude"] as! CLLocationDegrees
                
                // Calculate distance
                let marker_coords = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let distance = GMSGeometryDistance(point, marker_coords)
                
                var new_marker = Marker()
                new_marker.latitude = lat
                new_marker.longitude = lng
                new_marker.distance_from_me = distance
                new_marker.timestamp = marker.valueForKey("timestamp") as? Double
                new_marker.public_id = marker.valueForKey("public_id") as? String
                new_marker.tags = marker.valueForKey("tags") as? String
                
                markers_with_distance.append(new_marker)
            }
            
            self.markersByDistance = markers_with_distance.sort({
                $0.distance_from_me < $1.distance_from_me
            })
            
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
5
        // Save
        do {
            //try managedContext.save()
        } catch {
            print("save failed")
        }
    }
}