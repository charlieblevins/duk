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

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    var mapView: GMSMapView?
    var locationManager: CLLocationManager!
    
    // Flags used by location update to determine next action
    var tryingToAddMarker: Bool = false
    var tryingToShowMyLocation: Bool = false
    
    // Flag used by location observer to animate to location
    var didFindMyLocation: Bool = false
    
    var savedMarkers: [AnyObject] = []
    var deletedMarkers: [Double] = []
    var curMapMarkers: [GMSMarker] = []
    var markerToAdd: [AnyObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showGMap()
        
        // Enable user's location
        showMyLocation()
        
        // Observe changes to my location
        mapView!.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        
        addMarkersFromCore()
        
        // Get public markers
        addPublicMarkers()
        
        // Add buttons
        showAddMarkerButton()
        showMyMarkersButton()
        showMyLocationBtn()
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
            
            // Use icon matching first tag
            let tags = markerToAdd[3] as! String
            let pinImage = Util.getIconForTags(tags)
            
            let lat = markerToAdd[0] as! Double
            let lng = markerToAdd[1] as! Double
            
            // Add marker
            self.addMarker(lat, markerLng: lng, timestamp: timestampString, pinImage: pinImage)
            
            // Center on marker
            if mapView != nil {
                mapView!.animateToLocation(CLLocationCoordinate2DMake(lat, lng))
            }
            
            // Clear the array
            markerToAdd = []
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    func showGMap () {
        // Position camera
        let camera = GMSCameraPosition.cameraWithLatitude(42.879070,
            longitude: -97.381173, zoom: 3)
        
        // Initialize map object
        mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        
        // Set map delegate as this view controller class
        mapView!.delegate = self
        
        // Set this view controllers view as the map view object
        self.view = mapView
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
        }
    }
    
    func addMarkersFromCore () {
        
        // Show user's saved markers if they exist
        savedMarkers = Util.fetchCoreData("Marker")
        
        if savedMarkers.count > 0 {
            for marker in savedMarkers {
                
                // Get timestamp
                let timestamp = marker.valueForKey("timestamp") as! Double
                let timestampString = String(format: "%.7f", timestamp)
                
                // Use icon matching first tag
                let tags = marker.valueForKey("tags") as! String
                let pinImage = Util.getIconForTags(tags)
                
                // Add marker
                self.addMarker(marker.latitude, markerLng: marker.longitude, timestamp: timestampString, pinImage: pinImage)
            }
            
            // Set mapview to last marker
            let lastMarker = savedMarkers.last
            mapView!.animateToLocation(CLLocationCoordinate2DMake(lastMarker!.latitude, lastMarker!.longitude))
            mapView!.animateToZoom(12)
        }
    }
    
    // Add marker to map
    func addMarker (markerLat: CLLocationDegrees, markerLng: CLLocationDegrees, timestamp: String?, pinImage: UIImage?) {
        
        let marker = GMSMarker()
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
    func mapView(mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView! {
        print("marker is about to show")
        let customInfoWindow = UIView(frame: CGRectMake(0, 0, 100, 100))
        
        // Get latest core data
        savedMarkers = Util.fetchCoreData("Marker")
        
        // Find marker that matches timestamp
        let timestamp = Double(marker.title)
        
        let matchingMarker = savedMarkers.filter{
            let t = $0.valueForKey("timestamp") as! Double
            return t == timestamp
        }.first
        
        // Add image to custom info window
        let imageView = UIImageView(frame: CGRectMake(0, 0, 100, 100))
        let data: NSData = matchingMarker!.valueForKey("photo") as! NSData
        imageView.image = UIImage(data: data)
        
        customInfoWindow.addSubview(imageView)
        
        customInfoWindow.backgroundColor = UIColor.whiteColor()
        
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
        button.addTarget(self, action: "addMarker:", forControlEvents: UIControlEvents.TouchUpInside)
        
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
            showLocationAcessDeniedAlert()
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
            showLocationAcessDeniedAlert()
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
        button.addTarget(self, action: "goToMyMarkers:", forControlEvents: UIControlEvents.TouchUpInside)
        
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
        button.addTarget(self, action: #selector(MapViewController.showMyLocation), forControlEvents: UIControlEvents.TouchUpInside)
        
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
    
    // Check location permissions and either
    // - show and animate to the user's current location
    // - request the user's permission to access location
    // - show an alert that tells user how to allow location permission
    func showMyLocation () {
        
        // Location services must be on to continue
        if CLLocationManager.locationServicesEnabled() == false {
            showLocationAcessDeniedAlert()
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
            tryingToShowMyLocation = true
            reqUserLocation()
            return
            
        case .Denied:
            fallthrough
        case .Restricted:
            showLocationAcessDeniedAlert()
        }
    }
    
    func goToAddMarkerView () {
        let AddMarkerViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AddMarkerViewController")
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
                tryingToShowMyLocation = false
                showMyLocation()
            }
        }
    }
    
    // Help user adjust settings if accidentally denied
    func showLocationAcessDeniedAlert() {
        let alertController = UIAlertController(title: "Location Services",
            message: "This action requires your location. Please allow access to location services in Settings to continue.",
            preferredStyle: .Alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (alertAction) in
            
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // Get public markers from api for the map's current
    // latitude and longitude
    func addPublicMarkers() {
        
        //** Get bottom-left and upper-right coords
        
        // Get projection
        guard let projection = mapView!.projection else {
            return
        }
        
        // Get visible region (4 coords for each corner)
        // can never be nil
        let visibleRegion = projection.visibleRegion()
        
        let bleft = visibleRegion.nearLeft
        let tright = visibleRegion.farRight
        
        // Send request to server
        
        // Add received markers to map
        
    }

    func removeDeleted() {
        
        // Loop through deleted items
        for timestamp in deletedMarkers {
            
            // Get marker by timestamp
            let marker = curMapMarkers.filter{ $0.title == String(format: "%.7f", timestamp) }.first! as GMSMarker
            
            // Remove from map
            marker.map = nil
        }
        
        // Clear deleted markers
        //deletedMarkers = []
    }
    
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

