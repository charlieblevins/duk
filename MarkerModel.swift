//
//  MarkerModel.swift
//  Duck
//
//  Created by Charlie Blevins on 2/12/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import CoreData
import GoogleMaps

struct Marker {
    var latitude, longitude: Double?
    var timestamp: Double?
    var photo: Data?
    var photo_md: Data?
    var photo_sm: Data?
    var tags: String?
    
    var public_id: String?
    var user: String?
    
    var editable: Bool
    
    var distance_from_me: Double?
    
    var approved: Int?
    
    init() {
        self.latitude = nil
        self.longitude = nil
        
        let timestamp = Date().timeIntervalSince1970
        self.timestamp = timestamp
        
        self.photo = nil
        self.photo_md = nil
        self.photo_sm = nil
        self.tags = nil
        
        self.editable = false
        self.distance_from_me = nil
    }
    
    init(fromCoreData data: AnyObject) {
        self.latitude = data.value(forKey: "latitude") as? Double
        self.longitude = data.value(forKey: "longitude") as? Double
        self.timestamp = data.value(forKey: "timestamp") as? Double
        
        self.photo = data.value(forKey: "photo") as? Data
        self.photo_md = data.value(forKey: "photo_md") as? Data
        self.photo_sm = data.value(forKey: "photo_sm") as? Data
        self.tags = data.value(forKey: "tags") as? String
        
        // If from core data, this marker is editable
        self.editable = true
        
        // Store public id if available
        if let pid = data.value(forKey: "public_id") as? String {
            self.public_id = pid
        }
        
        self.distance_from_me = nil
    }
    
    // Initialize from public (server) data
    init?(fromPublicData data: NSDictionary) {
        
        self.editable = false

        
        let geometry = data.value(forKey: "geometry")
        if geometry == nil {
            print("no geometry provided")
            return nil
        }
        
        let coords = (geometry! as AnyObject).value(forKey: "coordinates")
        if coords == nil {
            print("no coords provided to marker init")
            return nil
        }
        
        let coords_array = (coords as! NSArray) as Array
        
        if coords_array.count != 2 {
            print("coords array missing data")
            return nil
        }
        
        self.latitude = coords_array[1] as? Double
        self.longitude = coords_array[0] as? Double
        
        // if server returns distance
        if let distance = data.value(forKey: "distance") {
            self.distance_from_me = distance as? Double
        }
        
        // public markers don't have a timestamp
        self.timestamp = nil
        
        self.photo = nil
        self.photo_md = nil
        self.photo_sm = nil
        
        if let photoJson = data.value(forKey: "photo") {
            let b64_photo = (photoJson as AnyObject).value(forKey: "data") as? String
            self.photo = Data(base64Encoded: b64_photo!, options: [])
        }

        if let nouns_arr = data.value(forKey: "tags") as? Array<String> {
            self.tags = nouns_arr.joined(separator: " ")
        }
        
        self.public_id = data.value(forKey: "_id") as? String
        self.approved = data.value(forKey: "approved") as? Int
        
        // Get username
        self.user = data.value(forKey: "username") as? String
        
        // Determine if this user can edit
        self.editable = self.canEdit()
    }

    
    // Save this marker's data in core data as 
    // a new entity (insert)
    mutating func saveInCore() -> Bool {
        
        // 1. Get managed object context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // 2. Create new object as marker entity
        let entity = NSEntityDescription.entity(forEntityName: "Marker", in:managedContext)
        let marker_data = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        // 3. Add data to marker object (and validate)
        marker_data.setValue(timestamp, forKey: "timestamp")
        
        marker_data.setValue(latitude, forKey:"latitude")
        
        marker_data.setValue(longitude, forKey:"longitude")
        
        // Create space separated string of tags
        marker_data.setValue(tags, forKey: "tags")
        
        // Save image as binary
        marker_data.setValue(photo, forKey: "photo")
        
        // Make small and medium image versions
        marker_data.setValue(photo_sm, forKey: "photo_sm")
        marker_data.setValue(photo_md, forKey: "photo_md")
        
        // 4. Save the marker object
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
            return false
        }
        
