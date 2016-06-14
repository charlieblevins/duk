//
//  MapViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 9/20/15.
//  Copyright (c) 2015 Charlie Blevins. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData
import GoogleMaps

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, ApiRequestDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    // Label displayed to user to give status updates
    // as app downloads or performs other tasks
    @IBOutlet weak var StatusLabel: UILabel!

    var locationManager: CLLocationManager!
    
    // Flags used by location update to determine next action
    var tryingToAddMarker: Bool = false
    var tryingToShowMyLocation: Bool = false
    
    // Flag used by location observer to animate to location
    var didFindMyLocation: Bool = false
    
    // Handler to execute when map comes to rest
    // Allows executing other tasks after map reaches new region
    var mapAtRestHandler:(()->Void)!
    
    // Array of all markers in view
    var markersInView: [AnyObject] = []
    
    var deletedMarkers: [Double] = []
    var curMapMarkers: [DukGMSMarker] = []
    
    
    // Store a marker from the addMarker view to be 
    // loaded when completing add marker task and viewing
    // newly created marker
    var markerToAdd: [AnyObject] = []
    
    var mapIsAtRest: Bool = false
    var mapTilesFinishedRendering: Bool = false
    
    // Current infowindow
    var curInfoWindow: InfoWindowView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide status initially
        StatusLabel.hidden = true

        // Initialize and show google map
        showGMap()
        
        // Add buttons
        showAddMarkerButton()
        showMyMarkersButton()
        showMyLocationBtn()
        
        // Enable user's location
        showMyLocation(false)

        
        // Observe changes to my location
        mapView!.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        
        // Closure to execute when map comes to rest at it's final
        // location
        mapAtRestHandler = {
            self.StatusLabel.text = "Loading local markers"
            self.addMarkersInView()
        }
    }
    
    // Hide nav bar for this view, but show for others
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        
        // Remove deleted from map
        if (deletedMarkers.count > 0) {
            removeDeleted()
        }
        
        // Add new markers to map
        if (markerToAdd.count > 0) {
            let timestamp = markerToAdd[2] as! Double
            let timestampString = String(format: "%.7f", timestamp)
            
            let lat = markerToAdd[0] as! Double
            let lng = markerToAdd[1] as! Double
            
            // Add marker
            self.addMarker(lat, markerLng: lng, timestamp: timestampString, pinImage: nil)
            
            // Center on marker
            if mapView != nil {
                mapView!.animateToLocation(CLLocationCoordinate2DMake(lat, lng))
                self.mapIsAtRest = false
            }
            
            // Clear the array
            markerToAdd = []
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    func showGMap () {
        
        // Initialize map object
        //mapContainer = GMSMapView.mapWithFrame(CGRectZero, camera: camera)

        // Set this map object as the MapView
        //mapContainer = mapView
        
        // Set map delegate as this view controller class
        mapView!.delegate = self
    }
    
    // Animate to current location on first update
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            
            // animate to location
            animateToCurLocation()
            
            didFindMyLocation = true
        }
    }
    
    func animateToCurLocation () {
        if let loc = mapView?.myLocation {
            mapView!.animateToCameraPosition(GMSCameraPosition.cameraWithTarget(loc.coordinate, zoom: 10))
            self.mapIsAtRest = false
        }
    }
    
    // map reaches idle state
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        print("map is idle")
        self.mapIsAtRest = true;
        if self.mapTilesFinishedRendering {
            self.mapAtRest()
        }
    }
    
    func mapViewDidStartTileRendering(mapView: GMSMapView) {
        self.mapTilesFinishedRendering = false
    }
    
    func mapViewDidFinishTileRendering(mapView: GMSMapView) {
        self.mapTilesFinishedRendering = true
        if self.mapIsAtRest {
            self.mapAtRest()
        }
    }
    
    // Called each time map:
    // 1. Finishes animating AND
    // 2. Finishes rendering tiles
    func mapAtRest () {
        if self.mapAtRestHandler != nil {
            self.mapAtRestHandler();
            self.mapAtRestHandler = nil
        }
    }
    
    // Add markers in current map view
    func addMarkersInView () {
        
        // 1. Get map bounds as bottom left and upper-right coords (nearLeft and farRight)
        let vis_region = self.mapView!.projection.visibleRegion()
        
        //    Convert to GMSCoordinateBounds
        let bounds = GMSCoordinateBounds(region: vis_region)
        
        
        // 2. Get local markers within bounds
        self.showCoreMarkersWithin(bounds)
        
        // 3. Get public markers within bounds
        let req = ApiRequest()
        req.delegate = self
        req.getMarkersWithinBounds(bounds)
        
        self.StatusLabel.text = "Loading public markers"
    }
    
    func showCoreMarkersWithin (bounds: GMSCoordinateBounds) {
        
        // Show user's saved markers if they exist
        let markers_from_core = Util.fetchCoreData("Marker", predicate: nil)
        
        if markers_from_core.count == 0 {
            return
        }
        
        // Find and return markers within provided bounds
        for marker_data in markers_from_core {

            let marker = Marker(fromCoreData: marker_data)
            
            // Get marker coords
            let coords = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
            
            if bounds.containsCoordinate(coords) {
                
                // Get map marker and store
                if let map_marker = marker.getMapMarker() {
                    map_marker.map = self.mapView
                    
                    // Save reference to active markers
                    curMapMarkers.append(map_marker)
                } else {
                    print("marker from core had no timestamp: \(marker)")
                }
            }
        }
    }
    
    // Add marker to map
    func addMarker (markerLat: CLLocationDegrees, markerLng: CLLocationDegrees, timestamp: String?, pinImage: UIImage?) {
        
        let marker = DukGMSMarker()
        marker.position = CLLocationCoordinate2DMake(markerLat, markerLng)
        
        // Store timestamp as title for id
        if timestamp != nil {
            marker.title = timestamp
        } else {
            marker.title = "Hello world!"
        }
        
        marker.snippet = "Test snippet"
        
        if pinImage != nil {
            marker.icon = pinImage
        }
        
        // Add marker to the map
        marker.map = mapView
        
        // Store all map markers
        curMapMarkers.append(marker)
    }
    
    // Info Window Pop Up
    func mapView(mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        print("marker is about to show")
        
        // Allow view to update dynamically (only in v 1.13 which is broken!
        marker.tracksInfoWindowChanges = true
        
        // Get info window view
        let customInfoWindow = NSBundle.mainBundle().loadNibNamed("InfoWindow", owner: self, options: nil)[0] as! InfoWindowView
        
        let custom_marker = marker as! DukGMSMarker
        
        // Set tags (stored in map marker obj)
        customInfoWindow.tags.text = custom_marker.tags!
        
        // Get image for local marker
        if custom_marker.dataLocation == .Local {
            
            // Hide loading
            customInfoWindow.loading.hidden = true
            
            let marker_data = Marker.getLocalByTimestamp(custom_marker.timestamp!)
            
            // Get image
            if marker_data != nil {
                customInfoWindow.image.image = UIImage(data: marker_data!.photo_md!)
            }
        
        // Get image for public marker
        } else {
            
            // Get request for image file
            let req = ApiRequest()
            req.delegate = self
            req.getMarkerImage("\(custom_marker.public_id!)_md.jpg")
            
            // Store reference for use when image download completes
            curInfoWindow = customInfoWindow
        }

        return customInfoWindow
    }
    
    // Show Add Marker button
    func showAddMarkerButton() {
        let button = DukBtn()
        
        // Build button
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.layer.masksToBounds = true
        button.backgroundColor = .whiteColor()

        button.setTitle("Add Marker", forState: .Normal)
        button.titleLabel!.lineBreakMode = .ByWordWrapping;
        button.titleLabel!.textAlignment = .Center
        
        button.setTitleColor(UIColor(red: 56, green: 150, blue: 57), forState: .Normal)
        
        // Dimensions
        let widthConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1,
            constant: 80)

        
        let heightConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1,
            constant: 80)
        
        
        // Make Circle
        button.layer.cornerRadius = 40
        
        // Position
        let horizontalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .CenterX,
            relatedBy: .Equal,
            toItem: view,
            attribute: .CenterX,
            multiplier: 1,
            constant: 0)
        
        let verticalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Bottom,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Bottom,
            multiplier: 1,
            constant: -15)
        
        // Set action
        button.addTarget(self, action: #selector(MapViewController.addMarker(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        // Add button to view
        self.view.addSubview(button)
        
        // Shadow
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 4
        
        // Undo default clipping mask to make shadow visible
        button.layer.masksToBounds = false
        
        // Activate constraints
        heightConstraint.active = true
        widthConstraint.active = true
        horizontalConstraint.active = true
        verticalConstraint.active = true
    }
 
    // Moves user to add marker view
    func addMarker(sender:UIButton!) {
        
        // Location services must be on to continue
        if CLLocationManager.locationServicesEnabled() == false {
            showLocationAcessDeniedAlert(nil)
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
            
        case .AuthorizedWhenInUse:
            fallthrough
        case .AuthorizedAlways:
            goToAddMarkerView()
            
        case .NotDetermined:
            tryingToAddMarker = true
            reqUserLocation()
            return
        
        case .Denied:
            fallthrough
        case .Restricted:
            showLocationAcessDeniedAlert(nil)
        }
    }
    
    func showMyMarkersButton () {
        let button = DukBtn()
        
        // Build button
        button.frame = CGRectMake(100, 100, 100, 50)
        
        button.backgroundColor = UIColor.blueColor()
        button.setTitle("My Markers", forState: UIControlState.Normal)
        
        // Position
        button.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Left,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Left,
            multiplier: 1,
            constant: 0)
        
        let verticalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Top,
            multiplier: 1,
            constant: 20)
        
        // Set action
        button.addTarget(self, action: #selector(MapViewController.goToMyMarkers(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        // Add button to view
        self.view.addSubview(button)
        
        // Activate constraints
        horizontalConstraint.active = true
        verticalConstraint.active = true
    }
    
    func goToMyMarkers (sender: UIButton) {
        let MyMarkersController = self.storyboard!.instantiateViewControllerWithIdentifier("MyMarkersController")
        self.navigationController?.pushViewController(MyMarkersController, animated: true)
    }
    
    // Show the my location (cross-hair) button
    func showMyLocationBtn () {
        let button = DukBtn()
        
        // Build button
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.layer.masksToBounds = true
        button.backgroundColor = .whiteColor()
        
        // Add crosshair image
        guard let image = UIImage(named: "crosshair") else {
            return
        }
        button.setImage(image, forState: .Normal)
        
        
        // Dimensions
        let widthConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1,
            constant: 60)
        
        
        let heightConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1,
            constant: 60)
        
        
        // Make Circle
        button.layer.cornerRadius = 30
        
        // Position
        let horizontalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Trailing,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Trailing,
            multiplier: 1,
            constant: -15)
        
        let verticalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .Bottom,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Bottom,
            multiplier: 1,
            constant: -15)
        
        // Set action
        button.addTarget(self, action: #selector(myLocationBtnTapped), forControlEvents: UIControlEvents.TouchUpInside)
        
        // Add button to view
        self.view.addSubview(button)
        
        // Shadow
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 4
        
        // Undo default clipping mask to make shadow visible
        button.layer.masksToBounds = false
        
        // Activate constraints
        heightConstraint.active = true
        widthConstraint.active = true
        horizontalConstraint.active = true
        verticalConstraint.active = true
    }
    
    // Show users location OR alert
    // the user about a permissions problem
    func myLocationBtnTapped () {
        showMyLocation(true)
    }
    
    // Check location permissions and either
    // - show and animate to the user's current location
    // - request the user's permission to access location
    // - show an alert that tells user how to allow location permission
    func showMyLocation (alertFailure: Bool) {
        
        // Update user
        StatusLabel.text = "Moving map to your location"
        StatusLabel.hidden = false
        
        // Location services must be on to continue
        if CLLocationManager.locationServicesEnabled() == false && alertFailure {
            showLocationAcessDeniedAlert("Location services are disabled. Location services are required to access your location.")
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
            
        case .AuthorizedWhenInUse:
            fallthrough
        case .AuthorizedAlways:
            
            // Enable user location on Google Map and allow
            // observer to show location on first update
            if mapView!.myLocationEnabled != true {
                didFindMyLocation = false
                mapView!.myLocationEnabled = true
                
            // Location is already enabled: zoom to location
            } else if mapView!.myLocation != nil {
                animateToCurLocation()
            }
        case .NotDetermined:
            
            // Set flag for permission change handler
            tryingToShowMyLocation = true
            
            reqUserLocation()
            return
            
        case .Denied:
            fallthrough
        case .Restricted:
            if alertFailure {
                showLocationAcessDeniedAlert(nil)
            }
        }
    }
    
    func goToAddMarkerView () {
        let AddMarkerViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AddMarkerController")
        self.navigationController?.pushViewController(AddMarkerViewController, animated: true)
    }
    
    // Request user location by initializing CLLocationManager
    // This will promp the user to give the app location permission
    // if not already allowed.
    func reqUserLocation () {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        mapView!.myLocationEnabled = true
    }
    
    // Callback for user location permissions
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
            
            // Check flags to determine next action
            if tryingToAddMarker == true {
                tryingToAddMarker = false
                goToAddMarkerView()
                
            } else if tryingToShowMyLocation == true {
                
                // Unset flag
                tryingToShowMyLocation = false
                
                showMyLocation(true)
            }
        }
    }
    
    // Help user adjust settings if accidentally denied
    func showLocationAcessDeniedAlert(message: String?) {
        var final_message: String?
        
        if message == nil {
            final_message = "This action requires your location. Please allow access to location services in Settings."
        } else {
            final_message = message
        }
        
        let alertController = UIAlertController(title: "Location Services",
                                                message: final_message,
                                                preferredStyle: .Alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (alertAction) in
            
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (alertAction) in
            
            // If mapAtRest handler exists, execute it
            // and remove
            self.mapAtRest()
        })
        
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    func removeDeleted() {
        
        // Loop through deleted items
        for timestamp in deletedMarkers {
            
            // Get marker by timestamp
            if let marker_ind = curMapMarkers.indexOf({ $0.timestamp == timestamp }) {
                
                // Remove from map
                curMapMarkers[marker_ind].map = nil
                
                curMapMarkers.removeAtIndex(marker_ind)
            }
        }
        
        // Clear deleted markers
        //deletedMarkers = []
    }
    
    // ApiRequestDelegate methods
    func reqDidComplete(data: NSDictionary, method: ApiMethod) {
        var pubMarkersById: [String: AnyObject] = [:]
        
        if data["data"] == nil {
            return Void()
        }
        
        // Loop over received marker data
        let marker_array = data["data"] as! [AnyObject]
        for marker_data in marker_array {
            
            // Convert data to DukGMSMarker
            let marker = Marker(fromPublicData: marker_data as! [String: AnyObject])
            
            // Store map marker by public id
            if let map_marker = marker!.getMapMarker() {
                pubMarkersById[map_marker.public_id!] = map_marker
                
            } else {
                print("could not get map marker from marker data: \(marker)")
            }
        }
        
        // Remove duplicates
        let local_public = Marker.getLocalPublicIds()
        
        // Remove markers with a matching public id
        for public_id in local_public {
            pubMarkersById.removeValueForKey(public_id)
        }
        
        // Make array from remaining values
        let cleaned_public_markers = Array(pubMarkersById.values) as! [DukGMSMarker]
        
        // Set marker's map property to show in view
        for marker in cleaned_public_markers {
            
            marker.map = self.mapView
            
            // Save reference to active markers
            curMapMarkers.append(marker)
        }
        
        self.StatusLabel.hidden = true
    }
    
    func imageDownloadDidProgress (progress: Float) {
        let percentage = Int(progress * 100)
        curInfoWindow!.loading.text = "Loading: \(percentage)%"
    }
    
    func reqDidComplete(withImage image: UIImage) {
        
        // Hide loading
        curInfoWindow!.loading.hidden = true
        
        curInfoWindow!.image.image = image
    }
    
    func reqDidFail(error: String, method: ApiMethod) {
        self.StatusLabel.hidden = true
        
        if method == .Image {
            curInfoWindow!.loading.text = "Image failed to load"
        }
        
        print(error)
    }
    
    
}

