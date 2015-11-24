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

class AddMarkerController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AutocompleteDelegate {

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
    var iconModel: IconModel!
    var autocompleteView: UIView! = nil
    var autocomplete: Autocomplete!

    var tagBubbles: UIView! = nil
    var initialTextSectionHeight: CGFloat!

    
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
    
    // Display taken photo
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            cameraPhoto.contentMode = .ScaleAspectFit
            cameraPhoto.image = pickedImage
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Handle Keyboard show/hide
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardDidShowNotification, object: nil)
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
    
    func tagFieldDidChange (sender: UITextField) {
        
        // Get autocomplete suggestions
        if (autocomplete == nil) {
            autocomplete = Autocomplete()
            autocomplete.delegate = self
        }
        
        autocompleteView = autocomplete.suggest(sender.text!)
        
        if (autocompleteView != nil) {
            
            // Make room in text container
            textSectionHeightConstraint.constant = initialTextSectionHeight + autocompleteView.frame.height
            
            TextSection.addSubview(autocompleteView)
        }
    }
    
    // Show matching tags as user types
    func tagFieldDidChange2 (sender: UITextField) {
        
//        // Load icon data
//        if iconModel == nil {
//            iconModel = IconModel()
//        }
//        
//        // Store height pre-autocomplete
//        initialTextSectionHeight = textSectionHeightConstraint.constant
//        
//        // Get index of matching icon as user types
//        let matchingIcons: [IconModel.Icon] = iconModel.icons.filter({
//            
//            // Check if icon tag contains typed text
//            let foundString: Range? = $0.tag.rangeOfString(sender.text!)
//            
//            // all characters of typed string match first characters of Icon name
//            if foundString != nil && foundString!.startIndex == sender.text!.startIndex {
//                return true
//            } else {
//                return false
//            }
//        })
//        
//        // Display matching items in dropdown
//        if matchingIcons.count > 0 {
//            // Limit to 5 results
//            
//
//            // Measure amount of space needed
//            let height = CGFloat(matchingIcons.count) * sender.frame.size.height
//            
//            // Build/show autocomplete container
//            if autocomplete === nil {
//                
//                // Make room in text container
//                textSectionHeightConstraint.constant += height
//                
//                let aFrame = CGRect(x: tagAddWrapView.frame.origin.x, y: tagAddWrapView.frame.origin.y + 30, width: sender.frame.size.width, height: height)
//                autocomplete = UIView(frame: aFrame)
//                autocomplete.layer.borderWidth = 1.0
//                autocomplete.layer.borderColor = sender.layer.borderColor
//                TextSection.addSubview(autocomplete)
//        
//            // If autocomplete exists but results have changed
//            } else if autocomplete.frame.height != height {
//                // Adjust text section from original height
//                textSectionHeightConstraint.constant = initialTextSectionHeight + height
//                
//                // Set new autocomplete height
//                autocomplete.frame = CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y + 30, width: sender.frame.size.width, height: height)
//
//                // Clear old results
//                autocomplete.subviews.forEach({ $0.removeFromSuperview() })
//            }
//            
//            // Append suggestions (icon names)
//            let limit = matchingIcons.count
//            for var i = 0; i < limit; ++i {
//                
//                let icon = matchingIcons[i]
//                
//                // Increase y value for each icon
//                let yPos = CGFloat(i) * sender.frame.size.height
//                let iconBtn: UIButton = UIButton(frame: CGRectMake(0, yPos, sender.frame.size.width, sender.frame.size.height))
//                iconBtn.setTitleColor(UIColor.grayColor(), forState: .Normal)
//                iconBtn.setTitle(icon.tag, forState: .Normal)
//                iconBtn.addTarget(self, action: "suggestionChosen:", forControlEvents: .TouchUpInside)
//                autocomplete.addSubview(iconBtn)
//                
//            } // End for loop
//        } else if autocomplete != nil {
//            // No icons were found
//            autocomplete.removeFromSuperview()
//            autocomplete = nil
//            textSectionHeightConstraint.constant = initialTextSectionHeight
//        }
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
            //tagBubbles.layer.backgroundColor = UIColor.redColor().CGColor
            
            // Display new tag bubble
            TextSection.addSubview(tagBubbles)
        }
        
        // If Add was tapped, use text field value, otherwise use the autocomplete button's title
        let tagBubble = UIButton(frame: CGRect(x: 0, y: tagBubbles.subviews.count * tagHeight, width: Int(tagAddWrapView.frame.size.width), height: tagHeight))
        if sender.currentTitle! == "Add +" {
            tagBubble.setTitle("#" + TagField.text!, forState: .Normal)
        } else {
            tagBubble.setTitle("#" + sender.currentTitle!, forState: .Normal)
        }

        tagBubbles.addSubview(tagBubble)
        
        // If this is the first tag, also display the icon
        
        // Update height of text section
        textSectionHeightConstraint.constant = 150 + CGFloat(tagBubbles.subviews.count * tagHeight)
        //containerViewHeightConstraint.constant = CGFloat(tagBubbles.subviews.count * tagHeight)
        
        // Bind an event handler for tag bubble
        
        // Clear text field
        TagField.text = nil
    }
    
    // Add Marker Done Action
    @IBAction func DoneBuildingMarker(sender: UIButton) {
        if TagField.text != nil {
            print(TagField.text!)
        }
        
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
