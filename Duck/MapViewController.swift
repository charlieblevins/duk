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

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, ApiRequestDelegate, MarkerAggregatorDelegate {
    
    @IBOutlet weak var menuBG: UIView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var searchBtn: DukBtn!
    @IBOutlet weak var addMarkerBtn: DukBtn!
    @IBOutlet weak var markersBtn: DukBtn!
    @IBOutlet weak var accountBtn: DukBtn!
    @IBOutlet weak var dukBtn: DukBtn!

    var menuBtns: [DukBtn]!
    var menuOpen: Bool = false
    
    var locationManager: CLLocationManager!

    
    // Flag used by location observer to animate to location
    var didFindMyLocation: Bool = false
    
    // Handler to execute when map comes to rest
    // Allows executing other tasks after map reaches new region
    var mapAtRestHandler:(()->Void)!
    
    var locationAuthHandler:(()->Void)!
    
    // Array of all markers in view
    var markersInView: [AnyObject] = []
    
    var deletedMarkers: [Double] = []
    var curMapMarkers: [DukGMSMarker] = []
    
    // Reference search box when present
    var searchBox: SearchBox? = nil
    
    
    // Store a marker from the addMarker view to be 
    // loaded when completing add marker task and viewing
    // newly created marker
    var markerToAdd: Marker?
    
    var mapIsAtRest: Bool = false
    var mapTilesFinishedRendering: Bool = false
    
    // Current infowindow
    var curInfoWindow: InfoWindowView? = nil
    
    // Loader overlay
    var loaderOverlay: UIAlertController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize and show google map
        showGMap()
        
        // Add buttons
        //showAddMarkerButton()
        showMyLocationBtn()
        
        menuBtns = [searchBtn, addMarkerBtn, markersBtn, accountBtn]
        toggleMenu(false)
        
        // This kicks off all initial loading.
        checkUserLocation(false) {
            self.showNearbyMarkers()
        }
        
        // Observe changes in user location OR
        if DistanceTracker.sharedInstance.locationManager.location == nil {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.enableMapLocation), name: LocationNotifKey, object: nil)
        } else {
            enableMapLocation()
        }
        

        // Observe changes to myLocation prop of mapView
        mapView!.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
    }
    
    // Hide nav bar for this view, but show for others
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        
        // Remove deleted from map
        if (deletedMarkers.count > 0) {
            removeDeleted()
        }
        
        // Add new markers to map
        if (markerToAdd != nil) {
            
            // Add marker
            self.addMarkerToMap(markerToAdd!)
            
            // Center on marker
            if mapView != nil {
                mapView!.animateToLocation(CLLocationCoordinate2DMake(markerToAdd!.latitude!, markerToAdd!.longitude!))
                self.mapIsAtRest = false
            }
            
            // Clear the array
            markerToAdd = nil
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    func showGMap () {
        
        // Set map delegate as this view controller class
        mapView!.delegate = self
    }
    
    
    // Check location permissions and either
    // - show and animate to the user's current location
    // - request the user's permission to access location
    // - show an alert that tells user how to allow location permission
    func checkUserLocation (alertFailure: Bool, authHandler: (()->Void)?) {
        
        if authHandler != nil {
            self.locationAuthHandler = authHandler
        }
        
        // Location services must be on to continue
        if CLLocationManager.locationServicesEnabled() == false && alertFailure {
            showLocationAcessDeniedAlert("Location services are disabled. Location services are required to access your location.")
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
            
        case .AuthorizedWhenInUse:
            fallthrough
        case .AuthorizedAlways:
            
            // Location use is authorized, execute auth handler
            if self.locationAuthHandler != nil {
                self.locationAuthHandler!()
                self.locationAuthHandler = nil
            }

        case .NotDetermined:
            
            // Request location auth. If user approves
            // delegate method will handler authHandler execution
            reqUserLocation()
            
            break
            
        case .Denied:
            fallthrough
        case .Restricted:
            if alertFailure {
                showLocationAcessDeniedAlert(nil)
            }
        }
    }
    
    func showNearbyMarkers () {
        
        // Enable user location on Google Map and allow
        // observer to show location on first update
        if mapView!.myLocationEnabled != true {
            didFindMyLocation = false
            mapView!.myLocationEnabled = true
            
            // Location is already enabled: zoom to location
        } else if mapView!.myLocation != nil {
            
            loadNearbyMarkers()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("lcoation update")
        print(locations)
    }
    
    // Begin loading nearby markers on first update
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            
            loadNearbyMarkers()
            
            didFindMyLocation = true
        }
    }
    
    // Loads all makers near the users current location, as
    // determined by the DistanceTracker
    func loadNearbyMarkers () {
        
        let marker_aggregator = MarkerAggregator()
        marker_aggregator.delegate = self
        
        // Start tracking distance for core data if not already
        if !DistanceTracker.sharedInstance.firstUpdateComplete {
            
            DistanceTracker.sharedInstance.start()
            
            // Re-call this function when data updates
            DistanceTracker.sharedInstance.delegate = marker_aggregator
            
            marker_aggregator.distanceDataCallback = {
                marker_aggregator.loadNearPoint(self.mapView!.myLocation!.coordinate, noun: nil, searchType: .MyLocation)
            }
            return
        } else {

            marker_aggregator.loadNearPoint(mapView!.myLocation!.coordinate, noun: nil, searchType: .MyLocation);
        }
    }
    
    func enableMapLocation () {
        if mapView!.myLocationEnabled != true {
            mapView!.myLocationEnabled = true
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
    
    // Add markers near the user's current location
    func addMarkersNearby (curLocation: CLLocationCoordinate2D) {
        
        // 1. Get 20 nearest from server
        let req = ApiRequest()
        req.delegate = self
        req.getMarkersNear(curLocation, noun: nil)
        
        // 2. get 20 nearest from local
        //let nearest_loc = self.getNearbyLocal(curLocation)
        
        // 3. Aggregate and get 20 closest
        
        
        // 2. Get local markers within bounds
        //self.showCoreMarkersWithin(bounds)
        
        // 3. Get public markers within bounds

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
        req.getMarkersWithinBounds(bounds, page: nil)
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
            let coords = CLLocationCoordinate2D(latitude: marker.latitude!, longitude: marker.longitude!)
            
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
    func addMarkerToMap (marker: Marker) {
        
        let mapMarker = marker.getMapMarker()
        
        // Add marker to the map
        mapMarker!.assignMap(mapView)
        
        // Store all map markers
        curMapMarkers.append(mapMarker!)
    }
    
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        print("marker tapped")
        mapView.selectedMarker = marker
        
        var cg_point = mapView.projection.pointForCoordinate(marker.position)
        cg_point.y = cg_point.y - 100
        
        let camPos = GMSCameraPosition(
            target: mapView.projection.coordinateForPoint(cg_point),
            zoom: mapView.camera.zoom,
            bearing: mapView.camera.bearing,
            viewingAngle: mapView.camera.viewingAngle
        )
        
        mapView.animateToCameraPosition(camPos)
        return true
    }
    
    // Info Window Pop Up
    func mapView(mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        print("info window is about to show")
        
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
    
    // Tapped info window
    func mapView(mapView: GMSMapView, didTapInfoWindowOfMarker marker: GMSMarker) {
        print("info window tapped")
        
        // 1. Get marker data
        
        let marker_d = marker as! DukGMSMarker
        
        // If marker is local, create marker from core data
        if marker_d.dataLocation == .Local {
            
            let data = Util.fetchCoreData("Marker", predicate: NSPredicate(format: "timestamp = %lf", marker_d.timestamp!))
            
            let data_as_dictionary = Util.coreToDictionary(data[0] as! NSManagedObject)
            
            if data.count > 0 {
                performSegueWithIdentifier("MapToMarkerDetail", sender: data_as_dictionary)
            } else {
                print("No markers found matching timestmap")
            }
            
        // marker is public
        } else {
            
            // Get marker data
            let request = ApiRequest()
            request.delegate = self
            request.getMarkerDataById(marker_d.public_id!, photo_size: "full")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Pass marker data to edit view
        if segue.identifier == "MapToMarkerDetail" {
            
            // Get next view controller
            let detailView = segue.destinationViewController as! AddMarkerController
            
            // Create marker instance from data and reference in next view
            let data = sender as! NSDictionary
            
            // if _id exists this data is from the server
            var marker: Marker?
            if data["_id"] != nil {
                marker = Marker(fromPublicData: data)
            } else {
                marker = Marker(fromCoreData: data)
            }
            detailView.editMarker = marker
        }
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
        
        // HIDDEN - FIXME
        button.hidden = true
    }
 
    // Moves user to add marker view
    func addMarker(sender:UIButton!) {
        
        // Ensure we have location authorization
        // then move to add marker view
        self.checkUserLocation(true) {
            self.goToAddMarkerView()
        }
    }
    
    func goToAddMarkerView () {
        let AddMarkerViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AddMarkerController")
        self.navigationController?.pushViewController(AddMarkerViewController, animated: true)
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
        goToView("MyMarkersController")
    }
    
    func goToView(controllerName: String) {
        let MyMarkersController = self.storyboard!.instantiateViewControllerWithIdentifier(controllerName)
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
    
    // Animate to users location OR alert
    // the user about a permissions problem
    func myLocationBtnTapped () {
        
        checkUserLocation(true) {
            self.showNearbyMarkers()
        }
    }
    
    /** Menu Handling */
    @IBAction func dukTapped(sender: DukBtn) {
        toggleMenu(!menuOpen)
    }
    
    func toggleMenu (open: Bool) {
        
        for btn in menuBtns {
            btn.hidden = !open
        }
        
        menuBG.hidden = !open
        
        menuOpen = open
        
        if open {
            let closeX = UIImage(named: "close-x-small-white")
            dukBtn.setImage(closeX, forState: .Normal)
            let inset: CGFloat = 20
            dukBtn.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset)
            dukBtn.setTitle("", forState: .Normal)
        } else {
            dukBtn.setTitle("DUK", forState: .Normal)
            dukBtn.setImage(nil, forState: .Normal)
        }
    }

    
    // Search Btn Tapped
    @IBAction func searchTapped(sender: AnyObject) {
        appendSearchBox()
    }
    
    func appendSearchBox () {
        self.searchBox = SearchBox(self)
            
        // Create reference to this controller
        self.searchBox!.parentController = self
        
        self.addChildViewController(self.searchBox!)
      
        // Add view but hide until constraints are in place
        self.view.addSubview(self.searchBox!.view)
        
        // Turn off conclicting automatic constraints
        self.searchBox!.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Full width
        let width_constraint = NSLayoutConstraint(
            item: self.searchBox!.view,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: self.view,
            attribute: .Width,
            multiplier: 1,
            constant: 0
        )
        width_constraint.active = true
        
        // Constant height
        let height_constraint = NSLayoutConstraint(
            item: self.searchBox!.view,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1,
            constant: 170
        )
        height_constraint.active = true
        
        // Top
        let top_constraint = NSLayoutConstraint(
            item: self.searchBox!.view,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: self.view,
            attribute: .Top,
            multiplier: 1,
            constant: 0
        )
        top_constraint.active = true
        
        // Left
        let left_constraint = NSLayoutConstraint(
            item: self.searchBox!.view,
            attribute: .Leading,
            relatedBy: .Equal,
            toItem: self.view,
            attribute: .Leading,
            multiplier: 1,
            constant: 0
        )
        left_constraint.active = true
    }
    
    // Hide the search box
    func hideSearchBox () {
        guard self.searchBox != nil else {
            print("cannot hide searchbox. search box not present")
            return
        }
        
        self.searchBox?.willMoveToParentViewController(nil)
        self.searchBox?.view.removeFromSuperview()
        self.searchBox?.removeFromParentViewController()
    }
    
    func appendSearchResults (message: String?) {
        let searchResults = SearchResultsViewController(self)
        
        // Create reference to this controller
        searchResults.parentController = self
        
        self.addChildViewController(searchResults)
        
        // Add view but hide until constraints are in place
        self.view.addSubview(searchResults.view)
        
        if message != nil {
            searchResults.setMessage(message!)
        }
        
        // Turn off conclicting automatic constraints
        searchResults.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Full width
        let width_constraint = NSLayoutConstraint(
            item: searchResults.view,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: self.view,
            attribute: .Width,
            multiplier: 1,
            constant: 0
        )
        width_constraint.active = true
        
        // Constant height
        let height_constraint = NSLayoutConstraint(
            item: searchResults.view,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1,
            constant: 45
        )
        height_constraint.active = true
        
        // Top
        let top_constraint = NSLayoutConstraint(
            item: searchResults.view,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: self.view,
            attribute: .Top,
            multiplier: 1,
            constant: 0
        )
        top_constraint.active = true
        
        // Left
        let left_constraint = NSLayoutConstraint(
            item: searchResults.view,
            attribute: .Leading,
            relatedBy: .Equal,
            toItem: self.view,
            attribute: .Leading,
            multiplier: 1,
            constant: 0
        )
        left_constraint.active = true
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
    
    // Change of user location permissions. If authorized, exec auth handler
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            
            if self.locationAuthHandler != nil {
                self.locationAuthHandler!()
                self.locationAuthHandler = nil
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
    
    // Route data received from api to corresponding handler function
    func reqDidComplete(data: NSDictionary, method: ApiMethod) {
        
        if data["data"] == nil {
            print("Api server returned no data")
            return Void()
        }
        
        switch method {
            
        case .MarkersNearPoint:
            handleMarkersWithinBoundsResponse(data)
        
        case .MarkersWithinBounds:
            handleMarkersWithinBoundsResponse(data)
            break
        
        case .GetMarkerDataById:
            handleGetMarkerDataByIdResponse(data)
            break
            
        default:
            print("Unknown api method")
        }
    }
    
    func imageDownloadDidProgress (progress: Float) {
        let percentage = Int(progress * 100)
        curInfoWindow!.loading.text = "Loading: \(percentage)%"
    }
    
    // Image request handler
    func reqDidComplete(withImage image: UIImage) {
        
        // Hide loading
        curInfoWindow!.loading.hidden = true
        
        curInfoWindow!.image.image = image
    }
    
    func reqDidFail(error: String, method: ApiMethod) {
        
        loaderOverlay?.dismissViewControllerAnimated(false, completion: nil)
        
        if method == .Image {
            curInfoWindow!.loading.text = "Image failed to load"
        }
        
        print(error)
    }

    
    // Handle data returned from a markersWithinBounds api request
    func handleMarkersWithinBoundsResponse (data: NSDictionary) {
        var pubMarkersById: [String: AnyObject] = [:]
        
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
    }
    
    // Handle data returned from a getMArkerDataById request
    func handleGetMarkerDataByIdResponse (data: NSDictionary) {
        
        print("received marker data")
        
        // Send marker data as dictionary
        let sender = data["data"]! as! [String: AnyObject]

        // Load marker detail
        if loaderOverlay != nil {
            
            // Hide loader
            loaderOverlay?.dismissViewControllerAnimated(false, completion: {
                self.performSegueWithIdentifier("MapToMarkerDetail", sender: sender)
            })
        
        } else {
            self.performSegueWithIdentifier("MapToMarkerDetail", sender: sender)
        }
    }
    
    func markerAggregator(loadDidFail error: String, method: LoadMethod) {
        print("Marker load failed")
    }
    
    func markerAggregator(loadDidComplete data: [Marker], method: LoadMethod, noun: String?) {
        print("Marker load complete")
        
        // Clear all existing markers
        mapView.clear()
        
        // If no markers, stop here
        if data.count == 0 {
            return
        }
        
        hideSearchBox()
        
        // Iterate through markers, adding them to the map
        // and creating a bounding box for the group
        var groupBounds: GMSCoordinateBounds? = nil
        for marker in data {
            
            let map_marker: DukGMSMarker? = (noun != nil) ? marker.getMapMarker(iconOverride: noun) : marker.getMapMarker()
            
            if let mm = map_marker {
                mm.map = self.mapView
                
                if groupBounds == nil {
                    groupBounds = GMSCoordinateBounds(coordinate: mm.position, coordinate: mm.position)
                } else {
                    groupBounds = groupBounds!.includingCoordinate(mm.position)
                }
            }
        }
        
        // Animate camera to markers
        let cameraUpdate = GMSCameraUpdate.fitBounds(groupBounds!)
        mapView!.animateWithCameraUpdate(cameraUpdate)
        
        if method == .MarkersNearPoint {
            appendSearchResults("\(data.count) nearby markers")
        
        } else if method == .MarkersWithinBounds {
            appendSearchResults("\(data.count) markers in view")
        }
        
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
    
    func assignMap (map: GMSMapView) {
        self.map = map
    }
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
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    init() {
        super.init(frame: CGRectZero)
        self.setup()
    }
    
    func setup () {
        
        // Change BG on down press
        self.addTarget(self, action: #selector(self.pressDown), forControlEvents: .TouchDown)
        
        // Reset bg on release
        self.addTarget(self, action: #selector(self.resetBg), forControlEvents: .TouchUpInside)
        
        // Shadow
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 4
        
        // Undo default clipping mask to make shadow visible
        self.layer.masksToBounds = false
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

