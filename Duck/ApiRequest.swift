//
//  ApiRequest.swift
//  Duck
//
//  Created by Charlie Blevins on 1/30/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import GoogleMaps

@objc protocol ApiRequestDelegate {
    
    @objc optional func reqDidStart()
    
    @objc optional func uploadDidProgress(_ progress: Float)
    
    @objc optional func imageDownloadDidProgress(_ progress: Float)
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod)
    
    @objc optional func reqDidComplete(withImage image: UIImage)
    
    func reqDidFail(_ error: String, method: ApiMethod)
}


class ApiRequest {
    
    // MARK: Vars
    var delegate: ApiRequestDelegate?
    var progress: Float = 0.0
    let baseURL: String = "http://dukapp.io/api"
    
    // MARK: Methods
    func checkCredentials (_ email: String, password: String, successHandler: @escaping (() -> Void), failureHandler: @escaping ((_ message: String?) -> Void)) {
        
        // Add basic auth to request header
        let loginData = "\(email):\(password)".data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString(options: .lineLength64Characters)

        let headers = ["Authorization": "Basic \(base64LoginString)"]
        
        // Execute request
        Alamofire.request("\(baseURL)/authCheck", headers: headers)
            .responseString { response in
                
                switch response.result {
                case .success:
                    successHandler()
                
                case .failure(let error as NSError):
                    
                    // No connection
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                        failureHandler("No active internet connection.")
                        
                    // Server returned status code
                    } else if let status = response.response?.statusCode {
                        
                        // Handle 401 or other
                        if status == 401 {
                            failureHandler("Username or password is incorrect")
                        } else {
                            failureHandler("An unexpected server response occurred. If this issue persists, please allow us to assist at dukapp.io/help")
                        }
                        
                    // No status code
                    } else {
                        failureHandler("An unexpected server error occurred. If this issue persists, please allow us to assist at dukapp.io/help")
                    }
                }

            }
    }
    
    // Sends marker data and photo as multipart POST request to server
    func publishSingleMarker (_ credentials: Credentials, marker: Marker) {
        
        progress = 0
        
        // Add basic auth to request header
        let loginData = "\(credentials.email):\(credentials.password)".data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString(options: .lineLength64Characters)
        
        let headers = ["Authorization": "Basic \(base64LoginString)"]
        
        // Execute request
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                
                // Add marker data to multipart form
                multipartFormData.append("\(marker.latitude!)".data(using: String.Encoding.utf8)!, withName: "latitude")
                multipartFormData.append("\(marker.longitude!)".data(using: String.Encoding.utf8)!, withName: "longitude")
                multipartFormData.append("\(marker.tags!)".data(using: String.Encoding.utf8)!, withName: "tags")
                multipartFormData.append(marker.photo!, withName: "photo", fileName: "photo", mimeType: "image/jpeg")
                multipartFormData.append(marker.photo_md!, withName: "photo_md", fileName: "photo_md", mimeType: "image/jpeg")
                multipartFormData.append(marker.photo_sm!, withName: "photo_sm", fileName: "photo_sm", mimeType: "image/jpeg")
                
            },
            to: baseURL + "/markers",
            method: .post,
            headers: headers,
            encodingCompletion: { encodingResult in
                
                switch encodingResult {
                    
                case .success(let upload, _, _):
                    
                    print("upload START SUCCESS")
                    
                    // Notify delegates upload begin
                    self.delegate?.reqDidStart?()
                    
                    upload.uploadProgress { progress in
                        print(progress)
                        DispatchQueue.main.async {
                            // Get percentage of uploaded bytes
                            let percentage: Float = Float(progress.fractionCompleted)
                            
                            // If next percent reached: notify delegates
                            if percentage > self.progress {
                                self.progress = percentage
                                self.delegate?.uploadDidProgress?(percentage)
                            }
                        }
                    }
                        
                    // Response JSON received (complete)
                    // TODO: Handle request failure (server not responding)
                    // TODO: Handle failure response codes
                    upload.responseJSON { response in
                        self.handleResponse(response, method: .publishMarker)
                    }

                case .failure(let encodingError):
                    print("encoding error!!")
                    print(encodingError)
                }
            })
 
    }
    
    // Get a single marker's data from API
    // Optionally request base 64 photo data by size
    func getMarkerDataById (_ public_id: String, photo_size: String?) {
        
        var params = ["marker_id": public_id]
        
        if photo_size != nil {
            params["photo"] = photo_size!
        }
        
        // Exec request
        Alamofire.request(.GET, "\(baseURL)/markers", parameters: params)
            .responseJSON { response in
                self.handleResponse(response, method: .GetMarkerDataById)
        }
    }
    
    // Get marker data within geographic bounds
    func getMarkersWithinBounds (_ bounds: GMSCoordinateBounds, page: Int?) {
        
        // Build request params
        var params: [String: String] = [
            "bottom_left_lat": String(format: "%f", bounds.southWest.latitude),
            "bottom_left_lng": String(format: "%f", bounds.southWest.longitude),
            "upper_right_lat": String(format: "%f", bounds.northEast.latitude),
            "upper_right_lng": String(format: "%f", bounds.northEast.longitude)
        ]
        
        if page != nil {
            params["page"] = "\(page)"
        }
        
        self.delegate?.reqDidStart?()
        
        // Exec request
        Alamofire.request(.GET, "\(baseURL)/markersWithin", parameters: params)
            .responseJSON { response in
                self.handleResponse(response, method: .MarkersWithinBounds)
            }
    }
    
    // Get marker data near lat/lng point
    func getMarkersNear (_ point: CLLocationCoordinate2D, noun: String?) {
        
        // Build request params
        var params: [String: String] = [
            "lat": String(format: "%f", point.latitude),
            "lng": String(format: "%f", point.longitude)
        ]
        
        if noun != nil {
            params["noun"] = noun
        }
        
        self.delegate?.reqDidStart?()
        
        // Exec request
        Alamofire.request(.GET, "\(baseURL)/markersNear", parameters: params)
            
            .responseJSON { response in
                self.handleResponse(response, method: .MarkersNearPoint)
            }
    }
    
    // Get Marker Image
    func getMarkerImage (_ fileName: String) {
        
        self.delegate?.reqDidStart?()
        
        // Set download destination path
        let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
        
        // Create file path
        let fm = FileManager.default
        let path: [URL] = fm.urls(for: .documentDirectory, in: .userDomainMask)
        let imgPath: URL = path[0].appendingPathComponent(fileName)
        
        // Ensure this image file does not already exist (should never happen)
        if fm.fileExists(atPath: imgPath.path) {
            print("SHOULD NEVER HAPPEN: Image existed after info window display")
            try! FileManager.default.removeItem(at: imgPath)
        }
        
        // Exec request
        Alamofire.download(.GET, "http://dukapp.io/photos/\(fileName)", destination: destination)
            
            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                print(totalBytesRead)
                
                // This closure is NOT called on the main queue for performance
                // reasons. To update your ui, dispatch to the main queue.
                dispatch_async(dispatch_get_main_queue()) {
                    print("Total bytes read on main queue: \(totalBytesRead)")
                    
                    // Get percentage of downloaded bytes
                    let percentage: Float = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    
                    // If next percent reached: notify delegates
                    if percentage > self.progress {
                        self.progress = percentage
                        self.delegate?.imageDownloadDidProgress?(percentage)
                    }
                }
            }
        
            .response { _, response, _, error in
                print("handling response")
                
                if let error = error {
                    
                    print("Failed with error: \(error)")
                    let error_descrip = error.localizedDescription
                    self.delegate?.reqDidFail(error_descrip, method: .Image)
                    
                } else {
                    print("Downloaded file successfully")
                    
                    // Get http status code
                    let response_code = response!.statusCode
                    
                    // Success: code between 200 and 300
                    if response_code >= 200 && response_code < 300 {
                        
                        // Convert data to UIImage
                        let imgData: NSData = NSData(contentsOfFile: imgPath.path!)!
                        
                        let image: UIImage = UIImage(data: imgData)!
                        
                        // Notify delegates of upload complete
                        self.delegate?.reqDidComplete!(withImage: image)
                        
                        // Delete downloaded image
                        if fm.fileExistsAtPath(imgPath.path!) {
                            try! NSFileManager.defaultManager().removeItemAtURL(imgPath)
                        }
                        
                        // 400 status code. message prop should exist
                    } else if response_code >= 300 && response_code < 500 {
                        
                        let message = "Server responded with http error response code \(response_code)"
                        self.delegate?.reqDidFail(message, method: .Image)
                        
                        // Server error
                    } else if response_code >= 500 {
                        self.delegate?.reqDidFail("A server error occurred.", method: .Image)
                    }
                }

            }
    }
    
    // Handles an alamofire response object and calls associated delegate methods
    func handleResponse (_ response: DataResponse<Any>, method: ApiMethod) {
        print("handling response")
        
        switch response.result {
            
        case .success(let JSON):
            
            // Get json as dictionary
            let res_json_dictionary = JSON as! NSDictionary

            // Get http status code
            let response_code = response.response!.statusCode
            
            // Success: code between 200 and 300
            if response_code >= 200 && response_code < 300 {
                
                // Notify delegates of upload complete
                self.delegate?.reqDidComplete(res_json_dictionary, method: method)
            
            // 400 status code. message prop should exist
            } else if response_code >= 300 && response_code < 500 {
                
                let message = res_json_dictionary.object(forKey: "message") as! String
                self.delegate?.reqDidFail(message, method: method)

            // Server error
            } else if response_code >= 500 {
                self.delegate?.reqDidFail("A server error occurred.", method: method)
            }

            
        case .failure(let error):
            
            let error_descrip = error.localizedDescription
            self.delegate?.reqDidFail(error_descrip, method: method)
        }
    }
    
    // ** Utils
    
    // Build http basic auth header from credentials
    func buildAuthHeader (_ credentials: Credentials) -> [String: String] {
        
        // Add basic auth to request header
        let loginData = "\(credentials.email):\(credentials.password)".data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString(options: .lineLength64Characters)
        
        return ["Authorization": "Basic \(base64LoginString)"]
    }
}

// Classify api method types for easier response handling
@objc enum ApiMethod: Int {
    case markersWithinBounds, markersNearPoint, image, publishMarker, getMarkerDataById
}
