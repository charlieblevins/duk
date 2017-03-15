//
//  AddMarkerController.swift
//  Duck
//
//  Created by Charlie Blevins on 10/3/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//
// This is the marker builder page.
// This page is used to build vararker including an icon and photo

import CoreData
import CoreLocation
import UIKit

protocol AddMarkerViewDelegate {
    func addMarkerView(didUpdateMarker marker: Marker)
}

class AddMarkerController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, ZoomableImageDelegate, EditNounDelegate, CameraControlsOverlayDelegate {
    
    @IBOutlet weak var LatContainer: UIView!
    @IBOutlet weak var LngContainer: UIView!
    @IBOutlet weak var AccContainer: UIView!
    @IBOutlet weak var SaveBtn: UIButton!
    @IBOutlet weak var PublishBtn: UIButton!
    @IBOutlet weak var accLabel: UILabel!
    @IBOutlet weak var lngLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoSectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var PhotoSection: UIView!
    @IBOutlet weak var addPhotoBtn: UIButton!
    @IBOutlet weak var cameraPhoto: ZoomableImageView!
    @IBOutlet weak var NounText: UILabel!
    @IBOutlet weak var EditNoun: UIButton!
    @IBOutlet weak var iconView: MarkerIconView!
    @IBOutlet weak var DownloadSwitch: UISwitch!
    @IBOutlet weak var DownloadLabel: UILabel!
    @IBOutlet weak var favoriteSwitch: UISwitch!
    @IBOutlet weak var favoriteLabel: UILabel!
    
    var imagePicker: UIImagePickerController!
    var imageChosen: Bool = false
    var autocompleteView: UIView! = nil

    var locationManager: CLLocationManager?
    var coords: CLLocationCoordinate2D!
    var downloading: Bool = false
    var origNouns: String? = nil
    var delegate: AddMarkerViewDelegate?

    // Marker data passed in from 
    // other view
    var editMarker: Marker? = nil
    
    var existingMarker: Bool = false


    override func viewDidLoad() {

        super.viewDidLoad()
        
        self.showGuidelines()

        // Last minute styles
        addStyles()
        
        // Initialize Nouns
        updateNouns(nil)

        // New Marker
        if editMarker == nil {
            applyAddMode(Marker())
            
        // Existing Marker
        } else {
            applyExistingMode(editMarker!)
        }
        
        initSwitches(editMarker!)
        
        initGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showGuidelines () {
        
        let dontShow = UserDefaults.standard.bool(forKey: "stopMarkerGuidelineMessage")
        
        if dontShow == true {
            return
        }
        
        self.overlay("MarkerGuidelinesViewController")
    }
    
    // Setup view for adding a new marker
    func applyAddMode (_ marker: Marker) {
        
        self.title = "Add Marker"
        
        // Don't show initially (no changes to save yet)
        self.toggleButtonEnabled(self.SaveBtn, enabled: false)
        self.PublishBtn.isHidden = true
        
        // New empty marker
        editMarker = marker
        
        // Receive gps coords
        // Start receiving location data
        listenForCoords()
    }
    
    // Setup view for existing marker
    func applyExistingMode (_ existingMarker: Marker) {
        
        // set flag as existing marker. Any changes will only update core data
        self.existingMarker = true
        
        insertExistingData(existingMarker)
        
        // Don't show initially (no changes to save yet)
        self.SaveBtn.isHidden = true
        self.PublishBtn.isHidden = true
        
        // Store nouns before editing
        self.origNouns = existingMarker.tags
        
        if self.editMarker?.isOwned == true {
            applyEditMode(existingMarker)
        } else {
            applyDetailMode()
        }
    }

    // Setup view for editable marker
    func applyEditMode (_ marker: Marker) {
        self.title = "Edit Marker"
        
        // show publish button if private
        if !marker.isPublic() {
            self.PublishBtn.isHidden = false
            self.toggleButtonEnabled(self.SaveBtn, enabled: false)
        }
    }
    
    // Setup view for unowned marker
    func applyDetailMode () {
        self.title = "Marker Detail"
        
        // hide edit buttons
        preventEditing()
    }
    
    // Show/hide switches
    func initSwitches (_ marker: Marker) {
        initDownloadSwitch(marker)
        initFavoriteSwitch(marker)
    }
    
    // Initialize gestures
    func initGestures () {
        
        // Go to edit noun view on noun text tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(AddMarkerController.goToNounEditor))
        NounText.isUserInteractionEnabled = true
        NounText.addGestureRecognizer(tap)
    }
    
    // Load camera to take photo
    @IBAction func addPhoto(_ sender: UIButton) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        
        imagePicker.showsCameraControls = false
        
        present(imagePicker, animated: true, completion: {
            
            // Assign the overlay and associate delegate
            let overlay = CameraControlsOverlay.instanceFromNib()
            overlay.delegate = self
            self.imagePicker.cameraOverlayView = overlay
            
            // Turn off conclicting automatic constraints
            self.imagePicker.cameraOverlayView!.translatesAutoresizingMaskIntoConstraints = false
            
            // Full width
            let width_constraint = NSLayoutConstraint(
                item: self.imagePicker.cameraOverlayView!,
                attribute: .width,
                relatedBy: .equal,
                toItem: self.imagePicker.cameraOverlayView!.superview!,
                attribute: .width,
                multiplier: 1,
                constant: 0
            )
            width_constraint.isActive = true
            
            // Constant height
            let height_constraint = NSLayoutConstraint(
                item: self.imagePicker.cameraOverlayView!,
                attribute: .height,
                relatedBy: .equal,
                toItem: self.imagePicker.cameraOverlayView!.superview!,
                attribute: .height,
                multiplier: 1,
                constant: 0
            )
            height_constraint.isActive = true
    
            // Top
            let top_constraint = NSLayoutConstraint(
                item: self.imagePicker.cameraOverlayView!,
                attribute: .top,
                relatedBy: .equal,
                toItem: self.imagePicker.cameraOverlayView!.superview!,
                attribute: .top,
                multiplier: 1,
                constant: 0
            )
            top_constraint.isActive = true
    
            // Left
            let left_constraint = NSLayoutConstraint(
                item: self.imagePicker.cameraOverlayView!,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self.imagePicker.cameraOverlayView!.superview!,
                attribute: .leading,
                multiplier: 1,
                constant: 0
            )
            left_constraint.isActive = true
            
        })
    }
    
