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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


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
    
    var latestCoord: CLLocationCoordinate2D? = nil
    
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
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Receive updates for location change
            self.locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: LocationNotifKey), object: self)
        
        // Don't handle new update if still updating
        if self.updating {
            return
        }
        
        self.updating = true
            
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            // Store latest coord
            self.latestCoord = locations[locations.count - 1].coordinate
            
            // Update with latest coordinate
            self.update(self.latestCoord!)
            
            DispatchQueue.main.async {
                self.updating = false
                if self.delegate != nil {
                    self.firstUpdateComplete = true
                    self.delegate!.distanceTracker(updateDidComplete: self)
                }
            }
        }
    }

    func update (_ point: CLLocationCoordinate2D) {

        // Context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        

        // Fetch request
        let fetchReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchReq.entity = NSEntityDescription.entity(forEntityName: "Marker", in: managedContext)

        fetchReq.resultType = .dictionaryResultType
        fetchReq.propertiesToFetch = ["latitude", "longitude", "timestamp", "public_id", "tags", "created"]


        do {
            let markers = try managedContext.fetch(fetchReq)
            var markers_with_distance = [Marker]()

            for marker in markers {
                let m = marker as AnyObject
                
                let lat = m["latitude"] as! CLLocationDegrees
                let lng = m["longitude"] as! CLLocationDegrees
                
                // Calculate distance
                let marker_coords = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let distance = GMSGeometryDistance(point, marker_coords)
                
                let new_marker = Marker()
                new_marker.latitude = lat
                new_marker.longitude = lng
                new_marker.distance_from_me = distance
                new_marker.timestamp = (marker as AnyObject).value(forKey: "timestamp") as? Double
                new_marker.public_id = (marker as AnyObject).value(forKey: "public_id") as? String
                new_marker.tags = (marker as AnyObject).value(forKey: "tags") as? String
                
                markers_with_distance.append(new_marker)
            }
            
            // Sort by distance nearest to furthest
            self.markersByDistance = markers_with_distance.sorted(by: {
                $0.distance_from_me < $1.distance_from_me
            })
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
}
