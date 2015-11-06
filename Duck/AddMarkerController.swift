//
//  AddMarkerController.swift
//  Duck
//
//  Created by Charlie Blevins on 10/3/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//
// This is the marker builder page.
// This page is used to build a marker including an icon and photo

import UIKit

class AddMarkerController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var PhotoSection: UIView!
    @IBOutlet weak var TextSection: UIView!
    
    @IBOutlet weak var TagField: UITextField!
    @IBOutlet weak var DoneBtn: UIButton!
    
    @IBOutlet weak var PhotoSectionTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cameraPhoto: UIImageView!
    @IBOutlet weak var addPhotoBtn: UIButton!
    @IBOutlet weak var textSectionHeightConstraint: NSLayoutConstraint!
    
    var imagePicker: UIImagePickerController!
    
    var iconModel: IconModel!
    var autocomplete: UIView! = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Marker"
        print("AddPhotoMarkerController view loaded")
        
        // Add event handler for keyboard display
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        
        // Add tap recognizer to close keyboard by tapping anywhere 
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        view.addGestureRecognizer(tap)
        
        // Respond to text change events
        TagField.addTarget(self, action: "tagFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
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
    
    // Display taken photo
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            cameraPhoto.contentMode = .ScaleAspectFit
            cameraPhoto.image = pickedImage
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Adjust view when keyboard is displayed
    func keyboardWillShow(notification: NSNotification) {
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        print("Keyboard shown")
        
        UIView.animateWithDuration(0.1, animations: {
            self.PhotoSectionTopConstraint.constant = 0 - (keyboardFrame.size.height + 20)
        })
        

    }
    
    // Reset view as keyboard hides
    func DismissKeyboard () {
        UIView.animateWithDuration(0.1, animations: {
            self.PhotoSectionTopConstraint.constant = 0
        })
        view.endEditing(true)
    }
    
    // Show matching tags as user types
    func tagFieldDidChange (sender: UITextField) {
        
        // Load icon data
        if iconModel == nil {
            iconModel = IconModel()
        }
        
        // Get index of matching icon as user types
        let matchingIcons: [IconModel.Icon] = iconModel.icons.filter({
            
            // Check if icon tag contains typed text
            let foundString: Range? = $0.tag.rangeOfString(sender.text!)
            
            // all characters of typed string match first characters of Icon name
            if foundString != nil && foundString!.startIndex == sender.text!.startIndex {
                return true
            } else {
                return false
            }
        })
        
        // Display matching items in dropdown
        if matchingIcons.count > 0 {
            // Limit to 5 results
            
            // Measure amount of space needed
            let height = CGFloat(matchingIcons.count) * sender.frame.size.height
            
            // Make room in text container
            textSectionHeightConstraint.constant = height
            
            // Build/show autocomplete container
            if autocomplete === nil {
                let aFrame = CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y + 30, width: sender.frame.size.width, height: height)
                autocomplete = UIView(frame: aFrame)
                autocomplete.layer.borderWidth = 1.0
                autocomplete.layer.borderColor = sender.layer.borderColor
                sender.superview!.addSubview(autocomplete)
        
            // If autocomplete exists but height needs to change
            } else if autocomplete.frame.height != height {
                autocomplete.frame = CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y + 30, width: sender.frame.size.width, height: height)
            }
            
            // Append suggestions (icon names)
            let limit = matchingIcons.count
            for var i = 0; i < limit; ++i {
                
                let icon = matchingIcons[i]
                
                // Increase y value for each icon
                let yPos = CGFloat(i) * sender.frame.size.height
                let iconBtn: UIButton = UIButton(frame: CGRectMake(0, yPos, sender.frame.size.width, sender.frame.size.height))
                iconBtn.setTitleColor(UIColor.grayColor(), forState: .Normal)
                iconBtn.setTitle(icon.tag, forState: .Normal)
                autocomplete.addSubview(iconBtn)
                
            } // End for loop
       
            // Save original frame and add height to account for autocomplete container
            
            //TextSection.frame = CGRect(x: TextSection.frame.origin.x, y: TextSection.frame.origin.x, width: TextSection.frame.size.width, height: TextSection.frame.size.height + height)

            
            // Make suggestion tap-able
            
            // When suggestion tapped, add it to list below
        } else if autocomplete != nil {
            // No icons were found
            autocomplete.removeFromSuperview()
            autocomplete = nil
            textSectionHeightConstraint.constant = 0
        }
    }
    
    @IBAction func DoneBuildingMarker(sender: UIButton) {
        if TagField.text != nil {
            print(TagField.text!)
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
