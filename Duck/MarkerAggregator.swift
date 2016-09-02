//
//  MarkerAggregator.swift
//  Duck
//
//  Created by Charlie Blevins on 7/2/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData
import GoogleMaps

protocol MarkerAggregatorDelegate {
    
    func markerAggregator(loadDidComplete data: [Marker], method: LoadMethod, noun: String?)
    
    func markerAggregator(loadDidFail error: String, method: LoadMethod)
}

class MarkerAggregator: NSObject, ApiRequestDelegate, CLLocationManagerDelegate, DistanceTrackerDelegate {
    
    // Create globally available shared instancae (Singleton)
    //static let sharedInstance = MarkerAggregator()
    
    var isLoading: Bool = false
    var coreLoading: Bool = false
    var serverLoading: Bool = false
    
    var cancelled: Bool = false
    
    var noun: String? = nil
    
    var distanceDataCallback: (()->Void)? = nil
    
    var aggregateStore: [Marker]? = []
    
    var delegate: MarkerAggregatorDelegate? = nil
    
    override init () {
        super.init()
    }
    
    func loadNearPoint (point: CLLocationCoordinate2D, noun: String?) {
        self.isLoading = true
        
        self.coreLoading = true
        
        self.noun = noun
        
        // Get from server
        self.serverLoading = true
        let apiRequest = ApiRequest()
        apiRequest.delegate = self
        apiRequest.getMarkersNear(point, noun: noun)
        
        // Get from core
        self.coreLoading = true
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            let found_markers = self.getCoreMarkersNear(point, noun: noun, limit: 30)
            
            // Add found_markers to aggregate in main thread
            dispatch_async(dispatch_get_main_queue()) {
                self.aggregateStore! = self.aggregateStore! + found_markers!
                self.coreLoading = false
                
                if self.coreAndServerComplete() {
                    self.aggregate(.MarkersNearPoint)
                }
            }
        }
    }
    
    func loadWithinBounds (bounds: GMSCoordinateBounds, page: Int, noun: String?) {
        
        self.isLoading = true
        
        // Core markers within
        self.coreLoading = true
        
        self.noun = noun
        
        // Get from server
        self.serverLoading = true
        let req = ApiRequest()
        req.delegate = self
        req.getMarkersWithinBounds(bounds, page: page)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            let found_markers = self.getCoreMarkersWithin(bounds, page: page)
            self.coreLoading = false
            
            // Add found_markers to aggregate in main thread
            dispatch_async(dispatch_get_main_queue()) {
                self.aggregateStore! = self.aggregateStore! + found_markers!
                
                
                if self.coreAndServerComplete() {
                    self.aggregate(.MarkersWithinBounds)
                }
            }
        }

    }
    
    // Show user's saved markers if they exist
    func getCoreMarkersWithin (bounds: GMSCoordinateBounds, page: Int) -> [Marker]? {
        
        let markersPerPage = 10
        let startInd = (page - 1) * markersPerPage
        
        var found_markers = [Marker]()
        
        let markers_from_core = Util.fetchCoreData("Marker", predicate: nil)
        
        if markers_from_core.count == 0 {
            return nil
        }
        
        // Find and return markers within provided bounds
        for marker_data in markers_from_core {
            
            let marker = Marker(fromCoreData: marker_data)
            
            // Get marker coords
            let coords = CLLocationCoordinate2D(latitude: marker.latitude!, longitude: marker.longitude!)
            
            if bounds.containsCoordinate(coords) {
                found_markers.append(marker)
            }
        }
        
        // Return found_markers sliced at start index
        let ret: Array<Marker> = Array(found_markers[startInd..<found_markers.count])
        return ret
    }
    
    // Get local markers sorted by distance_to_me. Optionally filtered by tags. Limit 30
    func getCoreMarkersNear (point: CLLocationCoordinate2D, noun: String?, limit: Int) -> [Marker]? {
        
        // No nouns: return markersByDistance
        if noun == nil {
            if DistanceTracker.sharedInstance.markersByDistance.count < 30 {
                return Array(DistanceTracker.sharedInstance.markersByDistance)
            } else {
                return Array(DistanceTracker.sharedInstance.markersByDistance[0..<30])
            }
        
        } else {
            
            var matched_markers = [Marker]()
            
            // Check each marker for matching tags
            for marker in DistanceTracker.sharedInstance.markersByDistance {
                
                // If this marker has tags
                if let tags = marker.tags {
                    
                    let marker_noun_arr = tags.componentsSeparatedByString(" ")
                    
                    // If true, marker is kept
                    if marker_noun_arr.contains(noun!) {
                        matched_markers.append(marker)
                        
                        // End after 30 (limit)
                        if matched_markers.count >= 30 {
                            break
                        }
                    }
                }
            }
            
            return matched_markers
        }
    }
    
    // Aggregate core and server data according to load method
    func aggregate (aggregationType: LoadMethod) {
        
        switch aggregationType {
        
        // Given 30 from server and 15 local, get 30 closest
        case .MarkersWithinBounds:
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                self.aggregateStore = self.removeDuplicates(self.aggregateStore!)
                
                // Load complete - notify delegate
                dispatch_async(dispatch_get_main_queue()) {
                    
                    // If a delegate is assigned and this request has not been cancelled
                    if self.delegate != nil && self.cancelled == false {
                        self.delegate!.markerAggregator(loadDidComplete: self.aggregateStore!, method: .MarkersWithinBounds, noun: self.noun)
                    }
                }
            }
        break;
            
        
        // Return 30 closest markers
        case .MarkersNearPoint:
            
            // Get 30 nearest markers
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                
                // Prune and filter markers (if any were found)
                if (self.aggregateStore!.count > 0) {
                    self.aggregateStore = self.removeDuplicates(self.aggregateStore!)
                    self.aggregateStore = self.filterClosest(self.aggregateStore!, limit: 30)
                }
                
                // Load complete - notify delegate
                dispatch_async(dispatch_get_main_queue()) {
                    
                    // If a delegate is assigned and this request has not been cancelled
                    if self.delegate != nil && self.cancelled == false {
                        self.delegate!.markerAggregator(loadDidComplete: self.aggregateStore!, method: .MarkersNearPoint, noun: self.noun)
                    }
                }
            }
        break;
        }
    }
    
    func coreAndServerComplete () -> Bool {
        return !self.coreLoading && !self.serverLoading
    }
    
    // ApiRequestDelegate methods
    
    // Route data received from api to corresponding handler function
    func reqDidComplete(data: NSDictionary, method: ApiMethod) {
        
        if data["data"] == nil {
            print("Api server returned no data")
            return Void()
        }
        
        switch method {
            
        case .MarkersNearPoint:
            handleMarkersNearResponse(data)
            
        case .MarkersWithinBounds:
            handleMarkersWithinBoundsResponse(data)
            break
            
        default:
            print("Unknown api method")
        }
    }
    
    func reqDidFail(error: String, method: ApiMethod) {
        
        switch method {
            
        case .MarkersNearPoint:
            print("MarkersNearPoint api request failed")
            break
            
        case .MarkersWithinBounds:
            print("MarkersWithinBounds api request failed")
            break
            
        default:
            print("Unknown api method failed")
        }
        
        self.serverLoading = false
        
        if self.coreAndServerComplete() {
            self.aggregate(.MarkersNearPoint)
        }
    }
    
    
    // Handle data returned from a markersWithinBounds api request
    func handleMarkersWithinBoundsResponse (data: NSDictionary) {
        
        var server_markers = [Marker]()
        
        // Convert received dictionary to [DukGMSMarker]
        let marker_array = data["data"] as! [AnyObject]
        for marker_data in marker_array {
            
            // Convert data to DukGMSMarker
            let marker = Marker(fromPublicData: marker_data as! [String: AnyObject])
            server_markers.append(marker!)
        }
        
        self.serverLoading = false
        self.aggregateStore! = self.aggregateStore! + server_markers
        
        if self.coreAndServerComplete() {
            self.aggregate(.MarkersNearPoint)
        }
    }
    
    func handleMarkersNearResponse (data: NSDictionary) {
        var server_markers = [Marker]()
        
        // Convert received dictionary to [DukGMSMarker]
        let marker_array = data["data"] as! [AnyObject]
        for marker_data in marker_array {
            
            // Convert data to DukGMSMarker
            let marker = Marker(fromPublicData: marker_data as! [String: AnyObject])
            server_markers.append(marker!)
        }
        
        self.serverLoading = false
        self.aggregateStore! = self.aggregateStore! + server_markers
        
        if self.coreAndServerComplete() {
            self.aggregate(.MarkersNearPoint)
        }
    }
    
    // Remove duplicates between core data and server data (for case where server returns public marker 
    // that also exists in core data)
    func removeDuplicates (markers: [Marker]) -> [Marker] {
        
        var serverMarkersById: [String: Marker] = [:]
        
        // Store map marker by public id, overwriting any duplicate ids
        for marker in markers {
            if marker.public_id != nil {
                serverMarkersById[marker.public_id!] = marker
            } else {
                serverMarkersById["\(marker.timestamp!)"] = marker
            }
        }
        
        // Make array from remaining values
        return Array(serverMarkersById.values)
    }
    
    // Reduce a set of markers to the closest limited by total
    func filterClosest (markers: [Marker], limit: Int) -> [Marker] {
        
        let last_ind = ((limit > markers.count) ? markers.count : limit) - 1
        
        let sorted = markers.sort({ $0.distance_from_me < $1.distance_from_me })
        
        return [Marker](sorted[0...last_ind])
    }

    // Receive update when distanceTracker updates
    func distanceTracker(updateDidComplete distanceTracker: DistanceTracker) {
        if self.distanceDataCallback != nil {
            self.distanceDataCallback!()
            self.distanceDataCallback = nil
        }
    }
}

// Classify api method types for easier response handling
@objc enum LoadMethod: Int {
    case MarkersWithinBounds, MarkersNearPoint
}