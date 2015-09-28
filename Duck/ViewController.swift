//
//  ViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 9/20/15.
//  Copyright (c) 2015 Charlie Blevins. All rights reserved.
//

import Mapbox
import Foundation
import CoreLocation

class ViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    
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
    
    // Callback for user location permissions
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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
        
        // set the map's center coordinate ,
        mapView.setCenterCoordinate(CLLocationCoordinate2D(latitude: 51.513594,
            longitude: -0.127210),
            zoomLevel: 12, animated: false)
        view.addSubview(mapView)
        
        // Set the delegate property of our map view to self after instantiating it.
        mapView.delegate = self
        
        // Declare the marker `hello` and set its coordinates, title, and subtitle
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: 51.502202, longitude: -0.134982)
        hello.title = "Hello world!"
        hello.subtitle = "Welcome to my marker"
        
        // Add marker `hello` to the map
        mapView.addAnnotation(hello)
        
        
    }
    
    // Use the default marker; see our custom marker example for more information
    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return nil
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
        //button.setTranslatesAutoresizingMaskIntoConstraints(false)
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
    
    func addMarker(sender:UIButton!)
    {
        print("Adding marker...")
    }
    
}