    func preventEditing () {
        addPhotoBtn.isHidden = true
        EditNoun.isHidden = true
        SaveBtn.isHidden = true
        AccContainer.isHidden = true
    }
    
    // Method called by noun view
    func nounsDidUpdate (_ nouns: String?) {

        guard self.editMarker != nil else {
            print("No editable marker. Cannot update")
            return
        }
        
        guard let new_nouns = nouns else {
            print("cannot update nouns with nil!!")
            //TODO: pop alert here - empty nouns no allowed!!!
            return
        }
        
        // Update marker data
        self.editMarker?.tags = new_nouns
        
        updateNouns(new_nouns)
        
        // If nouns have changed, enable save button
        if self.origNouns != new_nouns && imageChosen == true {
            self.PublishBtn.isHidden = true
            self.toggleButtonEnabled(self.SaveBtn, enabled: true)
        }
    }
    
    func tappedNounText(sender: UILabel) {
        
    }
    
    // Refresh UI display of Nouns
    // including icon
    func updateNouns(_ nouns: String?) {
        
        guard let new_nouns = nouns else {
            NounText.attributedText = NSMutableAttributedString(string: "Nouns...", attributes: nil)

            self.iconView.setNoun(nil)
            
            EditNoun.titleLabel?.text = "Add Nouns"
            return
        }
        
        // Format nouns
        NounText.attributedText = Marker.formatNouns(new_nouns)
        
        self.iconView.setNoun(Marker.getPrimaryNoun(new_nouns))
        
        EditNoun.setTitle("Edit Nouns", for: .normal)
    }

    
    // Update this view with existing data
    // (for editing existing marker - not for adding new marker)
    func insertExistingData (_ marker: Marker) {
        
        // Add photo
        if let photo_data = marker.photo, let image = UIImage(data: photo_data as Data) {
            setPhoto(image)
        }
        
        // Hide "Add Photo" button
        addPhotoBtn.isHidden = true
        
        // Add lat/lng data
        latLabel.text = Marker.formatSingleCoord(marker.latitude!)
        lngLabel.text = Marker.formatSingleCoord(marker.longitude!)
        accLabel.text = "N/A"
        
        // Update noun display and icon
        updateNouns(marker.tags)
    }
    
