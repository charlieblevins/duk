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

class AddMarkerController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AutocompleteDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoSectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var PhotoSection: UIView!
    @IBOutlet weak var DoneBtn: UIButton!
    @IBOutlet weak var TagField: UITextField!
    @IBOutlet weak var TextSection: UIView!
    @IBOutlet weak var textSectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addPhotoBtn: UIButton!
    @IBOutlet weak var cameraPhoto: UIImageView!
    @IBOutlet weak var TagFieldYConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagAddWrapView: UIView!
    @IBOutlet weak var tagAddBtn: UIButton!

    @IBOutlet weak var DoneView: UIView!
    
    var imagePicker: UIImagePickerController!
    var imageChosen: Bool = false
    var iconModel: IconModel!
    var autocompleteView: UIView! = nil
    var autocomplete: Autocomplete!

    var tagBubbles: UIView! = nil
    var initialTextSectionHeight: CGFloat!
    var locationManager: CLLocationManager!
    var coords: CLLocationCoordinate2D!

    
    override func viewDidLoad() {

        super.viewDidLoad()


        self.title = "Add Marker"

        print("AddPhotoMarkerController view loaded")

        // Store height pre-autocomplete
        initialTextSectionHeight = textSectionHeightConstraint.constant

        // Add event handler for keyboard display
        registerForKeyboardNotifications()
    
        // Respond to text change events
        TagField.addTarget(self, action: "tagFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        // Center text field content
        TagField.textAlignment = .Center
        
        // Handle tap on Add btn
        tagAddBtn.addTarget(self, action: "suggestionChosen:", forControlEvents: .TouchUpInside)
        
        // Tap to dismiss keyboard
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Adjust height of container and scroll views according to subview height
        let heightOfSubviews = PhotoSection.frame.size.height + TextSection.frame.size.height + DoneView.frame.size.height
        containerViewHeightConstraint.constant = heightOfSubviews
        scrollView.contentSize = CGSize(width: containerView.frame.size.width, height: containerView.frame.size.height)
    }
    
    override func viewDidAppear(animated: Bool) {
        // Add styles
        self.stylePhotoSection()
        self.addBottomBorder(PhotoSection)
        //self.addBottomBorder(TextSection)
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func stylePhotoSection () {
        //PhotoSection.layer.borderColor = UIColor.darkGrayColor().CGColor
        //PhotoSection.layer.borderWidth = 2
    }
    
    // Adds a bottom border element at position of element
    func addBottomBorder (section: UIView) {
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0.0, y: section.frame.height - 1, width: section.frame.size.width, height: 1.0)
        bottomBorder.backgroundColor = UIColor.blackColor().CGColor
        section.layer.addSublayer(bottomBorder)
    }
    
    // Load camera to take photo
    @IBAction func addPhoto(sender: UIButton) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .Camera
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // Display taken photo AND
    // get current location coords
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            cameraPhoto.contentMode = .ScaleAspectFit
            cameraPhoto.image = pickedImage
            imageChosen = true
            
            // Grab location coords
            if locationManager == nil {
                locationManager = CLLocationManager()
                
                if CLLocationManager.locationServicesEnabled() {
                    locationManager.delegate = self
                    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                } else {
                    print("location services not enabled. Could not get location!")
                    return
                }
            }
            
            locationManager.startUpdatingLocation()
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Only save location if associated with taking a photo
        coords = manager.location!.coordinate
        print("locations = \(coords.latitude) \(coords.longitude)")
        
        // Location updates no longer needed. Ensures location is only captured at moment of photo capture
        locationManager.stopUpdatingLocation()
    }
    
    // Handle Keyboard show/hide
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(aNotification: NSNotification) {
        let scrollPoint: CGPoint = CGPointMake(0.0, self.TextSection.frame.origin.y)
                    print(scrollPoint)
        self.scrollView.setContentOffset(scrollPoint, animated: false)
    }
    
    func keyboardWasShown(aNotification: NSNotification) {
        var info = aNotification.userInfo
        let kbSize: CGSize = info![UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)

        var aRect: CGRect = self.view.frame
        aRect.size.height -= kbSize.height
        if !CGRectContainsPoint(aRect, TagField.frame.origin) {
            
            // NEED to wait until contentoffset animation is complete before doing these
            self.scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }
    
    func keyboardWillBeHidden(aNotification: NSNotification) {
        let contentInsets: UIEdgeInsets = UIEdgeInsetsZero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func tagFieldDidChange (sender: UITextField) {
        
        // Get autocomplete suggestions
        if (autocomplete == nil) {
            autocomplete = Autocomplete()
            autocomplete.delegate = self
            
            // Set autocomplete item sizes to match text field
            autocomplete.itemWidth = sender.frame.size.width
            autocomplete.itemHeight = sender.frame.size.height
        }
        
        autocompleteView = autocomplete.suggest(sender.text!)
        
        if (autocompleteView != nil) {
            
            // Make room in text container
            textSectionHeightConstraint.constant = initialTextSectionHeight + autocompleteView.frame.height
            
            TextSection.addSubview(autocompleteView)

            autocompleteView!.frame.origin.x = sender.superview!.frame.origin.x
            autocompleteView!.frame.origin.y = sender.superview!.frame.origin.y + sender.frame.size.height
        }
    }
    
    func willChooseTag(autocomplete: Autocomplete, tag: UIButton) {
        suggestionChosen(tag)
    }
    
    // Autocomplete suggestion tapped
    func suggestionChosen(sender:UIButton!) {
        
        print("suggestion chosen")
        // Hide autocomplete
        if autocompleteView != nil {
            autocompleteView!.removeFromSuperview()
            autocompleteView = nil
        }
        
        // Create tag bubble view
        let tagHeight = 30
        if tagBubbles === nil {
            let tbFrame = CGRect(x: tagAddWrapView.frame.origin.x, y: tagAddWrapView.frame.origin.y + 50, width: tagAddWrapView.frame.size.width, height: CGFloat(tagHeight))
            tagBubbles = UIView(frame: tbFrame)
            
            // Display new tag bubble
            TextSection.addSubview(tagBubbles)
        }
        
        // If Add was tapped, use text field value, otherwise use the autocomplete button's title
        let tagBubble = UIButton(frame: CGRect(x: 0, y: tagBubbles.subviews.count * tagHeight, width: Int(tagAddWrapView.frame.size.width), height: tagHeight))
        
        // Custom tag
        if sender.currentTitle! == "Add +" {
            
            tagBubble.setTitle("#" + TagField.text!, forState: .Normal)
            
        // Autocomplete tag
        } else {
            
            tagBubble.setTitle("#" + sender.currentTitle!, forState: .Normal)
            tagBubble.setTitleColor(UIColor.blackColor(), forState: .Normal)
            tagBubble.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
            tagBubble.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            tagBubble.setImage(sender.imageView?.image, forState: .Normal)
            
        }

        tagBubbles.addSubview(tagBubble)
        
        // Update height of text section
        textSectionHeightConstraint.constant = 150 + CGFloat(tagBubbles.subviews.count * tagHeight)
        
        // Clear text field
        TagField.text = nil
    }
    
    // Add Marker Done Action
    @IBAction func DoneBuildingMarker(sender: UIButton) {
        if TagField.text != nil {
            print(TagField.text!)
        }
        
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
        marker.setValue(Double(coords.latitude), forKey:"latitude")
        marker.setValue(Double(coords.longitude), forKey:"longitude")
        
        // Create space separated list for tags
        for tagButton in tagBubbles.subviews {
            let casted = tagButton as! UIButton
            print(casted)
        }
        
        // Save image as binary
        let imageData = UIImageJPEGRepresentation(cameraPhoto.image!, 1)
        marker.setValue(imageData, forKey: "photo")
        
        // 4. Save the marker object
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        print("Done.")
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
    
    func fetchCoreData () {
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Marker")
        
        //3
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            print(results)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
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
