//
//  MapViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 9/20/15.
//  Copyright (c) 2015 Charlie Blevins. All rights reserved.
//

import Mapbox
import Foundation
import CoreLocation
import CoreData

class MapViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    
    var mapView: MGLMapView!
    var locationManager: CLLocationManager!
    var tryingToAddMarker: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showMap()
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

    // Initialize a Mapbox Map
    func showMap() {
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // Set the delegate property of our map view to self after instantiating it.
        mapView.delegate = self
        
        view.addSubview(mapView)

        // Show user's saved markers if they exist
        let savedMarkers = Util.fetchCoreData("Marker")
        
        if savedMarkers.count > 0 {
            for marker in savedMarkers {
                print(marker)
                
                mapView.setCenterCoordinate(CLLocationCoordinate2D(latitude: marker.latitude,
                    longitude: marker.longitude),
                    zoomLevel: 12, animated: false)
                
                // Add a test marker
                self.addMarker(marker.latitude, markerLng: marker.longitude)
            }
        } else {
            // London - test
            // set the map's center coordinate
            mapView.setCenterCoordinate(CLLocationCoordinate2D(latitude: 51.513594,
                longitude: -0.127210),
                zoomLevel: 12, animated: false)
            
            // Add a test marker
            self.addMarker(51.502202, markerLng: -0.134982)
        }

        
        // Turn on debug
        //mapView.toggleDebug()
    }
    
    func addMarker (markerLat: CLLocationDegrees, markerLng: CLLocationDegrees) {
        // Declare the marker `hello` and set its coordinates, title, and subtitle
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: markerLat, longitude: markerLng)
        hello.title = "Hello world!"
        hello.subtitle = "Welcome to my marker"
        
        // Add marker `hello` to the map
        mapView.addAnnotation(hello)
    }
    
    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Memory efficiency: If a marker is available from the reusable queue, use it
        if let pin = mapView.dequeueReusableAnnotationImageWithIdentifier("customPin") {
            return pin
        }
        
        let image = UIImage(named: "mapMarker")!
        return MGLAnnotationImage(image: image, reuseIdentifier: "customPin")
    }
    
    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
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
            constant: 0)
        
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
        mapView.showsUserLocation = true;
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
    
    func fetchCoreData (entityName: String) -> [AnyObject]! {
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        //3
        do {
            return try managedContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
    }

    
}

