//
//  File.swift
//  Duck
//
//  Created by Charlie Blevins on 2/12/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation

struct Credentials {
    let email: String
    let password: String
    
    init (email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    init(fromCoreData data: AnyObject) {
        self.email = data.valueForKey("email") as! String
        self.password = data.valueForKey("password") as! String
    }
}