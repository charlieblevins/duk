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
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int)
    
    @objc optional func reqDidComplete(withImage image: UIImage)
    
    func reqDidFail(_ error: String, method: ApiMethod, code: Int)
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
                default:
                    print("unexpected result: \(response.result)")
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
                multipartFormData.append("\(marker.createdString)".data(using: String.Encoding.utf8)!, withName: "created")
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
    
    func editSingleMarker (_ credentials: Credentials, public_id: String, tags: String) {
        
        let params: Parameters = [
            "public_id": public_id,
            "tags": tags
        ]
        
        // Add basic auth to request header
        let loginData = "\(credentials.email):\(credentials.password)".data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString(options: .lineLength64Characters)
        
        let headers = ["Authorization": "Basic \(base64LoginString)"]
        
        // Exec request
        Alamofire.request("\(baseURL)/markers", method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                self.handleResponse(response, method: .editMarker)
        }
    }
    
    // Get a single marker's data from API
    // Optionally request base 64 photo data by size
    func getMarkerDataById (_ markers: Array<Dictionary<String, Any>>) {
        
        let params: Parameters = ["markers": markers]
        
        // Exec request
        Alamofire.request("\(baseURL)/getMarkersById", method: .post, parameters: params, encoding: JSONEncoding.default)
            .responseJSON { response in
                self.handleResponse(response, method: .getMarkerDataById)
        }
    }
    
    // Delete a single marker by id
    func deleteMarker (_ public_id: String, credentials: Credentials) {
        
        let params = ["marker_id": public_id]
        
        // Add basic auth to request header
        let loginData = "\(credentials.email):\(credentials.password)".data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString(options: .lineLength64Characters)
        
        let headers = ["Authorization": "Basic \(base64LoginString)"]
        
        // Exec request
        Alamofire.request("\(baseURL)/markers", method: .delete, parameters: params, headers: headers)
            .responseJSON { response in
                self.handleResponse(response, method: .deleteById)
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
        Alamofire.request("\(baseURL)/markersWithin", method: .get, parameters: params)
            .responseJSON { response in
                self.handleResponse(response, method: .markersWithinBounds)
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
        Alamofire.request("\(baseURL)/markersNear", method: .get, parameters: params)
            
            .responseJSON { response in
                self.handleResponse(response, method: .markersNearPoint)
            }
    }
    
    // Get Marker Image
    func getMarkerImage (_ fileName: String) {
        
        self.delegate?.reqDidStart?()
        
        // Set download destination path
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory, in: .userDomainMask)
        
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
        Alamofire.download("http://dukapp.io/photos/\(fileName)", to: destination)
            
            .downloadProgress { progress in
                
                // This closure is NOT called on the main queue for performance
                // reasons. To update ui, dispatch to the main queue.
                DispatchQueue.main.async {
                    print("Fraction downloaded on main queue: \(progress.fractionCompleted)")
                    
                    // Get percentage of downloaded bytes
                    let percentage: Float = Float(progress.fractionCompleted)
                    
                    // If next percent reached: notify delegates
                    if percentage > self.progress {
                        self.progress = percentage
                        self.delegate?.imageDownloadDidProgress?(percentage)
                    }
                }
            }
        
            .responseData { response in
                print("handling response")
                let result = response.result
                
                if let error = result.error {
                    
                    print("Failed with error: \(error)")
                    let error_descrip = error.localizedDescription
                    self.delegate?.reqDidFail(error_descrip, method: .image, code: 0)
                    
                } else {
                    print("Downloaded file successfully")
                    
                    // Get http status code
                    guard let response_code = response.response?.statusCode else {
                        print("Could not retrieve http response code")
                        return
                    }
                    
                    // Success: code between 200 and 300
                    if response_code >= 200 && response_code < 300 {
                        
                        // Convert data to UIImage
                        let imgData: NSData = NSData(contentsOfFile: imgPath.path)!
                        
                        let image: UIImage = UIImage(data: imgData as Data)!
                        
                        // Notify delegates of upload complete
                        self.delegate?.reqDidComplete!(withImage: image)
                        
                        // Delete downloaded image
                        if fm.fileExists(atPath: imgPath.path) {
                            try! FileManager.default.removeItem(at: imgPath)
                        }
                        
                        // 400 status code. message prop should exist
                    } else if response_code >= 300 && response_code < 500 {
                        
                        let message = "Server responded with http error response code \(response_code)"
                        self.delegate?.reqDidFail(message, method: .image, code: response_code)
                        
                        // Server error
                    } else if response_code >= 500 {
                        self.delegate?.reqDidFail("A server error occurred.", method: .image, code: response_code)
                    }
                }

            }
    }
    
    // Get all markers created by a user
    func getMarkersByUser (_ credentials: Credentials) {
        
        // Add basic auth to request header
        let loginData = "\(credentials.email):\(credentials.password)".data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString(options: .lineLength64Characters)
        
        let headers = ["Authorization": "Basic \(base64LoginString)"]
        
        // Exec request
        Alamofire.request("\(baseURL)/markersByUser", method: .get, parameters: nil, headers: headers)
            .responseJSON { response in
                self.handleResponse(response, method: .markersByUser)
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
                
                // Notify delegate of upload complete
                self.delegate?.reqDidComplete(res_json_dictionary, method: method, code: response_code)
            
            // 400 status code. message prop should exist
            } else if response_code >= 300 && response_code < 500 {
                
                let message = res_json_dictionary.object(forKey: "message") as! String
                self.delegate?.reqDidFail(message, method: method, code: response_code)

            // Server error
            } else if response_code >= 500 {
                self.delegate?.reqDidFail("A server error occurred.", method: method, code: response_code)
            }

            
        case .failure(let error):
            
            let error_descrip = error.localizedDescription
            self.delegate?.reqDidFail(error_descrip, method: method, code: 0)
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
    case markersWithinBounds, markersNearPoint, image, publishMarker, getMarkerDataById, deleteById, markersByUser, editMarker
}