    func initDownloadSwitch (_ marker: Marker) {
        
        // Hide download option if this marker is not public
        if marker.isPublic() == false {
            toggleDownloadSwitch(false)
        }
        
        // Hide download option if not owned by this user and not already a favorite
        if marker.isOwned == false && marker.isFavorite == false {
            toggleDownloadSwitch(false)
        }
        
        // Timestamp indicates local storage
        if marker.timestamp != nil {
            DownloadSwitch.isOn = true
        } else {
            DownloadSwitch.isOn = false
        }

        DownloadSwitch.addTarget(self, action: #selector(self.downloadSwitchTapped), for: .touchUpInside)
    }
    
    func toggleDownloadSwitch (_ open: Bool) {
        DownloadSwitch.isHidden = !open
        DownloadLabel.isHidden = !open
    }
    
    func downloadSwitchTapped (sender: UISwitch) {
        
        // Download
        if sender.isOn {
            
            // Set load spinner
            self.showLoading("Downloading...")
            
            guard let pid = self.editMarker?.public_id else {
                print("Error: download switch tapped but no public id present")
                return
            }
            
            self.requestMarkerDownload(pid)
            
        // Delete from local store
        } else {
            
            sender.setOn(true, animated: false)
            
            guard let marker = self.editMarker else {
                print("Cannot remove marker: editMarker is nil")
                return
            }
            
            self.popConfirm(
                "Confirm Delete",
                text: "Are you sure you want to remove this marker? Once removed, you will need an internet connection to access this marker again.",
                onConfirm: { alert_action in
                    
                    self.deleteOfflineMarker(marker)
                    self.DownloadSwitch.setOn(false, animated: true)
                })
        }
    }
    
    func deleteOfflineMarker (_ marker: Marker) {
        // Set load spinner
        self.showLoading("Removing...")
        
        if self.editMarker?.deleteFromCore() == false {
            print("Delete from core data failed in add marker view")
        }
        
        self.hideLoading({
            let alertController = UIAlertController(title: "Marker removed",
                                                    message: "This marker is no longer stored on this device.",
                                                    preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    func initFavoriteSwitch (_ marker: Marker) {
        
        // Hide favorite option if owned by current user
        if marker.isOwned == true {
            print("not showing favorite option. marker is owned by this user")
            favoriteSwitch.isHidden = true
            favoriteLabel.isHidden = true
            return
        }
        
        // Set current value
        favoriteSwitch.isOn = marker.isFavorite
        
        favoriteSwitch.addTarget(self, action: #selector(self.favoriteSwitchTapped), for: .touchUpInside)
    }
    
    func toggleButtonEnabled (_ button: UIButton, enabled: Bool) {
        if enabled {
            button.isEnabled = true
            button.isUserInteractionEnabled = true
            button.alpha = 1.0
        } else {
            button.isEnabled = false
            button.isUserInteractionEnabled = false
            button.alpha = 0.5
        }
    }
    
    // Add or remove the favorite from core data
    func favoriteSwitchTapped (sender: UISwitch) {
        
        guard let id = self.editMarker?.public_id else {
            print("Error: cannot change favorite status of a marker with no public id")
            return
        }
        
        let favorite = Favorite(id)
        
        if sender.isOn {
            favorite.save()
            toggleDownloadSwitch(true)
            
        } else {
            
            if self.DownloadSwitch.isOn == false {
                favorite.delete()
                toggleDownloadSwitch(false)
                return
            }
            
            // This marker is saved locally: confirm deletion
            self.favoriteSwitch.setOn(true, animated: false)
            
            guard let marker = self.editMarker else {
                print("Cannot remove favorite: editMarker unavailable")
                return
            }
            
            self.popConfirm(
                "Confirm Delete",
                text: "Once removed, you will need an internet connection to access this marker again. Are you sure you want to remove it?",
                onConfirm: { alert_action in
                    
                    // Delete favorite and local copy
                    self.deleteOfflineMarker(marker)
                    favorite.delete()
                    
                    // Turn off download switch and hide it
                    self.toggleDownloadSwitch(false)
                    self.DownloadSwitch.setOn(false, animated: false)

                    // Turn off favorite
                    self.favoriteSwitch.setOn(false, animated: true)
            })
        }
    }
    
    func requestMarkerDownload (_ public_id: String) {
        let marker_request = MarkerRequest()
        
        let sizes: [MarkerRequest.PhotoSizes] = [.sm, .md, .full]
        let marker_param = MarkerRequest.LoadByIdParamsSingle(public_id, sizes: sizes)
        
        marker_request.loadById([marker_param], completion: {markers in
            
            guard let marker = markers?[0] else {
                print("no markers returned")
                self.hideLoading(nil)
                return
            }
            
            // Generate timestamp
            marker.timestamp = Marker.generateTimestamp()
            
            // Save
            marker.saveInCore()
            
            self.hideLoading(nil)
        }, failure: {
            self.hideLoading({
                let alertController = UIAlertController(title: "Marker Download Failed",
                                                        message: "Could not communicate with the server.",
                                                        preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(okAction)
                
                self.present(alertController, animated: true, completion: nil)
            })
        })
    }
    
    // Store coords when shutter is tapped
    func didTapShutter() {
        
        // update created time
        self.editMarker?.created = NSDate()
        
        // triggers didFinish...
        self.imagePicker.takePicture()
    }
    
    // Display taken photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        print(info[UIImagePickerControllerMediaMetadata] as Any)
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Add photo to UI
            setPhoto(pickedImage)
            
            // Update photo data
            editMarker!.updateImage(pickedImage)
            
            // Associate location data with this marker and display in UI
            updateLocationData()
        }
        
        // If nouns have changed, show save button
        if nounsHaveChanged() {
            self.toggleButtonEnabled(self.SaveBtn, enabled: true)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func nounsHaveChanged () -> Bool {
        guard let cur_nouns = self.editMarker?.tags else {
            return false
        }
        return self.origNouns != cur_nouns
    }
    
    func setPhoto (_ image: UIImage) {
        cameraPhoto.contentMode = .scaleAspectFit
        cameraPhoto.image = image
        imageChosen = true
        
        addPhotoBtn.setTitle("Change Photo", for: .normal)
        
        // Set delegate and allow zoom
        cameraPhoto.delegate = self
        cameraPhoto.allowZoom = true
    }
    
    // Edit Noun action - Loads noun editor view (NounViewController)
    @IBAction func EditNoun(_ sender: AnyObject) {
        print("Loading NounViewController")
        
        goToNounEditor()
    }
    
    func goToNounEditor () {
        
        let nounViewController = self.storyboard!.instantiateViewController(withIdentifier: "NounViewController") as! NounViewController
        nounViewController.delegate = self
        
        if editMarker!.tags != nil {
            nounViewController.nounsRaw = editMarker!.tags
        }
        
        self.navigationController?.pushViewController(nounViewController, animated: true)
    }
    
    // Add styles that can't easily be added in IB
    func addStyles () {
        let lightGray = UIColor(red: 207, green: 207, blue: 207).cgColor
        LatContainer.layer.borderColor = lightGray
        LngContainer.layer.borderColor = lightGray
        AccContainer.layer.borderColor = lightGray
        
        PublishBtn.imageView?.contentMode = .scaleAspectFit
    }
    
    // Start receiving GPS coordinates. First coordinates received can be innacurate
    func listenForCoords () {
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager?.delegate = self
                
                // Highest possible level of accuracy. High power consumption
                locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                
            } else {
                print("location services not enabled. Could not get location!")
                return
            }
        }
        
        locationManager?.startUpdatingLocation()
    }
    
    // Continuously listen for coordinates. Data is only used when photo is chosen
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Keep coords up to date. Used when user taps shutter for photo
        coords = manager.location!.coordinate
        print("GPS = \(coords.latitude) \(coords.longitude)")
    }
    
    func updateLocationData () {
        
        guard locationManager != nil && locationManager?.location != nil else {
            print("cannot update location data. no location data present")
            return
        }
        
        // Associate latest coords with this marker
        editMarker!.latitude = coords.latitude
        editMarker!.longitude = coords.longitude

        print("Displaying Location :: \(coords.latitude) \(coords.longitude)")
        
        // Update UI coords (limit to 8 decimal places)
        latLabel.text = Marker.formatSingleCoord(coords.latitude)
        lngLabel.text = Marker.formatSingleCoord(coords.longitude)
        
        // Get location accuracy in meters and convert to feet
        guard let meterAccuracy = locationManager?.location?.horizontalAccuracy else {
            print("Error: Cannot retrieve location accuracy")
            return
        }
        
        let ftAccuracy = meterAccuracy * 3.28084
        let ftAccRounded = Double(round(10 * ftAccuracy)/10)
        accLabel.text = "\(ftAccRounded) ft."
    }

    func validateData () -> Bool {
        var errors: [String] = []
        
        if editMarker!.photo == nil {
            errors.append("Please add a photo (required).")
        }
        
        if editMarker!.tags == nil {
            errors.append("Please add at least one tag (required).")
        }
        
        if errors.count > 0 {
            popValidationAlert(errors.joined(separator: "\n"))
            return false
        } else {
            return true
        }
    }
    
    func popValidationAlert(_ text:String) {
        let alertController = UIAlertController(title: "Missing Data",
            message: text,
            preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // User tapped save button
    @IBAction func saveButtonTapped(_ sender: AnyObject) {
        
        // Validate
        if validateData() == false {
            return
        }
        
        // since no other method of disabling works...
        if self.SaveBtn.isEnabled == false {
            return
        }
        
        guard let marker = self.editMarker else {
            print("Error: no editMarker to save.")
            return
        }
        
        guard marker.public_id != nil || marker.timestamp != nil else {
            print("No timestamp or public_id. Unable to save")
            return
        }
        
        if existingMarker == false {
            
            // Save marker in core data
            guard marker.saveInCore() else {
                print("insert marker failed")
                return
            }
            previousView()
            return
        }
        
        // Only tag changes are allowed for existing markers
        if marker.public_id == nil && marker.timestamp != nil {
            if marker.updateInCore(["tags"]) {
                self.previousView()
            } else {
                print("update marker in core failed in add marker controller")
            }
        }
        
        // Public
        if marker.public_id != nil {
            
            // Prompt for login if necessary
            self.getCredentials({ credentials in
                
                self.showLoading("Updating public marker")
                
                marker.updateGlobal(credentials, props: ["tags"], completion: { success, message in
                    
                    if success {
                        
                        self.hideLoading({
                            self.previousView()
                        })
                    
                    } else {
                        self.hideLoading({
                            self.popAlert("Update failed", text: "Make sure you have an active network connection.")
                        })
                    }
                })
            })
        }
    }
        
    @IBAction func pubBtnTapped(_ sender: UIButton) {
        
        // Sign in credentials exist
        if Credentials() != nil {
            
            self.loadPublishConfirm()
            
        // If not signed in, send to account page
        } else {
            print("no credentials found")
            let accountView = self.storyboard!.instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController
            accountView.signInSuccessHandler = { credentials in
                self.loadPublishConfirm()
            }
            self.navigationController?.pushViewController(accountView, animated: true)
        }
    }
    
    func loadPublishConfirm () {
        
        // Load publish confirmation view
        let pub_view = self.storyboard!.instantiateViewController(withIdentifier: "PublishConfirmController") as! PublishConfirmController
        
        // pass marker data
        pub_view.markerData = self.editMarker
        
        self.navigationController?.pushViewController(pub_view, completion: {
            print("complete")
        })
    }
    
    func previousView () {
        
        // Stop location data
        locationManager?.stopUpdatingLocation()
        
        // Move back to map view
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: upload delegate method handlers
    func reqDidStart() {}
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        
        if (method == .getMarkerDataById) {
            
            // Convert returned to marker objects
            guard let returned = data.value(forKey: "data") as? Array<Any> else {
                print("Returned markers could not be converted to an array")
                return
            }
            
            guard returned.count > 0 else {
                print("No public markers returned by getMarkerDataById")
                return
            }
            
            guard let data_dic: NSDictionary = returned[0] as? NSDictionary else {
                print("could not cast to NSDictionary")
                return
            }
            
            // Build marker instance
            guard let marker = Marker(fromPublicData: data_dic) else {
                print("could not build marker instance from data")
                return
            }
            
            // Generate timestamp
            marker.timestamp = Marker.generateTimestamp()
            
            // Save
            marker.saveInCore()
            
            self.downloading = false
            
            self.hideLoading(nil)
        }
        
    }
    
    // Show alert on failure
    func reqDidFail(_ error: String, method: ApiMethod, code: Int) {
        if method == .getMarkerDataById {
            self.hideLoading({
                let alertController = UIAlertController(title: "Marker Download Failed",
                                                        message: error,
                                                        preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(okAction)
                
                self.present(alertController, animated: true, completion: nil)
            })
        }
    }

}
