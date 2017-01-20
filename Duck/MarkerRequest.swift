//
//  MarkerRequest.swift
//  Duck
//
//  Created by Charlie Blevins on 1/20/17.
//  Copyright © 2017 Charlie Blevins. All rights reserved.
//

import Foundation

// Use this class to make server requests for marker data
// Parses returned received JSON into usable Marker struct types
class MarkerRequest: ApiRequestDelegate {
    
    var apiRequest: ApiRequest
    var loadByIdCompletion: ((_ markers: [Marker]?) -> Void)? = nil
    var failure: (() -> Void)? = nil
    
    init () {
        apiRequest = ApiRequest()
        apiRequest.delegate = self
    }
    
    // The sizes of photo stored on the server
    enum PhotoSizes: String {
        case sm = "sm"
        case md = "md"
        case full = "full"
    }
    
    // Required format for loadById
    struct LoadByIdParamsSingle {
        
        var public_id: String
        var sizes: Array<PhotoSizes>
        
        init (_ public_id: String, sizes: Array<PhotoSizes>) {
            self.public_id = public_id
            self.sizes = sizes
        }
        
        // Convert to array to easily pass into func loadById()
        func toArray () -> Array<LoadByIdParamsSingle> {
            return [self]
        }
    }
    
    func loadById (_ markersRequested: Array<LoadByIdParamsSingle>, completion: (_ markers: [Marker]?) -> Void, failure: () -> Void) {
        
        // Convert types to more basic dictionary and array
        var params: Array<Dictionary<String, Any>> = []
        
        for param_single in markersRequested {
            
            let sizes_raw = param_single.sizes.map({
                return $0.rawValue
            })
        
            let marker_params: Dictionary<String, Any> = [
                "public_id": param_single.public_id,
                "photo_size": sizes_raw
            ]
            params.append(marker_params)
        }
        
        // Make request
        apiRequest.getMarkerDataById(params)
    }
    
    /**
     * ApiRequestDelegate required methods
     */
    func reqDidStart() {}
    
    // Format dat and execute callback
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        
        if (method == .getMarkerDataById && self.loadByIdCompletion != nil) {
            self.loadByIdCompletion?(self.formatGetMarkerDataByIdResult(data))
            self.loadByIdCompletion = nil
        }
        
    }
    
    // Show alert on failure
    func reqDidFail(_ error: String, method: ApiMethod, code: Int) {
        if method == .getMarkerDataById {
            if let fail = self.failure {
                fail()
            }
        }
        
        self.failure = nil
    }
    
    
    /** Formatters
     *  for received data. Convert to useful types
     **/
    
    private func formatGetMarkerDataByIdResult (_ data: NSDictionary) -> [Marker]? {
        
        // Convert returned to marker objects
        guard let returned = data.value(forKey: "data") as? Array<Any> else {
            print("Returned markers could not be converted to an array")
            return nil
        }
        
        guard returned.count > 0 else {
            print("No public markers returned by getMarkerDataById")
            return nil
        }
        
        var markers = [Marker]()
        
        for marker_data in returned {
            
            guard let data_dic: NSDictionary = marker_data as? NSDictionary else {
                print("could not cast to NSDictionary")
                break
            }
            
            if let marker = Marker(fromPublicData: data_dic) {
                markers.append(marker)
            }
        }
        
        return markers
    }

}
