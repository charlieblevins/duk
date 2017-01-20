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
    
    // Array of timestamps for markers to delete from map
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
            NotificationCenter.default.addObserver(self, selector: #selector(self.enableMapLocation), name: NSNotification.Name(rawValue: LocationNotifKey), object: nil)
        } else {
            enableMapLocation()
        }
        

        // Observe changes to myLocation prop of mapView
        mapView!.addObserver(self, forKeyPath: "myLocation", options: .new, context: nil)
    }
    
    // Hide nav bar for this view, but show for others
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        
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
                mapView!.animate(toLocation: CLLocationCoordinate2DMake(markerToAdd!.latitude!, markerToAdd!.longitude!))
                self.mapIsAtRest = false
            }
            
            // Clear the array
            markerToAdd = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func showGMap () {
        
        // Set map delegate as this view controller class
        mapView!.delegate = self
    }
    
    
    // Check location permissions and either
    // - show and animate to the user's current location
    // - request the user's permission to access location
    // - show an alert that tells user how to allow location permission
    func checkUserLocation (_ alertFailure: Bool, authHandler: (()->Void)?) {
        
        if authHandler != nil {
            self.locationAuthHandler = authHandler
        }
        
        // Location services must be on to continue
        if CLLocationManager.locationServicesEnabled() == false && alertFailure {
            showLocationAcessDeniedAlert("Location services are disabled. Location services are required to access your location.")
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
            
        case .authorizedWhenInUse:
            fallthrough
        case .authorizedAlways:
            
            // Location use is authorized, execute auth handler
            if self.locationAuthHandler != nil {
                self.locationAuthHandler!()
                self.locationAuthHandler = nil
            }

        case .notDetermined:
            
            // Request location auth. If user approves
            // delegate method will handler authHandler execution
            reqUserLocation()
            
            break
            
        case .denied:
            fallthrough
        case .restricted:
            if alertFailure {
                showLocationAcessDeniedAlert(nil)
            }
        }
    }
    
    func showNearbyMarkers () {
        
        // Enable user location on Google Map and allow
        // observer to show location on first update
        if mapView!.isMyLocationEnabled != true {
            didFindMyLocation = false
            mapView!.isMyLocationEnabled = true
            
            // Location is already enabled: zoom to location
        } else if mapView!.myLocation != nil {
            
            loadNearbyMarkers()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("lcoation update")
        print(locations)
    }
    
    // Begin loading nearby markers on first update
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
                marker_aggregator.loadNearPoint(self.mapView!.myLocation!.coordinate, noun: nil, searchType: .myLocation)
            }
            return
        } else {

            marker_aggregator.loadNearPoint(mapView!.myLocation!.coordinate, noun: nil, searchType: .myLocation);
        }
    }
    
    func enableMapLocation () {
        if mapView!.isMyLocationEnabled != true {
            mapView!.isMyLocationEnabled = true
        }
    }
    
    func animateToCurLocation () {
        if let loc = mapView?.myLocation {
            mapView!.animate(to: GMSCameraPosition.camera(withTarget: loc.coordinate, zoom: 10))
            self.mapIsAtRest = false
        }
    }
    
    // map reaches idle state
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        print("map is idle")
        self.mapIsAtRest = true;
        if self.mapTilesFinishedRendering {
            self.mapAtRest()
        }
    }
    
    func mapViewDidStartTileRendering(_ mapView: GMSMapView) {
        self.mapTilesFinishedRendering = false
    }
    
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
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
    func addMarkersNearby (_ curLocation: CLLocationCoordinate2D) {
        
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
    
    func showCoreMarkersWithin (_ bounds: GMSCoordinateBounds) {
        
        // Show user's saved markers if they exist
        let markers_from_core = Util.fetchCoreData("Marker", predicate: nil)
        
        if markers_from_core?.count == 0 {
            return
        }
        
        // Find and return markers within provided bounds
        for marker_data in markers_from_core! {

            let marker = Marker(fromCoreData: marker_data)
            
            // Get marker coords
            let coords = CLLocationCoordinate2D(latitude: marker.latitude!, longitude: marker.longitude!)
            
            if bounds.contains(coords) {
                
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
    func addMarkerToMap (_ marker: Marker) {
        
        let mapMarker = marker.getMapMarker()
        
        // Add marker to the map
        mapMarker!.assignMap(mapView)
        
        // Store all map markers
        curMapMarkers.append(mapMarker!)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("marker tapped")
        mapView.selectedMarker = marker
        
        var cg_point = mapView.projection.point(for: marker.position)
        cg_point.y = cg_point.y - 100
        
        let camPos = GMSCameraPosition(
            target: mapView.projection.coordinate(for: cg_point),
            zoom: mapView.camera.zoom,
            bearing: mapView.camera.bearing,
            viewingAngle: mapView.camera.viewingAngle
        )
        
        mapView.animate(to: camPos)
        return true
    }
    
    // Info Window Pop Up
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        print("info window is about to show")
        
        // Allow view to update dynamically (only in v 1.13 which is broken!
        marker.tracksInfoWindowChanges = true
        
        // Get info window view
        let customInfoWindow = Bundle.main.loadNibNamed("InfoWindow", owner: self, options: nil)?[0] as! InfoWindowView
        
        let custom_marker = marker as! DukGMSMarker
        
        // Set tags (stored in map marker obj)
        customInfoWindow.tags.attributedText = Marker.formatNouns(custom_marker.tags!)
        
        // Get image for local marker
        if custom_marker.dataLocation == .local {
            
            // Hide loading
            customInfoWindow.loading.isHidden = true
            
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
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf mapMarker: GMSMarker) {
        print("info window tapped")
        
        // 1. Get marker data
        
        guard let map_marker = mapMarker as? DukGMSMarker else {
            print("could not convert map marker to DukGMSMarker")
            return
        }
        
        // If marker is local, create marker from core data
        if map_marker.dataLocation == .local {
            
            guard let timestamp = map_marker.timestamp else {
                print("marker had no timestamp in didTapInfoWindow")
                return
            }
            
            guard let data = Util.fetchCoreData("Marker", predicate: NSPredicate(format: "timestamp = %lf", timestamp)) else {
                print("search for marker by timestamp failed")
                return
            }
            
            guard data.count > 0 else {
                print("No markers found by timestamp: \(timestamp)")
                return
            }
            
            let marker = Marker(fromCoreData: data[0])
            performSegue(withIdentifier: "MapToMarkerDetail", sender: marker)
            
        // marker is public
        } else {
            
            // Get marker data
//            let request = ApiRequest()
//            request.delegate = self
//            request.getMarkerDataById([["public_id": marker_d.public_id!, "photo_size": "full"]])
            
            guard let pid = map_marker.public_id else {
                print("Error: marker has no public id")
                return
            }
            
            let marker_request = MarkerRequest()
            
            let sizes: [MarkerRequest.PhotoSizes] = [.sm, .md, .full]
            let marker_param = MarkerRequest.LoadByIdParamsSingle(pid, sizes: sizes)
            
            marker_request.loadById([marker_param], completion: {markers in
                
                guard let marker = markers?[0] else {
                    print("no markers returned")
                    self.hideLoading(nil)
                    return
                }
                
                // Load marker detail
                if self.loaderOverlay != nil {
                    
                    // Hide loader
                    self.loaderOverlay?.dismiss(animated: false, completion: {
                        self.performSegue(withIdentifier: "MapToMarkerDetail", sender: marker)
                    })
                    
                } else {
                    self.performSegue(withIdentifier: "MapToMarkerDetail", sender: marker)
                }

            }, failure: {
                self.loaderOverlay?.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Pass marker data to edit view
        if segue.identifier == "MapToMarkerDetail" {
            
            // Get next view controller
            let detailView = segue.destination as! AddMarkerController
            
            guard let marker = sender as? Marker else {
                print("Error: data could not be converted in segue")
                return
            }
            
            detailView.editMarker = marker
        }
    }
    
    @IBAction func addMarker(_ sender: DukBtn) {
        
        // Ensure we have location authorization
        // then move to add marker view
        self.checkUserLocation(true) {
            self.goToView("AddMarkerController")
            self.toggleMenu(!self.menuOpen)
        }
    }
    
    @IBAction func accountTapped(_ sender: DukBtn) {
        self.goToView("AccountViewController")
        self.toggleMenu(!self.menuOpen)
    }
    
    @IBAction func markersTapped(_ sender: DukBtn) {
        self.goToView("MyMarkersController")
        self.toggleMenu(!self.menuOpen)
    }
    
    func goToView(_ controllerName: String) {
        let view = self.storyboard!.instantiateViewController(withIdentifier: controllerName)
        self.navigationController?.pushViewController(view, animated: true)
    }
    
    // Show the my location (cross-hair) button
    func showMyLocationBtn () {
        let button = DukBtn()
        
        // Build button
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.white
        
        // Add crosshair image
        guard let image = UIImage(named: "crosshair") else {
            return
        }
        
        button.setImage(image, for: UIControlState())
        
        let inset: CGFloat = 12
        button.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset)
        
        
        // Dimensions
        let widthConstraint = NSLayoutConstraint(
            item: button,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 50)
        
        
        let heightConstraint = NSLayoutConstraint(
            item: button,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 50)
        
        
        // Make Circle
        button.layer.cornerRadius = 25
        
        // Position
        let horizontalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: view,
            attribute: .trailing,
            multiplier: 1,
            constant: -15)
        
        let verticalConstraint = NSLayoutConstraint(
            item: button,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: view,
            attribute: .bottom,
            multiplier: 1,
            constant: -15)
        
        // Set action
        button.addTarget(self, action: #selector(myLocationBtnTapped), for: UIControlEvents.touchUpInside)
        
        // Add button to view
        self.view.addSubview(button)
        
        // Shadow
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 4
        
        // Undo default clipping mask to make shadow visible
        button.layer.masksToBounds = false
        
        // Activate constraints
        heightConstraint.isActive = true
        widthConstraint.isActive = true
        horizontalConstraint.isActive = true
        verticalConstraint.isActive = true
    }
    
    // Animate to users location OR alert
    // the user about a permissions problem
    func myLocationBtnTapped () {
        
        checkUserLocation(true) {
            self.showNearbyMarkers()
        }
    }
    
    /** Menu Handling */
    @IBAction func dukTapped(_ sender: DukBtn) {
        toggleMenu(!menuOpen)
    }
    
    func toggleMenu (_ open: Bool) {
        
        for btn in menuBtns {
            btn.isHidden = !open
        }
        
        menuBG.isHidden = !open
        
        menuOpen = open
        
        if open {
            let closeX = UIImage(named: "close-x-small-white")
            dukBtn.setImage(closeX, for: UIControlState())
            let inset: CGFloat = 20
            dukBtn.imageEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset)
            dukBtn.setTitle("", for: UIControlState())
        } else {
            dukBtn.setTitle("DUK", for: UIControlState())
            dukBtn.setImage(nil, for: UIControlState())
        }
    }

    
    // Search Btn Tapped
    @IBAction func searchTapped(_ sender: AnyObject) {
        appendSearchBox()
        toggleMenu(!menuOpen)
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
            attribute: .width,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .width,
            multiplier: 1,
            constant: 0
        )
        width_constraint.isActive = true
        
        // Constant height
        let height_constraint = NSLayoutConstraint(
            item: self.searchBox!.view,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 170
        )
        height_constraint.isActive = true
        
        // Top
        let top_constraint = NSLayoutConstraint(
            item: self.searchBox!.view,
            attribute: .top,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .top,
            multiplier: 1,
            constant: 0
        )
        top_constraint.isActive = true
        
        // Left
        let left_constraint = NSLayoutConstraint(
            item: self.searchBox!.view,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .leading,
            multiplier: 1,
            constant: 0
        )
        left_constraint.isActive = true
    }
    
    // Hide the search box
    func hideSearchBox () {
        guard self.searchBox != nil else {
            print("cannot hide searchbox. search box not present")
            return
        }
        
        self.searchBox?.willMove(toParentViewController: nil)
        self.searchBox?.view.removeFromSuperview()
        self.searchBox?.removeFromParentViewController()
    }
    
    func appendSearchResults (_ message: String?) {
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
            attribute: .width,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .width,
            multiplier: 1,
            constant: 0
        )
        width_constraint.isActive = true
        
        // Constant height
        let height_constraint = NSLayoutConstraint(
            item: searchResults.view,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 45
        )
        height_constraint.isActive = true
        
        // Top
        let top_constraint = NSLayoutConstraint(
            item: searchResults.view,
            attribute: .top,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .top,
            multiplier: 1,
            constant: 0
        )
        top_constraint.isActive = true
        
        // Left
        let left_constraint = NSLayoutConstraint(
            item: searchResults.view,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .leading,
            multiplier: 1,
            constant: 0
        )
        left_constraint.isActive = true
    }

    
    // Request user location by initializing CLLocationManager
    // This will promp the user to give the app location permission
    // if not already allowed.
    func reqUserLocation () {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        mapView!.isMyLocationEnabled = true
    }
    
    // Change of user location permissions. If authorized, exec auth handler
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            
            if self.locationAuthHandler != nil {
                self.locationAuthHandler!()
                self.locationAuthHandler = nil
            }
        }
    }
    
    // Help user adjust settings if accidentally denied
    func showLocationAcessDeniedAlert(_ message: String?) {
        var final_message: String?
        
        if message == nil {
            final_message = "This action requires your location. Please allow access to location services in Settings."
        } else {
            final_message = message
        }
        
        let alertController = UIAlertController(title: "Location Services",
                                                message: final_message,
                                                preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
            
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction) in
            
            // If mapAtRest handler exists, execute it
            // and remove
            self.mapAtRest()
        })
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func removeDeleted() {
        
        // Loop through deleted items
        for timestamp in deletedMarkers {
            
            // Get marker by timestamp
            if let marker_ind = curMapMarkers.index(where: { $0.timestamp == timestamp }) {
                
                // Remove from map
                curMapMarkers[marker_ind].map = nil
                
                curMapMarkers.remove(at: marker_ind)
            }
        }
        
        // Clear deleted markers
        deletedMarkers = []
    }
    
    // ApiRequestDelegate methods
    
    // Route data received from api to corresponding handler function
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        
        if data["data"] == nil {
            print("Api server returned no data")
            return Void()
        }
        
        switch method {
            
        case .markersNearPoint:
            handleMarkersWithinBoundsResponse(data)
        
        case .markersWithinBounds:
            handleMarkersWithinBoundsResponse(data)
            break
        
        case .getMarkerDataById:
            handleGetMarkerDataByIdResponse(data)
            break
            
        default:
            print("Unknown api method")
        }
    }
    
    func imageDownloadDidProgress (_ progress: Float) {
        let percentage = Int(progress * 100)
        curInfoWindow!.loading.text = "Loading: \(percentage)%"
    }
    
    // Image request handler
    func reqDidComplete(withImage image: UIImage) {
        
        // Hide loading
        curInfoWindow!.loading.isHidden = true
        
        curInfoWindow!.image.image = image
    }
    
    func reqDidFail(_ error: String, method: ApiMethod, code: Int) {
        
        loaderOverlay?.dismiss(animated: false, completion: nil)
        
        if method == .image {
            curInfoWindow!.loading.text = "Image failed to load"
        }
        
        print(error)
    }

    
    // Handle data returned from a markersWithinBounds api request
    func handleMarkersWithinBoundsResponse (_ data: NSDictionary) {
        var pubMarkersById: [String: AnyObject] = [:]
        
        // Loop over received marker data
        let marker_array = data["data"] as! [AnyObject]
        for marker_data in marker_array {
            
            // Convert data to DukGMSMarker
            let marker = Marker(fromPublicData: marker_data as! [String: AnyObject] as NSDictionary)
            
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
            pubMarkersById.removeValue(forKey: public_id)
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
    func handleGetMarkerDataByIdResponse (_ data: NSDictionary) {
        
        print("received marker data")
        
        // Send marker data as dictionary
        let sender = data["data"]! as! [String: AnyObject]

        // Load marker detail
        if loaderOverlay != nil {
            
            // Hide loader
            loaderOverlay?.dismiss(animated: false, completion: {
                self.performSegue(withIdentifier: "MapToMarkerDetail", sender: sender)
            })
        
        } else {
            self.performSegue(withIdentifier: "MapToMarkerDetail", sender: sender)
        }
    }
    
    func markerAggregator(loadDidFail error: String, method: LoadMethod) {
        print("Marker load failed")
    }
    
    func markerAggregator(loadDidComplete data: [Marker], method: LoadMethod, noun: String?) {
        print("Marker load complete")
        
        // Clear all existing markers
        mapView.clear()
        curMapMarkers = []
        
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
                
                // Display marker on map
                mm.map = self.mapView
                
                // Store reference
                curMapMarkers.append(mm)
                
                if groupBounds == nil {
                    groupBounds = GMSCoordinateBounds(coordinate: mm.position, coordinate: mm.position)
                } else {
                    groupBounds = groupBounds!.includingCoordinate(mm.position)
                }
            }
        }
        
        // Animate camera to markers
        let cameraUpdate = GMSCameraUpdate.fit(groupBounds!)
        mapView!.animate(with: cameraUpdate)
        
        // Search is automatic on app open
        // so search results are unexpected
        if GLOBALS.firstSearch {
            GLOBALS.firstSearch = false
            return
        }
        
        if method == .markersNearPoint {
            appendSearchResults("\(data.count) nearby markers")
        
        } else if method == .markersWithinBounds {
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
    
    func assignMap (_ map: GMSMapView) {
        self.map = map
    }
}

enum DataLocation {
    case local, `public`
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
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    func setup () {
        
        // Change BG on down press
        self.addTarget(self, action: #selector(self.pressDown), for: .touchDown)
        
        // Reset bg on release
        self.addTarget(self, action: #selector(self.resetBg), for: .touchUpInside)
        
        // Shadow
        self.layer.shadowColor = UIColor.black.cgColor
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

