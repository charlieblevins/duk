//
//  IconModel.swift
//  Duck
//
//  Created by Charlie Blevins on 10/30/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import Foundation

public class IconModel {
    
    public class Icon {
        var tag: String
        var fullName: String
        var imageName: String
        
        init(tag: String, fullName: String, imageName: String) {
            self.tag = tag
            self.fullName = fullName
            self.imageName = imageName
        }
    }
    
    public var icons: [Icon] = [
        Icon(tag: "hazard", fullName: "Hazard", imageName: "hazardMarker"),
        Icon(tag: "photo", fullName: "Photo", imageName: "Photo"),
        Icon(tag: "parking", fullName: "Parking", imageName: "parking")
    ]
    
    init() {
        print(self.icons)
    }
    
}