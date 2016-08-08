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

class AddMarkerController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, ZoomableImageDelegate, EditNounDelegate {
    
    @IBOutlet weak var LatContainer: UIView!
    @IBOutlet weak var LngContainer: UIView!
    @IBOutlet weak var AccContainer: UIView!
    @IBOutlet weak var SaveBtn: UIButton!
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
    @IBOutlet weak var MarkerIcon: UIImageView!
    @IBOutlet weak var IconIndicator: UIActivityIndicatorView!
    
    var imagePicker: UIImagePickerController!
    var imageChosen: Bool = false
    var iconModel: IconModel!
    var autocompleteView: UIView! = nil
    var autocomplete: Autocomplete!

    var locationManager: CLLocationManager!
    var coords: CLLocationCoordinate2D!

    // Marker data passed in from 
    // other view
    var editMarker: Marker? = nil


    override func viewDidLoad() {

        super.viewDidLoad()

        // Last minute styles
        addStyles()
        
        // Start receiving location data
        listenForCoords()
        
        // Initialize Nouns
        updateNouns(nil)
        
        // Receive gps coords
        // only if not editing already existing marker
        if editMarker == nil {
            
            self.title = "Add Marker"

            // New empty marker
            editMarker = Marker()
            editMarker!.editable = true
            
        // Insert existing marker data into view
        } else {
            
            self.title = "Edit Marker"
            
            insertExistingData(editMarker!)
        }
        
        // If marker not editable, hide edit buttons
        if editMarker!.editable == false {
            preventEditing()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // Load camera to take photo
    @IBAction func addPhoto(sender: UIButton) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .Camera
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func preventEditing () {
        addPhotoBtn.hidden = true
        EditNoun.hidden = true
        SaveBtn.hidden = true
        AccContainer.hidden = true
    }
    
    // Method called by noun view
    func nounsDidUpdate (nouns: String?) {

        if editMarker != nil {
            
            // Update marker data
            editMarker!.tags = nouns
        }
        
        updateNouns(nouns)
    }
    
    // Refresh UI display of Nouns
    // including icon
    func updateNouns(nouns: String?) {
        
        var primaryNoun: String? = nil
        
        // Create bold style attr
        let dynamic_size = UIFont.preferredFontForTextStyle(UIFontTextStyleBody).pointSize
        let bold_attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(dynamic_size)]
        var attributedString = NSMutableAttributedString(string: "")
        
        if nouns == nil {
            NounText.attributedText = NSMutableAttributedString(string: "Add Nouns Here", attributes: nil)

            setIconForNoun(nil)
            return
        
        // More than one noun - bold the first
        } else if let space_range = nouns!.rangeOfString(" ") {
            
            primaryNoun = nouns!.substringToIndex((space_range.startIndex))
            
            attributedString = NSMutableAttributedString(string: primaryNoun!, attributes: bold_attrs)
            
            // Make attr string from remaining string
            let remaining_nouns = NSMutableAttributedString(string: " \(nouns!.substringFromIndex((space_range.endIndex)))")
            
            // Concat first noun with remaining nouns
            attributedString.appendAttributedString(remaining_nouns)
            
        // No space - assume single tag
        } else {
            primaryNoun = nouns
            attributedString = NSMutableAttributedString(string: nouns!, attributes: bold_attrs)
        }
        
        NounText.attributedText = attributedString
        
        setIconForNoun(primaryNoun!)
    }
    
    // Get icon for primary noun
    func setIconForNoun (noun: String?) {
        
        // If nil, set to placeholder
        if noun == nil {
            self.MarkerIcon.image = UIImage(named: "photoMarker")
        
        // Load image from noun project
        } else {
            Util.loadIconImage(noun!, imageView: self.MarkerIcon, activitIndicator: self.IconIndicator)
        }
    }
    
    // Update this view with existing data
    // (for editing existing marker - not for adding new marker)
    func insertExistingData (marker: Marker) {
        
        // Add photo
        cameraPhoto.contentMode = .ScaleAspectFit
        cameraPhoto.image = UIImage(data: marker.photo!)
        imageChosen = true
        
        // Set delegate and allow zoom
        cameraPhoto.delegate = self
        cameraPhoto.allowZoom = true
        
        // Hide "Add Photo" button
        addPhotoBtn.hidden = true
        
        // Add lat/lng data
        latLabel.text = "\(marker.latitude!)"
        lngLabel.text = "\(marker.longitude!)"
        accLabel.text = "N/A"
        
        // Update noun display and icon
        updateNouns(marker.tags!)
    }
    
    // Display taken photo AND
    // get current location coords
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            cameraPhoto.contentMode = .ScaleAspectFit
            cameraPhoto.image = pickedImage
            imageChosen = true
            
            // Set delegate and allow zoom
            cameraPhoto.delegate = self
            cameraPhoto.allowZoom = true
            
            // Update photo data
            editMarker!.updateImage(pickedImage)

            // Associate latest coords with this photo
            editMarker!.latitude = coords.latitude
            editMarker!.longitude = coords.longitude
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Edit Noun action - Loads noun editor view (NounViewController)
    @IBAction func EditNoun(sender: AnyObject) {
        print("Loading NounViewController")
        
        let nounViewController = self.storyboard!.instantiateViewControllerWithIdentifier("NounViewController") as! NounViewController
        nounViewController.delegate = self
        
        if editMarker!.tags != nil {
            nounViewController.nounsRaw = editMarker!.tags
        }
        
        self.navigationController?.pushViewController(nounViewController, animated: true)
    }
    
    // Add styles that can't easily be added in IB
    func addStyles () {
        let lightGray = UIColor(red: 207, green: 207, blue: 207).CGColor
        LatContainer.layer.borderColor = lightGray
        LngContainer.layer.borderColor = lightGray
        AccContainer.layer.borderColor = lightGray
    }
    
    // Start receiving GPS coordinates. First coordinates received can be innacurate
    func listenForCoords () {
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                
                // Highest possible level of accuracy. High power consumption
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                
            } else {
                print("location services not enabled. Could not get location!")
                return
            }
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Only save location if associated with taking a photo
        coords = manager.location!.coordinate
        print("locations = \(coords.latitude) \(coords.longitude)")
        
        // Update UI
        latLabel.text = "\(coords.latitude)"
        lngLabel.text = "\(coords.longitude)"
        
        // Get location accuracy in meters and convert to feet
        let meterAccuracy = manager.location!.horizontalAccuracy
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
            popValidationAlert(errors.joinWithSeparator("\n"))
            return false
        } else {
            return true
        }
    }
    
    func popValidationAlert(text:String) {
        let alertController = UIAlertController(title: "Missing Data",
            message: text,
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(okAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // User tapped save button
    @IBAction func saveButtonTapped(sender: AnyObject) {
        
        // Validate
        if validateData() == false {
            return
        }
        
        
        
        // Save marker in core data
        editMarker!.saveInCore()
        
        // Stop location data
        locationManager.stopUpdatingLocation()
        
        // Add marker to map view
        let mvc = navigationController?.viewControllers.first as! MapViewController
        mvc.markerToAdd = editMarker
        
        // Move back to map view
        navigationController?.popToRootViewControllerAnimated(true)
        
        print("Saved.")
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
