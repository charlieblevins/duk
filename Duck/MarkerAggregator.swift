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
    
    func loadNearPoint (_ point: CLLocationCoordinate2D, noun: String?, searchType: SearchType) {
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
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            
            let found_markers = self.getCoreMarkersNear(point, noun: noun, searchType: searchType, limit: 30)
            
            // Add found_markers to aggregate in main thread
            DispatchQueue.main.async {
                self.aggregateStore! = self.aggregateStore! + found_markers!
                self.coreLoading = false
                
                if self.coreAndServerComplete() {
                    self.aggregate(.markersNearPoint)
                }
            }
        }
    }
    
    func loadWithinBounds (_ bounds: GMSCoordinateBounds, page: Int, noun: String?) {
        
        self.isLoading = true
        
        // Core markers within
        self.coreLoading = true
        
        self.noun = noun
        
        // Get from server
        self.serverLoading = true
        let req = ApiRequest()
        req.delegate = self
        req.getMarkersWithinBounds(bounds, page: page)
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            
            let found_markers = self.getCoreMarkersWithin(bounds, page: page)
            self.coreLoading = false
            
            // Add found_markers to aggregate in main thread
            DispatchQueue.main.async {
                self.aggregateStore! = self.aggregateStore! + found_markers!
                
                
                if self.coreAndServerComplete() {
                    self.aggregate(.markersWithinBounds)
                }
            }
        }

    }
    
    // Show user's saved markers if they exist
    func getCoreMarkersWithin (_ bounds: GMSCoordinateBounds, page: Int) -> [Marker]? {
        
        let markersPerPage = 10
        let startInd = (page - 1) * markersPerPage
        
        var found_markers = [Marker]()
        
        let markers_from_core = Marker.allMarkersWithFields(["latitude", "longitude", "timestamp", "public_id", "tags"])
        
        if markers_from_core.count == 0 {
            return nil
        }
        
        // Find and return markers within provided bounds
        for marker in markers_from_core {
            
            // Get marker coords
            let coords = CLLocationCoordinate2D(latitude: marker.latitude!, longitude: marker.longitude!)
            
            if bounds.contains(coords) {
                found_markers.append(marker)
            }
        }
        
        // Return found_markers sliced at start index
        let ret: Array<Marker> = Array(found_markers[startInd..<found_markers.count])
        return ret
    }
    
    // Get local markers sorted by distance_to_me. Optionally filtered by tags. Limit 30
    func getCoreMarkersNear (_ point: CLLocationCoordinate2D, noun: String?, searchType: SearchType, limit: Int) -> [Marker]? {
        
        var markers = [Marker]()
        
        // Background sorted markers
        if searchType == .myLocation {
            markers = DistanceTracker.sharedInstance.markersByDistance
        
        // Get sorted markers near point
        } else if searchType == .address {
            
            // Replace distance_from_me with distance from "address"
            markers = Marker.allMarkersWithFields(["latitude", "longitude", "timestamp", "public_id", "tags"])
            markers = markers.map({ marker in
                
                let new_marker = marker
                
                let coords = CLLocationCoordinate2D(latitude: marker.latitude!, longitude: marker.longitude!)
                new_marker.distance_from_me = GMSGeometryDistance(point, coords)
                
                return new_marker
            })
            
        } else {
            print("search type not supported")
            return nil
        }
        
        // No nouns: return markersByDistance
        if noun == nil {
            if markers.count < 30 {
                return Array(markers)
            } else {
                return Array(markers[0..<30])
            }
        
        } else {
            
            var matched_markers = [Marker]()
            
            // Check each marker for matching tags
            for marker in markers {
                
                // If this marker has tags
                if let tags = marker.tags {
                    
                    let marker_noun_arr = tags.components(separatedBy: " ")
                    
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
    func aggregate (_ aggregationType: LoadMethod) {
        
        switch aggregationType {
        
        // Given 30 from server and 15 local, get 30 closest
        case .markersWithinBounds:
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                self.aggregateStore = self.removeDuplicates(self.aggregateStore!)
                
                // Load complete - notify delegate
                DispatchQueue.main.async {
                    
                    // If a delegate is assigned and this request has not been cancelled
                    if self.delegate != nil && self.cancelled == false {
                        self.delegate!.markerAggregator(loadDidComplete: self.aggregateStore!, method: .markersWithinBounds, noun: self.noun)
                    }
                }
            }
        break;
            
        
        // Return 30 closest markers
        case .markersNearPoint:
            
            // Get 30 nearest markers
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                
                // Prune and filter markers (if any were found)
                if (self.aggregateStore!.count > 0) {
                    self.aggregateStore = self.removeDuplicates(self.aggregateStore!)
                    self.aggregateStore = self.filterClosest(markers: self.aggregateStore!, limit: 30)
                }
                
                // Load complete - notify delegate
                DispatchQueue.main.async {
                    
                    // If a delegate is assigned and this request has not been cancelled
                    if self.delegate != nil && self.cancelled == false {
                        self.delegate!.markerAggregator(loadDidComplete: self.aggregateStore!, method: .markersNearPoint, noun: self.noun)
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
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        
        if data["data"] == nil {
            print("Api server returned no data")
            return Void()
        }
        
        switch method {
            
        case .markersNearPoint:
            handleMarkersNearResponse(data)
            
        case .markersWithinBounds:
            handleMarkersWithinBoundsResponse(data)
            break
            
        default:
            print("Unknown api method")
        }
    }
    
    func reqDidFail(_ error: String, method: ApiMethod, code: Int) {
        
        switch method {
            
        case .markersNearPoint:
            print("MarkersNearPoint api request failed")
            break
            
        case .markersWithinBounds:
            print("MarkersWithinBounds api request failed")
            break
            
        default:
            print("Unknown api method failed")
        }
        
        self.serverLoading = false
        
        if self.coreAndServerComplete() {
            self.aggregate(.markersNearPoint)
        }
    }
    
    
    // Handle data returned from a markersWithinBounds api request
    func handleMarkersWithinBoundsResponse (_ data: NSDictionary) {
        
        var server_markers = [Marker]()
        
        // Convert received dictionary to [DukGMSMarker]
        let marker_array = data["data"] as! [AnyObject]
        for marker_data in marker_array {
            
            // Convert data to DukGMSMarker
            let marker = Marker(fromPublicData: marker_data as! [String: AnyObject] as NSDictionary)
            server_markers.append(marker!)
        }
        
        self.serverLoading = false
        self.aggregateStore! = self.aggregateStore! + server_markers
        
        if self.coreAndServerComplete() {
            self.aggregate(.markersNearPoint)
        }
    }
    
    func handleMarkersNearResponse (_ data: NSDictionary) {
        var server_markers = [Marker]()
        
        // Convert received dictionary to [DukGMSMarker]
        let marker_array = data["data"] as! [AnyObject]
        for marker_data in marker_array {
            
            // Convert data to DukGMSMarker
            let marker = Marker(fromPublicData: marker_data as! [String: AnyObject] as NSDictionary)
            server_markers.append(marker!)
        }
        
        self.serverLoading = false
        self.aggregateStore! = self.aggregateStore! + server_markers
        
        if self.coreAndServerComplete() {
            self.aggregate(.markersNearPoint)
        }
    }
    
    // Remove duplicates between core data and server data (for case where server returns public marker 
    // that also exists in core data)
    func removeDuplicates (_ markers: [Marker]) -> [Marker] {
        
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
        
        let sorted = markers.sorted {
            
            // send either to back if nil
            guard let d0 = $0.distance_from_me else {
                return false
            }
            guard let d1 = $1.distance_from_me else {
                return true
            }
            
            return d0 < d1
        }
        
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
    case markersWithinBounds, markersNearPoint
}
