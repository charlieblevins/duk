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

protocol MapViewDelegate {
    func zoomToMarker (_ marker: Marker)
}

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, ApiRequestDelegate, MarkerAggregatorDelegate, MapViewDelegate, searchDelegate {
    
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
    
    var curMapMarkers: [DukGMSMarker] = []
    
    // Reference search box when present
    var searchBox: SearchBox? = nil
    
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
        
        // Observe changes to marker data
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMarkerUpdate), name: Notification.Name("MarkerEditIdentifier"), object: nil)

        // Observe changes to myLocation prop of mapView
        mapView!.addObserver(self, forKeyPath: "myLocation", options: .new, context: nil)
    }
    
    // Hide nav bar for this view, but show for others
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
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
        
        guard let map_view = self.mapView else {
            print("Error: cannot show nearby markers - no map view is present")
            return
        }
        
        // Enable user location on Google Map and allow
        // observer to show location on first update
        if map_view.isMyLocationEnabled != true {
            didFindMyLocation = false
            map_view.isMyLocationEnabled = true
            
            // Location is already enabled: zoom to location
        } else if map_view.myLocation != nil {
            
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
    
    func zoomToMarker (_ marker: Marker) {
        
        self.addMarkerToMap(marker, completion: { mapMarker in
            
            // Animate to marker
            if let map_marker = mapMarker {
                self.zoomToPosition(map_marker.position)
                self.showInfoWindow(map_marker)
            }
        })

    }
    
    func zoomToPosition (_ position: CLLocationCoordinate2D) {
        self.mapView?.animate(to: GMSCameraPosition.camera(withTarget: position, zoom: 16))
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
                marker.getMapMarker(nil, completion: { mapMarker in
                    
                    if let map_marker = mapMarker {
                
                        map_marker.assignMap(self.mapView)
                        
                        // Save reference to active markers
                        self.curMapMarkers.append(map_marker)
                    } else {
                        print("No markers returned")
                    }
                })
            }
        }
    }
    
    // Add marker to map
    func addMarkerToMap (_ marker: Marker, completion: @escaping (_ mapMarker: DukGMSMarker?) -> Void) {
        
        marker.getMapMarker(nil, completion: { mapMarker in
            
            guard let map_marker = mapMarker else {
                completion(nil)
                return
            }
            
            // Add marker to the map
            map_marker.assignMap(self.mapView)
            
            // Store all map markers
            self.curMapMarkers.append(map_marker)
            
            completion(map_marker)
        })

    }
    
    func showInfoWindow (_ mapMarker: GMSMarker) {
        mapView.selectedMarker = mapMarker
        
        var cg_point = mapView.projection.point(for: mapMarker.position)
        cg_point.y = cg_point.y - 100
        
        let camPos = GMSCameraPosition(
            target: mapView.projection.coordinate(for: cg_point),
            zoom: mapView.camera.zoom,
            bearing: mapView.camera.bearing,
            viewingAngle: mapView.camera.viewingAngle
        )
        
        mapView.animate(to: camPos)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("marker tapped")
        
        self.showInfoWindow(marker)
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
        customInfoWindow.tags.attributedText = Marker.formatNouns(custom_marker.tags)
        customInfoWindow.tags.lineBreakMode = .byTruncatingTail
        customInfoWindow.tags.numberOfLines = 2
        
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
            
            guard let pid = map_marker.public_id else {
                fatalError("Error: marker has no public id")
            }
            
            self.showLoading("Loading")
            
            let marker_request = MarkerRequest()
            
            let sizes: [MarkerRequest.PhotoSizes] = [.sm, .md, .full]
            let marker_param = MarkerRequest.LoadByIdParamsSingle(pid, sizes: sizes)
            
            marker_request.loadById([marker_param], completion: {markers in
                
                guard let marker = markers?[0] else {
                    print("no markers returned")
                    self.hideLoading({
                        self.popAlert("Load Failed", text: "This marker no longer exists.")
                    })
                    return
                }
                
                // Load marker detail
                self.hideLoading({
                    self.performSegue(withIdentifier: "MapToMarkerDetail", sender: marker)
                })

            }, failure: {
                self.hideLoading({
                    self.popAlert("Load Failed", text: "This could be due to a weak network connection. If the problem persists, please contact us.")
                })
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
        self.goToView("MarkersWrapperController")
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
            
            let coord = self.mapView?.myLocation?.coordinate
            
            if (coord != nil) {
                self.zoomToPosition(self.mapView!.myLocation!.coordinate)
            }
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
        
        self.searchBox!.delegate = self
        
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
    
    // Remove a marker from this view's map and data source array
    func removeMarker (_ marker: Marker) {
        
        var marker_ind: Int? = nil
        
        // Remove old marker
        // Get marker by timestamp
        if let timestamp = marker.timestamp {
            marker_ind = curMapMarkers.index(where: { $0.timestamp == timestamp })
        } else if let public_id = marker.public_id {
            marker_ind = curMapMarkers.index(where: { $0.public_id == public_id })
        }
        
        guard let final_ind = marker_ind else {
            print("Could not find index of marker by public id or timestamp")
            return
        }
        
        // Remove from map
        curMapMarkers[final_ind].map = nil
        curMapMarkers.remove(at: final_ind)
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
        guard let marker_array = data["data"] as? [Dictionary<String, Any>] else {
            print("Unexpected structure returned from server")
            return
        }
        
        for marker_data in marker_array {
            
            // Convert data to DukGMSMarker
            guard let marker = Marker(fromPublicData: marker_data as NSDictionary) else {
                print("Could not convert marker data to marker instance")
                break
            }
            
            // Store map marker by public id
            if let map_marker = marker.constructMapMarker(nil) {
                
                guard let pid = map_marker.public_id else {
                    print("Error: expected marker to have public_id")
                    return
                }
                pubMarkersById[pid] = map_marker
                
            } else {
                print("could not construct map marker from marker data: \(marker)")
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
        
        let result_viewer = ResultViewer(markers: data, mapView: self.mapView, noun: noun, method: method)
        
        hideSearchBox()
        
        // no markers found
        if data.count == 0 {
            appendSearchResults(result_viewer.resultText.text)
            return
        }
        
        // Clear all existing markers
        mapView.clear()
        
        // Update map view controller's marker value store
        curMapMarkers = result_viewer.mapToDukMarkers()
        
        result_viewer.updateMap()
        
        // Search is automatic on app open
        // so search results are unexpected
        if GLOBALS.firstSearch {
            GLOBALS.firstSearch = false
            return
        }
        
        appendSearchResults(result_viewer.resultText.text)
    }
    
    // Called when any marker is changed on any view
    // Used to keep the map up to date with the latest marker data
    func handleMarkerUpdate (notification: Notification) {
        
        guard let message = notification.object as? MarkerUpdateMessage else {
            print("cannot convert message to MarkerUpdateMessage")
            return
        }
        
        // Always remove the marker first
        if message.editType == .create || message.editType == .update || message.editType == .delete {
            if let old = message.oldMarker {
                self.removeMarker(old)
            } else {
                self.removeMarker(message.marker)
            }
        }
        
        // If the removed marker is not public, we're done
        if message.editType == .delete && message.marker.isPublic() == false {
            return
        }
        
        // If edited, added OR a local copy of a public marker was deleted - add the marker back to map
        if message.editType == .create || message.editType == .update || message.marker.isPublic() {

            self.addMarkerToMap(message.marker, completion: { map_marker in
                
                // Center on last created marker
                if message.editType == .create {
                    
                    if let map_view = self.mapView {
                        guard let coord = message.marker.coordinate else {
                            print("Marker has no coordinate. Cannot animate")
                            return
                        }
                        map_view.animate(toLocation: coord)
                        self.mapIsAtRest = false
                    }
                }
            })
        }
    }
    
    // searchDelegate method
    func locationAccessFailed () {
        showLocationAcessDeniedAlert(nil)
    }
}

// Extend GMSMarker to have
// public/local data reference
// and an id/timestamp for data lookup
class DukGMSMarker: GMSMarker {
    
    // Indicate where marker data is stored
    var dataLocation: DataLocation
    
    // One of these will contain a reference
    // used for looking up info window data
    var timestamp: Double? = nil
    var public_id: String? = nil
    
    // Store tags for info window
    var tags: String
    
    init (_ coords: CLLocationCoordinate2D, tags: String, dataLocation: DataLocation, id: Any, iconOverride: String?) {

        self.tags = tags
        self.dataLocation = dataLocation
        
        super.init()
        
        self.position = coords
        
        // Get icon
        let prime_noun = (iconOverride != nil) ? Marker.getPrimaryNoun(iconOverride!) : Marker.getPrimaryNoun(tags)
        
        //let markerIconView = IconImageView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
        let _iconView = IconImageView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
        self.iconView = _iconView
        
        _iconView.load(prime_noun, complete: {
            self.iconView = _iconView
        })
        
        // Convert id to public or local
        if dataLocation == .local {
            if let t = id as? Double {
                self.timestamp = t
            } else {
                print("Error: Data location is local but id could not be casted to timestamp")
                return
            }
        } else {
            if let p = id as? String {
                self.public_id = p
            } else {
                print("Error: Data location is public but id could not be casted to string")
                return
            }
        }
    }
    
    func assignMap (_ map: GMSMapView) {
        self.map = map
    }
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

class ResultViewer {
    
    var markers: [Marker]
    var mapView: GMSMapView
    var noun: String?
    var resultText: ResultText
    
    init (markers: [Marker], mapView: GMSMapView, noun: String?, method: LoadMethod) {
        self.markers = markers
        self.mapView = mapView
        self.noun = noun
        
        self.resultText = (method == .markersNearPoint) ? NearbyResultText(markers.count) : WithinBoundsResultText(markers.count)
    }
    
    func mapToDukMarkers () -> [DukGMSMarker] {
        
        var gms_markers: [DukGMSMarker] = []
        
        for marker in markers {
            
            let map_marker: DukGMSMarker? = marker.constructMapMarker(noun)
            
            if let mm = map_marker {
                
                gms_markers.append(mm)
            }
        }
        
        return gms_markers
    }
    
    func addToMap (markers: [DukGMSMarker]) {
        
        for marker in markers {
            
            // Display marker on map
            marker.map = self.mapView
        }
    }

    func getBoundingBox (_ markers: [DukGMSMarker]) -> GMSCoordinateBounds {
        
        // Iterate through markers, adding them to the map
        // and creating a bounding box for the group
        var groupBounds: GMSCoordinateBounds = GMSCoordinateBounds()
        
        for marker in markers {

            groupBounds = groupBounds.includingCoordinate(marker.position)
        }
        
        return groupBounds
    }

    // Add markers to map, then zoom to appropriate bounding box
    func updateMap () {
        
        let gms_markers = self.mapToDukMarkers();
        
        self.addToMap(markers: gms_markers)
        
        let bounds = self.getBoundingBox(gms_markers)
        
        // Animate camera to markers
        let cameraUpdate = GMSCameraUpdate.fit(bounds)
        self.mapView.animate(with: cameraUpdate)
    }
}

protocol ResultText {
    
    var count: Int { get set }
    
    var text: String { get }
    
    init (_ count: Int)
}

extension ResultText {
    
    var markerWord: String {
        
        get {
            
            switch self.count {
            case 0:
                return "markers"
            case 1:
                return "marker"
            default:
                return "markers"
            }
        }
    }
}

class NearbyResultText: ResultText {
    
    var count: Int
    
    var text: String {
        
        // ex. "10 nearby markers"
        // ex. "1 nearby marker"
        get {
            return "\(self.count) nearby \(self.markerWord)"
        }
    }
    
    required init (_ count: Int) {
        self.count = count
    }
}


class WithinBoundsResultText: ResultText {
    
    var count: Int
    
    var text: String {
        get {
            return "\(self.count) \(self.markerWord) in view"
        }
    }
    
    required init (_ count: Int) {
        self.count = count
    }
}

