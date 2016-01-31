//
//  ApiModel.swift
//  Duck
//
//  Created by Charlie Blevins on 1/30/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import Gloss

struct ApiMessage: Decodable {
    
    let message: String?
    
    // MARK: Deserialization
    
    init?(json: JSON) {
        self.message = "message" <~~ json
    }
}