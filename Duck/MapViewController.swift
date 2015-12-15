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
    }
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    func showGMap () {
        let camera = GMSCameraPosition.cameraWithLatitude(-33.86,
            longitude: 151.20, zoom: 6)
        mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        self.view = mapView
    }

    
    func addMarker (markerLat: CLLocationDegrees, markerLng: CLLocationDegrees, titleText: String?, image: UIImage?) {

        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(markerLat, markerLng)
        
        if let title = titleText {
            marker.title = title
        } else {
            marker.title = "Hello world!"
        }
        
        marker.snippet = "Test snippet"
        
        //marker.icon = image
        
        // Add marker to the map
        marker.map = mapView
    }
    
    func addMarkersFromCore () {
        
        // Show user's saved markers if they exist
        let savedMarkers = Util.fetchCoreData("Marker")
        
        if savedMarkers.count > 0 {
            for marker in savedMarkers {
                
                // Add marker
                let image = UIImage(data: marker.valueForKey("photo") as! NSData)
                self.addMarker(marker.latitude, markerLng: marker.longitude, titleText: marker.valueForKey("tags") as? String, image: image)
            }
            
            // Set mapview to last marker
            let lastMarker = savedMarkers.last
            mapView!.animateToLocation(CLLocationCoordinate2DMake(lastMarker!.latitude, lastMarker!.longitude))
            mapView!.animateToZoom(12)
        }
    }
    
    func mapView(mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView {
        print("marker is about to show")
        return UIView()
    }
    
    // Show Add Marker button
    func showAddMarkerButton() {
        let button = UIButton()
        
        // Build button
        button.frame = CGRectMake(100, 100, 100, 50)

        button.backgroundColor = UIColor.greenColor()
        button.setTitle("Add Marker", forState: UIControlState.Normal)
        
        // Position
        button.translatesAutoresizingMaskIntoConstraints = false
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
            constant: 0)
        
        // Set action
        button.addTarget(self, action: "addMarker:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Add button to view
        self.view.addSubview(button)
        
        // Activate constraints
        horizontalConstraint.active = true
        verticalConstraint.active = true
    }
 
    // Moves user to add marker view
    func addMarker(sender:UIButton!) {
        
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


        
        //self.addMarker(51.505009, markerLng: -0.120699)
    }
    
    func showMyMarkersButton () {
        let button = UIButton()
        
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
        let alertController = UIAlertController(title: "Sad Face Emoji!",
            message: "Access to your location is required. Please enable it in Settings to continue.",
            preferredStyle: .Alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (alertAction) in
            
            // THIS IS WHERE THE MAGIC HAPPENS!!!!
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    
    
}