// Extend GMSMarker to have
// public/local data reference
// and an id/timestamp for data lookup
class DukGMSMarker: GMSMarker {
    
    // Indicate where marker data is stored
    var dataLocation: DataLocation? = nil
    
    // One of these will contain a reference
    // used for looking up info window data
    var timestamp: Double? = nil
    var public_id: String? = nil
    
    // Store tags for info window
    var tags: String? = nil
    
    // Get medium image for this marker
//    func getMedImage () -> UIImage {
//        
//    }
}

enum DataLocation {
    case Local, Public
}

// Custom button class used for 
// addMarker button and my markers button
class DukBtn: UIButton {
    
    var orig_bg: UIColor? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        // Change BG on down press
        self.addTarget(self, action: #selector(self.pressDown), forControlEvents: .TouchDown)
        
        // Reset bg on release
        self.addTarget(self, action: #selector(self.resetBg), forControlEvents: .TouchUpInside)
    }
    
    func pressDown () {
        print("btn pressed down!")
        
        // Store orig bg for reset
        self.orig_bg = self.backgroundColor
        
        // Set new bg
        self.backgroundColor = UIColor(red: 222, green: 222, blue: 222)
    }
    
    func resetBg () {
        
        if (self.orig_bg != nil) {
            self.backgroundColor = self.orig_bg
        }
    }
}

