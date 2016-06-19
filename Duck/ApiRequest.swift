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
    
    optional func reqDidStart()
    
    optional func uploadDidProgress(progress: Float)
    
    optional func imageDownloadDidProgress(progress: Float)
    
    func reqDidComplete(data: NSDictionary, method: ApiMethod)
    
    optional func reqDidComplete(withImage image: UIImage)
    
    func reqDidFail(error: String, method: ApiMethod)
}


class ApiRequest {
    
    // MARK: Vars
    var delegate: ApiRequestDelegate?
    var progress: Float = 0.0
    let baseURL: String = "http://dukapp.io/api"
    
    // MARK: Methods
    func checkCredentials (email: String, password: String, successHandler: (() -> Void), failureHandler: ((message: String?) -> Void)) {
        
        // Add basic auth to request header
        let loginData = "\(email):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)

        let headers = ["Authorization": "Basic \(base64LoginString)"]
        
        // Execute request
        Alamofire.request(.GET, "\(baseURL)/authCheck", headers: headers)
            .responseString { response in
                
                switch response.result {
                case .Success:
                    successHandler()
                
                case .Failure(let error):
                    
                    // No connection
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                        failureHandler(message: "No active internet connection.")
                        
                    // Server returned status code
                    } else if let status = response.response?.statusCode {
                        
                        // Handle 401 or other
                        if status == 401 {
                            failureHandler(message: "Username or password is incorrect")
                        } else {
                            failureHandler(message: "An unexpected server response occurred. If this issue persists, please allow us to assist at dukapp.io/help")
                        }
                        
                    // No status code
                    } else {
                        failureHandler(message: "An unexpected server error occurred. If this issue persists, please allow us to assist at dukapp.io/help")
                    }
                }

            }
    }
    
    // Sends marker data and photo as multipart POST request to server
    func publishSingleMarker (credentials: Credentials, marker: Marker) {
        
        progress = 0
        
        // Add basic auth to request header
        let loginData = "\(credentials.email):\(credentials.password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        let headers = ["Authorization": "Basic \(base64LoginString)"]
        
        // Execute request
        Alamofire.upload(
            .POST,
            "\(baseURL)/markers",
            headers: headers,
            multipartFormData: { multipartFormData in
                
                // Add marker data to multipart form
                multipartFormData.appendBodyPart(data: "\(marker.latitude!)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "latitude")
                multipartFormData.appendBodyPart(data: "\(marker.longitude!)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "longitude")
                multipartFormData.appendBodyPart(data: "\(marker.tags!)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "tags")
                multipartFormData.appendBodyPart(data: marker.photo!, name: "photo", fileName: "photo", mimeType: "image/jpeg")
                multipartFormData.appendBodyPart(data: marker.photo_md!, name: "photo_md", fileName: "photo_md", mimeType: "image/jpeg")
                multipartFormData.appendBodyPart(data: marker.photo_sm!, name: "photo_sm", fileName: "photo_sm", mimeType: "image/jpeg")
                
            },
            encodingCompletion: { encodingResult in
                
                switch encodingResult {
                    
                case .Success(let upload, _, _):
                    
                    print("upload START SUCCESS")
                    
                    // Notify delegates upload begin
                    self.delegate?.reqDidStart?()
                    
                    // Track progress
                    upload.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in

                        dispatch_async(dispatch_get_main_queue()) {
                            
                            // Get percentage of uploaded bytes
                            let percentage: Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                            
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

                        self.handleResponse(response, method: .PublishMarker)

                    }
                case .Failure(let encodingError):
                    print("encoding error!!")
                    print(encodingError)
                }
            }
        )
    }
    
    // Get a single marker's data from API
    func getMarkerDataById (public_id: String) {
        
        let param = ["marker_id": public_id]
        
        // Exec request
        Alamofire.request(.GET, "\(baseURL)/markers", parameters: param)
            .responseJSON { response in
                self.handleResponse(response, method: .GetMarkerDataById)
        }
    }
    
    // Get marker data within geographic bounds
    func getMarkersWithinBounds (bounds: GMSCoordinateBounds) {
        
        // Build request params
        let params: [String: String] = [
            "bottom_left_lat": String(format: "%f", bounds.southWest.latitude),
            "bottom_left_lng": String(format: "%f", bounds.southWest.longitude),
            "upper_right_lat": String(format: "%f", bounds.northEast.latitude),
            "upper_right_lng": String(format: "%f", bounds.northEast.longitude)
        ]
        
        self.delegate?.reqDidStart?()
        
        // Exec request
        Alamofire.request(.GET, "\(baseURL)/markersWithin", parameters: params)
            .responseJSON { response in
                self.handleResponse(response, method: .MarkersWithinBounds)
            }
    }
    
    
    // Get Marker Image
    func getMarkerImage (fileName: String) {
        
        self.delegate?.reqDidStart?()
        
        // Set download destination path
        let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
        
        // Create file path
        let fm = NSFileManager.defaultManager()
        let path: [NSURL] = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let imgPath: NSURL = path[0].URLByAppendingPathComponent(fileName)
        
        // Ensure this image file does not already exist (should never happen)
        if fm.fileExistsAtPath(imgPath.path!) {
            print("SHOULD NEVER HAPPEN: Image existed after info window display")
            try! NSFileManager.defaultManager().removeItemAtURL(imgPath)
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
    func handleResponse (response: Response<AnyObject, NSError>, method: ApiMethod) {
        print("handling response")
        
        switch response.result {
            
        case .Success(let JSON):
            
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
                
                let message = res_json_dictionary.objectForKey("message") as! String
                self.delegate?.reqDidFail(message, method: method)

            // Server error
            } else if response_code >= 500 {
                self.delegate?.reqDidFail("A server error occurred.", method: method)
            }

            
        case .Failure(let error):
            
            let error_descrip = error.localizedDescription
            self.delegate?.reqDidFail(error_descrip, method: method)
        }
    }
    
    // ** Utils
    
    // Build http basic auth header from credentials
    func buildAuthHeader (credentials: Credentials) -> [String: String] {
        
        // Add basic auth to request header
        let loginData = "\(credentials.email):\(credentials.password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        return ["Authorization": "Basic \(base64LoginString)"]
    }
}

// Classify api method types for easier response handling
@objc enum ApiMethod: Int {
    case MarkersWithinBounds, Image, PublishMarker, GetMarkerDataById
}