        return true
    }
    
    // Update existing marker in core
    func updateInCore<valType>(_ key: String, value: valType) -> Bool {
        
        /// Update core data
        // Get managed object context
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        // Construct fetch request with predicate
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Marker")
        
        guard self.timestamp != nil else {
            print("cannot update marker with no timestamp")
            return false
        }
        
        fetchRequest.predicate = NSPredicate(format: "timestamp = %lf", self.timestamp!)
        
        // Execute fetch
        do {
            let fetchResults = try appDel.managedObjectContext.fetch(fetchRequest) as? [NSManagedObject]
            
            // Insert new public id
            if  fetchResults != nil && fetchResults!.count > 0 {
                let managedObject = fetchResults![0]
                managedObject.setValue(value, forKey: key)
                
            } else {
                print("cannot update. marker does not exist")
                return false
            }
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            return false
        }
        
        // Save
        do {
            try context.save()
        } catch let error as NSError {
            print("marker save failed: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    func getMapMarker () -> DukGMSMarker? {
        return _getMapMarker(nil)
    }
    
    func getMapMarker (iconOverride icon: String?) -> DukGMSMarker? {
        return _getMapMarker(icon)
    }
    
    // Get an object that can be directly displayed on the google map
    fileprivate func _getMapMarker (_ iconOverride: String?) -> DukGMSMarker? {
        let map_marker = DukGMSMarker()
        
        // Set icon
        let icon_name = (iconOverride != nil) ? iconOverride : self.tags!
        
        let iconImgView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
        MarkerIconView.loadIconImage(Marker.getPrimaryNoun(icon_name!), imageView: iconImgView, complete: {
            map_marker.iconView = iconImgView
        })
        //Util.loadMarkerIcon(map_marker, noun_tags: icon_name!)
        
        // Set position
        map_marker.position = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        
        // No timestamp or public id
        if timestamp == nil && public_id == nil {
            return nil
        }
        
        // If timestamp assume local
        if timestamp != nil {
            map_marker.dataLocation = .local
            map_marker.timestamp = timestamp
        } else {
            map_marker.dataLocation = .public
        }
        
        // Add public id if present
        if public_id != nil {
            map_marker.public_id = public_id
        }
        
        // Add tags for info window display
        map_marker.tags = self.tags
        
        return map_marker
    }
    
    mutating func canEdit () -> Bool {
        
        let cred = Credentials()
        
        // Access login data
        if cred == nil {
            
            // No login data
            return false
            
        }
        
        // Compare with this markers username
        if cred!.email == self.user {
            return true
        } else {
            return false
        }
    }
    
    // Update image data
    mutating func updateImage (_ image: UIImage) {
        
        // Save image as binary
        self.photo = UIImageJPEGRepresentation(image, 1)

        // Make small and medium image versions
        self.photo_sm = UIImageJPEGRepresentation(Util.resizeImage(image, scaledToFillSize: CGSize(width: 80, height: 80)), 1)
        self.photo_md = UIImageJPEGRepresentation(Util.resizeImage(image, scaledToFillSize: CGSize(width: 240, height: 240)), 1)
    }
    
    // Load photo for this marker
    mutating func loadPropFromCore (prop: String, propLoaded: (Any?) -> Void) {
        
        guard self.timestamp != nil else {
            print("can't lookup photo. Marker has no timestamp")
            propLoaded(nil)
            return
        }
        
        // Context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // Fetch request
        let fetchReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchReq.entity = NSEntityDescription.entity(forEntityName: "Marker", in: managedContext)
        fetchReq.predicate = NSPredicate(format: "timestamp == %lf", self.timestamp!)
        
        fetchReq.resultType = .dictionaryResultType
        fetchReq.propertiesToFetch = [prop]
        
        
        do {
            let markers = try managedContext.fetch(fetchReq)
            
            let single = markers[0] as! NSDictionary
            let data = single[prop]
            
            propLoaded(data)
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
    
    // Get coordinates for display (ex "-32.12345678, 23.12345678")
    func getCoords () -> String? {
        
        guard self.longitude != nil && self.latitude != nil else {
            print("Marker does not have coordinates")
            return nil
        }
        
        let lat = Marker.formatSingleCoord(self.latitude!)
        let lng = Marker.formatSingleCoord(self.longitude!)
        
        return "\(lat), \(lng)"
    }
    
    // Format a single coordinate to 8 decimal places
    static func formatSingleCoord (_ coord: Double) -> String {
        return String(format: "%.8f", coord)
    }
    
    // Find and return marker with provided timestamp
    static func getLocalByTimestamp (_ timestamp: Double) -> Marker? {
        
        let pred = NSPredicate(format: "timestamp == %lf", timestamp)
        let markers_from_core = Util.fetchCoreData("Marker", predicate: pred)
        
        if markers_from_core?.count == 0 {
            return nil
        } else {
            return Marker(fromCoreData: (markers_from_core?[0])!)
        }
    }
    
    // Get an array of local markers that have been published (made public)
    static func getLocalPublicIds () -> [String] {
        var public_ids: [String] = []
        
        let markers_from_core = Util.fetchCoreData("Marker", predicate: nil)
        
        if markers_from_core?.count == 0 {
            return public_ids
        }
        
        for marker_data in markers_from_core! {
            
            let marker = Marker(fromCoreData: marker_data)
            
            if marker.public_id != nil {
                public_ids.append(marker.public_id!)
            }
        }
        
        // Nothing found
        return public_ids
    }
    
    
    // Fetch fields for entity
    static func allMarkersWithFields (_ fields: Array<String>) -> [Marker] {
        var found = [Marker]()
        
        // Context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // Fetch request
        let fetchReq: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchReq.entity = NSEntityDescription.entity(forEntityName: "Marker", in: managedContext)
        
        fetchReq.resultType = .dictionaryResultType
        fetchReq.propertiesToFetch = fields
        
        do {
            let markers = try managedContext.fetch(fetchReq)
            for marker in markers {
                found.append(Marker(fromCoreData: marker as AnyObject))
            }
            
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        return found
    }

    // Format noun(s) in attributed style. Primary noun should be bold.
    static func formatNouns (_ nouns: String) -> NSMutableAttributedString {
        
        var primaryNoun: String? = nil
        
        // Create bold style attr
        let dynamic_size = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).pointSize
        let bold_attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: dynamic_size)]
        var attributedString = NSMutableAttributedString(string: "")
        
        // More than one noun - bold the first
        if let space_range = nouns.range(of: " ") {
            
            primaryNoun = nouns.substring(to: (space_range.lowerBound))
            
            attributedString = NSMutableAttributedString(string: "#\(primaryNoun!)", attributes: bold_attrs)
            
            // Make attr string from remaining string
            let remaining_nouns = nouns.substring(from: (space_range.upperBound))
            
            // split by spaces and add command #
            let remaining_formatted = remaining_nouns.components(separatedBy: " ").map {
                item in
                return ", #\(item)"
            }.joined()
            
            // convert to attributed
            let remaining_attributed = NSMutableAttributedString(string: remaining_formatted)
            
            // Concat first noun with remaining nouns
            attributedString.append(remaining_attributed)
            
            // No space - assume single tag
        } else {
            attributedString = NSMutableAttributedString(string: "#\(nouns)", attributes: bold_attrs)
        }
        
        return attributedString
    }
    
    static func getPrimaryNoun (_ nouns: String) -> String {
        
        // if more than one noun
        if let space_range = nouns.range(of: " ") {
            return nouns.substring(to: (space_range.lowerBound))
            
        } else {
            return nouns
        }
    }
}
