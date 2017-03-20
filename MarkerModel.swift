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

class Marker: NSObject, ApiRequestDelegate {
    
    enum Approval: Int {
        case approved = 1
        case pending = 0
        case denied = -1
    }
    
    var latitude, longitude: Double?
    var timestamp: Double?
    var photo: Data?
    var photo_md: Data?
    var photo_sm: Data?
    var tags: String?
    
    var public_id: String?
    var user_id: String?
    
    var distance_from_me: Double?
    
    var approved: Approval?
    
    var isOwned: Bool {
        get {
            
            // If no public id, marker must have been created
            // on this device, thus it is owned.
            guard self.public_id != nil else {
                return true
            }
                
            guard let cred = Credentials() else {
                
                // No login data
                return false
            }
            
            // Compare with this markers user id
            if cred.id == self.user_id {
                return true
            } else {
                return false
            }
        }
    }
    
    var isFavorite: Bool {
        get {
            guard let pid = self.public_id else {
                return false
            }
            
            let favorites = Favorite.getAll()
            
            if favorites.index(of: pid) != NSNotFound {
                return true
            } else {
                return false
            }
        }
    }
    
    private var editMarkerCompletion: ((_ success: Bool, _ message: String?)->Void)? = nil
    
    var created: NSDate
    
    lazy var createdString: String = {
        return Marker.formatDate(nsdate: self.created)
    }()
    
    var coordinate: CLLocationCoordinate2D? {
        get {
        
            guard let lat = self.latitude else {
                print("Marker has no latitude. Cannot make coordinate")
                return nil
            }
            
            guard let lng = self.longitude else {
                print("Marker has no longitude. Cannot make coordinate")
                return nil
            }
            
            return CLLocationCoordinate2DMake(lat, lng)
        }
    }
    
    var dataLocation: DataLocation? {
        get {
            if self.timestamp != nil {
                return .local
            } else if self.public_id != nil {
                return .public
            } else {
                return nil
            }
        }
    }
    
    static let requiredFields = ["tags", "latitude", "longitude", "timestamp", "public_id", "created", "approved", "user_id"]
    
    override init() {
        self.latitude = nil
        self.longitude = nil
        
        self.timestamp = Marker.generateTimestamp()
        self.created = NSDate()
        
        self.photo = nil
        self.photo_md = nil
        self.photo_sm = nil
        self.tags = nil
        
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
        
        // Store public id if available
        if let pid = data.value(forKey: "public_id") as? String {
            self.public_id = pid
            
            // Set approved if public_id and an approved value is stored
            if let appr = data.value(forKey: "approved") as? Int {
                self.approved = Approval(rawValue: appr)
            }
            
            self.user_id = data.value(forKey: "user_id") as? String
        }
        
        self.created = data.value(forKey: "created") as! NSDate
        
        self.distance_from_me = nil
    }
    
    // Initialize from public (server) data
    init?(fromPublicData data: NSDictionary) {
        
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
        
        // PHOTOS
        if let photo_data = data.value(forKey: "photos") as? Dictionary<String, String> {
            
            if let sm = photo_data["sm"] {
                self.photo_sm = Data(base64Encoded: sm)
            }
            
            if let md = photo_data["md"] {
                self.photo_md = Data(base64Encoded: md)
            }
            
            if let full = photo_data["full"] {
                self.photo = Data(base64Encoded: full)
            }
            
        } else {
            self.photo = nil
            self.photo_md = nil
            self.photo_sm = nil
        }
        
        // Tags/Nouns
        if let nouns_arr = data.value(forKey: "tags") as? Array<String> {
            self.tags = nouns_arr.joined(separator: " ")
        }
        
        self.public_id = data.value(forKey: "_id") as? String
        
        // Approval
        if let appr_int = data.value(forKey: "approved") as? Int {
        
            self.approved = Approval(rawValue: appr_int)
        }
        
        // Get username
        self.user_id = data.value(forKey: "user_id") as? String
        
        // Convert date from json format to NSDate
        if let raw = data.value(forKey: "createdDate") as? String, let date = Marker.formatDate(string: raw) {
            self.created = date
            
        } else {
            print("Init failure: Could not parse created date")
            return nil
        }
    }
    
