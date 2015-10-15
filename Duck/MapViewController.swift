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

class MapViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    
    var mapView: MGLMapView!
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Request user location
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

    }
    
    // Hide nav bar for this view, but show for others
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    // Callback for user location permissions
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
            
            showMap()
            showAddMarkerButton()
        }
    }
    
    // Initialize a Mapbox Map
    func showMap() {
        mapView = MGLMapView(frame: view.bounds)
        mapView.showsUserLocation = true;
        mapView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // Turn on debug
        //mapView.toggleDebug()
        
        // set the map's center coordinate ,
        mapView.setCenterCoordinate(CLLocationCoordinate2D(latitude: 51.513594,
            longitude: -0.127210),
            zoomLevel: 12, animated: false)
        view.addSubview(mapView)
        
        // Set the delegate property of our map view to self after instantiating it.
        mapView.delegate = self
        
        // Add a test marker
        self.addMarker(51.502202, markerLng: -0.134982)
        
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
        
        let AddMarkerViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AddMarkerViewController")
        self.navigationController?.pushViewController(AddMarkerViewController, animated: true)
        
        //self.addMarker(51.505009, markerLng: -0.120699)
    }
    
}

