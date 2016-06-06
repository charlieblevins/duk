//
//  AddMarkerController.swift
//  Duck
//
//  Created by Charlie Blevins on 10/3/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//
// This is the marker builder page.
// This page is used to build a marker including an icon and photo

import CoreData
import CoreLocation
import UIKit

class AddMarkerController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, ZoomableImageDelegate, EditNounDelegate {
    
    @IBOutlet weak var LatContainer: UIView!
    @IBOutlet weak var LngContainer: UIView!
    @IBOutlet weak var AccContainer: UIView!
    @IBOutlet weak var accLabel: UILabel!
    @IBOutlet weak var lngLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoSectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var PhotoSection: UIView!
    @IBOutlet weak var DoneBtn: UIButton!
    @IBOutlet weak var addPhotoBtn: UIButton!
    @IBOutlet weak var cameraPhoto: ZoomableImageView!
    @IBOutlet weak var NounText: UILabel!
    @IBOutlet weak var EditNoun: UIButton!
    @IBOutlet weak var MarkerIcon: UIImageView!
    @IBOutlet weak var IconIndicator: UIActivityIndicatorView!

    @IBOutlet weak var DoneView: UIView!
    
    var imagePicker: UIImagePickerController!
    var imageChosen: Bool = false
    var iconModel: IconModel!
    var autocompleteView: UIView! = nil
    var autocomplete: Autocomplete!

    var tagBubbles: UIView! = nil
    var locationManager: CLLocationManager!
    var coords: CLLocationCoordinate2D!
    var photoCoords: CLLocationCoordinate2D!
    
    var updateNounsOnAppear: Bool = false

    // Marker data passed in from 
    // other view
    var editMarker: Marker? = nil



    override func viewDidLoad() {

        super.viewDidLoad()

        
        
        // Last minute styles
        addStyles()
        
        // Receive gps coords
        // only if not editing already existing marker
        if editMarker == nil {
            
            self.title = "Add Marker"
            
            listenForCoords()
            
        // Insert existing marker data into view
        } else {
            
            self.title = "Edit Marker"
            
            insertExistingData(editMarker!)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if self.updateNounsOnAppear && editMarker != nil {
            updateNouns(editMarker!.tags)
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
    
    // Refresh UI display of Nouns
    // including icon
    func updateNouns (nounString: String) {
        
        var primaryNoun: String? = nil
        
        // Reset flag
        updateNounsOnAppear = false
        
        // Create bold style attr
        let dynamic_size = UIFont.preferredFontForTextStyle(UIFontTextStyleBody).pointSize
        let bold_attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(dynamic_size)]
        var attributedString = NSMutableAttributedString(string: "")
        
        // More than one noun - bold the first
        if let space_range = nounString.rangeOfString(" ") {
            
            primaryNoun = nounString.substringToIndex((space_range.startIndex))
            
            attributedString = NSMutableAttributedString(string: primaryNoun!, attributes: bold_attrs)
            
            // Make attr string from remaining string
            let remaining_nouns = NSMutableAttributedString(string: " \(nounString.substringFromIndex((space_range.endIndex)))")
            
            // Concat first noun with remaining nouns
            attributedString.appendAttributedString(remaining_nouns)
            
        // No space - assume single tag
        } else {
            primaryNoun = nounString
            attributedString = NSMutableAttributedString(string: nounString, attributes: bold_attrs)
        }
        
        NounText.attributedText = attributedString
        
        setIconForNoun(primaryNoun!)
    }
    
    // Get icon for primary noun
    func setIconForNoun (noun: String) {
        Util.loadIconImage(noun, imageView: self.MarkerIcon, activitIndicator: self.IconIndicator)
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
        latLabel.text = "\(marker.latitude)"
        lngLabel.text = "\(marker.longitude)"
        accLabel.text = "N/A"
        
        // Update noun display and icon
        updateNouns(marker.tags)
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

            // Associate latest coords with this photo
            photoCoords = coords
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Edit Noun action - Loads noun editor view (NounViewController)
    @IBAction func EditNoun(sender: AnyObject) {
        print("Loading NounViewController")
        
        let nounViewController = self.storyboard!.instantiateViewControllerWithIdentifier("NounViewController") as! NounViewController
        nounViewController.delegate = self
        
        if editMarker != nil {
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
        
        if imageChosen == false {
            errors.append("Please add a photo (required).")
        }
        
        if tagBubbles == nil || tagBubbles.subviews.count < 1 {
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
    
    @IBAction func doneAddingMarker(sender: UIButton) {
        
        // Validate
        if validateData() == false {
            return
        }
        
        // Save in core data
        
        // 1. Get managed object context
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        // 2. Create new object as marker entity
        let entity = NSEntityDescription.entityForName("Marker", inManagedObjectContext:managedContext)
        let marker = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        // 3. Add data to marker object (and validate)
        let timestamp = NSDate().timeIntervalSince1970
        marker.setValue(timestamp, forKey: "timestamp")
        
        let latitude = Double(photoCoords.latitude)
        marker.setValue(latitude, forKey:"latitude")
        
        let longitude = Double(photoCoords.longitude)
        marker.setValue(longitude, forKey:"longitude")
        
        // Create space separated string of tags
        var tagString: String = ""
        for tagButton in tagBubbles.subviews {
            let casted = tagButton as! UIButton
            tagString += casted.titleLabel!.text! + " "
        }
        tagString = tagString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        marker.setValue(tagString, forKey: "tags")
        
        // Save image as binary
        let imageData = UIImageJPEGRepresentation(cameraPhoto.image!, 1)
        marker.setValue(imageData, forKey: "photo")
        
        // Make small and medium image versions
        let sm = UIImageJPEGRepresentation(Util.resizeImage(cameraPhoto.image!, scaledToFillSize: CGSizeMake(80, 80)), 1)
        marker.setValue(sm, forKey: "photo_sm")
        
        let md = UIImageJPEGRepresentation(Util.resizeImage(cameraPhoto.image!, scaledToFillSize: CGSizeMake(240, 240)), 1)
        marker.setValue(md, forKey: "photo_md")
        
        // 4. Save the marker object
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        // Add marker to map view
        let mvc = navigationController?.viewControllers.first as! MapViewController
        mvc.markerToAdd.append(latitude)
        mvc.markerToAdd.append(longitude)
        mvc.markerToAdd.append(timestamp)
        mvc.markerToAdd.append(tagString)
        
        // Location updates no longer needed. Ensures location is only captured at moment of photo capture
        locationManager.stopUpdatingLocation()
        
        // Move back to map view
        navigationController?.popToRootViewControllerAnimated(true)
        
        print("Done.")
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
