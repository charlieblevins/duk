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

class ApiRequest {
    
    let baseURL: String = "http://dukapp.io/api"
    
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
                multipartFormData.appendBodyPart(data: "\(marker.latitude)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "latitude")
                multipartFormData.appendBodyPart(data: "\(marker.longitude)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "longitude")
                multipartFormData.appendBodyPart(data: "\(marker.tags)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "tags")
                multipartFormData.appendBodyPart(data: marker.photo, name: "photo", fileName: "TestFile", mimeType: "image/jpeg")
            },
            encodingCompletion: { encodingResult in
                
                switch encodingResult {
                    
                case .Success(let upload, _, _):
                    
                    print("upload SUCCESS")
                    upload.responseJSON { response in
                        let data_str = NSString(data: response.data!, encoding: NSUTF8StringEncoding)
                        print(data_str)
                        let json = JSON(data_str!)
                        print(json)
                    }
                case .Failure(let encodingError):
                    print("upload FAIL")
                    print(encodingError)
                }
            }
        )
    }
}