    // Make a copy of another marker
    init?(copy marker: Marker) {
        self.latitude = marker.latitude
        self.longitude = marker.longitude
        
        self.timestamp = marker.timestamp
        self.public_id = marker.public_id
        
        self.photo = marker.photo
        self.photo_md = marker.photo_md
        self.photo_sm = marker.photo_sm
        self.tags = marker.tags
        
        self.distance_from_me = marker.distance_from_me
        self.user_id = marker.user_id
        self.approved = marker.approved
        self.created = marker.created
    }

    
    // Save this marker's data in core data as 
    // a new entity (insert)
    @discardableResult func saveInCore() -> Bool {
        
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
        
        // approved
        marker_data.setValue(approved?.rawValue, forKey: "approved")
        
        marker_data.setValue(public_id, forKey: "public_id")
        
        marker_data.setValue(user_id, forKey: "user_id")
        
        marker_data.setValue(created, forKey: "created")
        
        // 4. Save the marker object
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
            return false
        }
        
        // If we're saving a marker that already exists on the server, dispatch an update
        if self.isPublic() {
            let copy = Marker(copy: self)
            copy?.timestamp = nil
            self.notifyUpdate(.update, oldMarker: copy)
        } else {
            self.notifyUpdate(.create)
        }
        
        return true
    }
    
    // Update existing marker in core
    func updateInCore(_ props: [String]) -> Bool {
        
        /// Update core data
        // Get managed object context
        let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        // Construct fetch request with predicate
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Marker")
        
        guard let ts = self.timestamp else {
            print("cannot update marker with no timestamp")
            return false
        }
        
        fetchRequest.predicate = NSPredicate(format: "timestamp = %lf", ts)
        
        // Execute fetch
        var new: Marker?
        do {
            let fetchResults = try appDel.managedObjectContext.fetch(fetchRequest) as? [NSManagedObject]
            
            // Insert new public id
            if  fetchResults != nil && fetchResults!.count > 0 {
                let managedObject = fetchResults![0]
                
                for prop in props {
                    
                    guard let val = self.value(forKeyPath: prop) else {
                        print("Marker has no value for prop: \(prop)")
                        break
                    }
                    managedObject.setValue(val, forKey: prop)
                }
                
                new = Marker(fromCoreData: managedObject)
                
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
        
        if new != nil {
            new?.notifyUpdate(.update, oldMarker: self)
        }
        
        return true
    }
    
    
    // Delete objects with a certain time stamp from core data
    func deleteFromCore () -> Bool {
        
        guard let timestamp = self.timestamp else {
            print("Error: no timestamp. Cannot delete")
            return false
        }
        
        let marker: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        marker.entity = NSEntityDescription.entity(forEntityName: "Marker", in: managedContext)
        marker.includesPropertyValues = false
        
        // Query by timestamp
        let predicate = NSPredicate(format: "timestamp = %lf", timestamp)
        marker.predicate = predicate
        
        var markers: [AnyObject]
        
        do {
            markers = try managedContext.fetch(marker)
            
            for marker in markers {
                managedContext.delete(marker as! NSManagedObject)
            }
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            return false
        }
        
        do {
            try managedContext.save()
        } catch {
            print("save failed")
            return false
        }
        
        // Only local markers create a delete message
        if self.isPublic() {
            
            // Send old and new on update
            let old = Marker(copy: self)
            self.timestamp = nil
            self.notifyUpdate(.update, oldMarker: old)
        } else {
            self.notifyUpdate(.delete)
        }
        
        return true
    }
    
    // Updates marker both publicly and locally
    // Dispatches a single notification
    func updateGlobal (_ credentials: Credentials, props: [String], completion: ((_ success: Bool, _ message: String?)->Void)?) {
       
        guard props.count > 0 && props[0] == "tags" else {
            print("Error: Cannot update marker. Invalid prop update requested. Only 'tags' allowed")
            return
        }
        
        guard let pubid = self.public_id, let _tags = self.tags else {
            print("Error: Cannot update marker. Public id or tags missing")
            
            if completion != nil {
                completion?(false, "An error occurred. Please close the app and try again")
            }
            return
        }
        
        let req = ApiRequest()
        req.delegate = self
        req.editSingleMarker(credentials, public_id: pubid, tags: _tags)
        
        self.editMarkerCompletion = completion
    }
    
    func notifyUpdate (_ editType: MarkerEditType) {
        self.notifyUpdate(editType, oldMarker: nil)
    }
    
    func notifyUpdate (_ editType: MarkerEditType, oldMarker: Marker?) {
        
        // Notify all views of marker update
        let notificationName = Notification.Name("MarkerEditIdentifier")
        let message = MarkerUpdateMessage(self, editType: editType, oldMarker: oldMarker)
        NotificationCenter.default.post(name: notificationName, object: message)
    }
    
    // Get an object that can be directly displayed on the google map
    func getMapMarker (_ iconOverride: String?, completion: @escaping (_ mapMarker: DukGMSMarker?)->Void) {
        
        guard let data_loc = self.dataLocation else {
            print("Error: cannot get map marker - marker has no public or local id")
            completion(nil)
            return
        }
        
        // Try to make a map marker from data in memory
        if let map_marker = self.constructMapMarker(iconOverride) {
            
            // success
            completion(map_marker)
            return
        }
        
        // Data missing - request from public or persistent store
        if data_loc == .public {
            
            let req = MarkerRequest()
            
            guard let pid = self.public_id else {
                completion(nil)
                return
            }
            
            let single = MarkerRequest.LoadByIdParamsSingle(pid, sizes: [.md])
            
            req.loadById([single], completion: { markers in
                
                guard let markers_returned = markers else {
                    print("Error: no markers returned for public_id: \(pid)")
                    completion(nil)
                    return
                }
                
                guard markers_returned.count > 0 else {
                    print("Error: server returned empty array for public_id: \(pid)")
                    completion(nil)
                    return
                }
                
                let marker = markers_returned[0]
                
                guard let map_marker = marker.constructMapMarker(iconOverride) else {
                    print("Error: could not construct map marker from marker data")
                    completion(nil)
                    return
                }
                
                // success
                completion(map_marker)
                
                
            }, failure: {
                completion(nil)
            })
            
        // data_loc == .local
        } else {
            
            guard let t = self.timestamp else {
                completion(nil)
                return
            }
            
            guard let marker = Marker.getMarkerFromCore(t, additionalFields: ["photo_md"]) else {
                print("Error: Cannot get map marker - no marker found with timestamp \(t)")
                completion(nil)
                return
            }
           
            guard let map_marker = marker.constructMapMarker(iconOverride) else {
                print("Error: could not construct map marker from marker data")
                completion(nil)
                return
            }
            
            // success
            completion(map_marker)
        }
    }
    
    func constructMapMarker(_ iconOverride: String?) -> DukGMSMarker? {
        
        guard let coord = self.coordinate else {
            print("Error: Cannot get coordinate from marker")
            return nil
        }
        
        guard let _tags = self.tags else {
            print("Error: Cannot get tags from marker")
            return nil
        }
        
        guard let data_loc: DataLocation = self.dataLocation else {
            print("Error: cannot determine data location")
            return nil
        }
        
        let id: Any = (data_loc == .local) ? self.timestamp as Any : self.public_id as Any
        
        return DukGMSMarker(coord, tags: _tags, dataLocation: data_loc, id: id, iconOverride: iconOverride)
    }

    // Update image data
    func updateImage (_ image: UIImage) {
        
        // Save image as binary
        self.photo = UIImageJPEGRepresentation(image, 1)

        // Make small and medium image versions
        self.photo_sm = UIImageJPEGRepresentation(Util.resizeImage(image, scaledToFillSize: CGSize(width: 80, height: 80)), 1)
        self.photo_md = UIImageJPEGRepresentation(Util.resizeImage(image, scaledToFillSize: CGSize(width: 240, height: 240)), 1)
    }
    
    // Load photo for this marker
    func loadPropFromCore (prop: String, propLoaded: (Any?) -> Void) {
        
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
        
        guard let lng = self.longitude, let lat = self.latitude else {
            print("Marker does not have coordinates")
            return nil
        }
        
        let f_lat = Marker.formatSingleCoord(lat)
        let f_lng = Marker.formatSingleCoord(lng)
        
        return "\(f_lat), \(f_lng)"
    }
    
    // True if marker is published and approved
    func isPublic () -> Bool {
        if self.public_id != nil && self.approved == .approved {
            return true
        }
        
        return false
    }
    
    // True if marker is published (not necessarily approved)
    func isPublished () -> Bool {
        return self.public_id != nil
    }
    
    // MARK: Static Functions
    
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
    
    static func getMarkerFromCore (_ timestamp: Double, additionalFields: [String]) -> Marker? {
        
        let pred = NSPredicate(format: "timestamp = %lf", timestamp)
        
        let finalFields = Marker.requiredFields + additionalFields
        
        let data = Util.fetchCoreData("Marker", predicate: pred, fields: finalFields)
        if data.count > 0 {
            return Marker(fromCoreData: data[0] as AnyObject)
        }
        
        return nil
    }
    
    static func formatDate (string: String) -> NSDate? {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.date(from: string) as NSDate?
        
        return date
    }
    
    static func formatDate (nsdate: NSDate) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        
        return formatter.string(from: nsdate as Date)
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
    
    static func generateTimestamp () -> Double {
        return Date().timeIntervalSince1970
    }
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        if method == .editMarker {
            
            // Use returned tags and approved to ensure exact data match
            // Tags/Nouns
            guard let nouns_arr = data["new_tags"] as? Array<String> else {
                print("Error: cannot complete update. Server did not return tags")
                return
            }
            guard nouns_arr.count > 0 else {
                print("Error: emtpy array returned from server. Tags/Nouns required")
                return
            }
            
            guard let rapproved = data["approved"] as? Int else {
                print("Error: cannot complete update. Server did not return approved")
                return
            }
            
            guard let approval = Approval.init(rawValue: rapproved) else {
                print("Error: cannot complete update. Server returned invalid approval integer")
                return
            }
            
            self.tags = nouns_arr.joined(separator: " ")
            self.approved = approval
            
            if (self.timestamp != nil) {
                if self.updateInCore(["tags", "approved"]) == false {
                    print("update marker in core failed")
                    self.editMarkerCompletion?(false, "An error occurred while saving marker locally.")
                    return
                }
            }
            
            self.notifyUpdate(.update)
            
            self.editMarkerCompletion?(true, "Marker update succeeded")
        }
    }
    
    func reqDidFail(_ error: String, method: ApiMethod, code: Int) {
        if method == .editMarker {
            self.editMarkerCompletion?(false, error)
        }
    }
}


// Define marker update message object
struct MarkerUpdateMessage {
    var marker: Marker
    var oldMarker: Marker?
    var editType: MarkerEditType
    
    init (_ marker: Marker, editType: MarkerEditType, oldMarker: Marker?) {
        self.marker = marker
        self.editType = editType
        
        if editType == .update && oldMarker == nil {
            fatalError("editType of update requires old marker value")
        }
        
        self.oldMarker = oldMarker
    }
}

enum MarkerEditType {
    case create, update, delete
}

enum DataLocation {
    case local, `public`
}
