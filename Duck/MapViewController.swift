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
    var tryingToAddMarker: Bool = false
    var savedMarkers: [AnyObject] = []
    var deletedMarkers: [Double] = []
    var curMapMarkers: [GMSMarker] = []
    var markerToAdd: [AnyObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showGMap()
        addMarkersFromCore()
        showAddMarkerButton()
        showMyMarkersButton()
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
        let camera = GMSCameraPosition.cameraWithLatitude(-33.86,
            longitude: 151.20, zoom: 6)
        mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView!.delegate = self
        self.view = mapView
        
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
        //button.frame = CGRectMake(100, 100, 225, 225)
        
        
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
            constant: -25)
        

        
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
        
        print("going to my markers...")
        let MyMarkersController = self.storyboard!.instantiateViewControllerWithIdentifier("MyMarkersController")
        self.navigationController?.pushViewController(MyMarkersController, animated: true)
    }
    
    func goToAddMarkerView () {
        let AddMarkerViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AddMarkerViewController")
        self.navigationController?.pushViewController(AddMarkerViewController, animated: true)
    }
    
    // Request user location
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
            
            if tryingToAddMarker == true {
                goToAddMarkerView()
            }
        }
    }
    
    // Help user adjust settings if accidentally denied
    func showLocationAcessDeniedAlert() {
        let alertController = UIAlertController(title: "Location Services",
            message: "Adding a marker requires your location. Please enable it in Settings to continue.",
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

