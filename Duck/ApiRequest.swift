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

protocol ApiRequestDelegate {
    
    func uploadDidStart()
    
    func uploadDidProgress(progress: Float)
    
    func uploadDidComplete(data: NSDictionary)
    
    func uploadDidFail(error: ErrorType)
}

enum APIError: ErrorType {
    case NoInternet
    case HTTPError(message: String)
    case ServerError(message: String)
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
    
    func publishSingleMarker (credentials: Credentials, marker: Marker, successHandler: (() -> Void), failureHandler: ((message: String?) -> Void)) {
        
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
                multipartFormData.appendBodyPart(data: "\(marker.latitude)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "latitude")
                multipartFormData.appendBodyPart(data: "\(marker.longitude)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "longitude")
                multipartFormData.appendBodyPart(data: "\(marker.tags)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "tags")
                multipartFormData.appendBodyPart(data: marker.photo, name: "photo", fileName: "TestFile", mimeType: "image/jpeg")
                
            },
            encodingCompletion: { encodingResult in
                
                switch encodingResult {
                    
                case .Success(let upload, _, _):
                    
                    print("upload START SUCCESS")
                    
                    // Notify delegates upload begin
                    self.delegate?.uploadDidStart()
                    
                    // Track progress
                    upload.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in

                        dispatch_async(dispatch_get_main_queue()) {
                            
                            // Get percentage of uploaded bytes
                            let percentage: Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                            
                            // If next percent reached: notify delegates
                            if percentage > self.progress {
                                self.progress = percentage
                                self.delegate?.uploadDidProgress(percentage)
                            }
                        }

                    }
                    
                    // Response JSON received (complete)
                    // TODO: Handle request failure (server not responding)
                    // TODO: Handle failure response codes
                    upload.responseJSON { response in

                        self.handleResponse(response)

                    }
                case .Failure(let encodingError):
                    print("encoding error!!")
                    print(encodingError)
                }
            }
        )
    }
    
    // Handles an alamofire response object and calls associated delegate methods
    func handleResponse (response: Response<AnyObject, NSError>) {
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
                self.delegate?.uploadDidComplete(res_json_dictionary)
            
            // 400 status code. message prop should exist
            } else if response_code >= 300 && response_code < 500 {
                
                let message = res_json_dictionary.objectForKey("message") as! String
                self.delegate?.uploadDidFail(APIError.HTTPError(message: message))

            // Server error
            } else if response_code >= 500 {
                self.delegate?.uploadDidFail(APIError.ServerError(message: "A server error occurred."))
            }

            
        case .Failure(let error):
            self.delegate?.uploadDidFail(error)
        }
    }
}