//
//  SearchViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 7/23/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit
import GooglePlaces

class SearchBox: UIViewController, GMSAutocompleteViewControllerDelegate, UITextFieldDelegate {


    @IBOutlet weak var nounsField: UISearchField!
    @IBOutlet weak var myLocation: UIButtonTab!
    @IBOutlet weak var thisArea: UIButtonTab!
    @IBOutlet weak var address: UIButtonTab!
    @IBOutlet weak var addressField: UISearchField!
    @IBOutlet weak var containerHeight: NSLayoutConstraint!

    var parentController: MapViewController? = nil
    
    var noun: String? = nil
    var coord: CLLocationCoordinate2D? = nil
    
    var nounPL: String? = "(Anything)"
    var locationPL: String? = "(My Location)"
    
    var tabGroup = [UIButtonTab]()

    // Add gestures when this view is added to it's parent
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.userInteractionEnabled = true
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nounsTapped)))
        
        nounsField.placeholder = nounPL
        nounsField.delegate = self
        
        // Register tab buttons as a group
        tabGroup = [myLocation, thisArea, address]
        
        // Set underline as selected state for tabs
        setTabUnderline()
        
        
        // Hide address field
        hideAddressField()
    }
    
    override func viewDidLayoutSubviews() {
        addTap(self.nounsField, action: #selector(nounsTapped))
        
        let location = CGPoint(x: CGFloat(40), y: CGFloat(80))
        let touched = self.view.hitTest(location, withEvent: nil)
        print(touched)
    }
    
    // Add tap recognizer to a subview
    func addTap (view: UIView, action: Selector) {
        
        // Even though IB says this is already true, it isn't
        view.userInteractionEnabled = true
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
    }
    
    // Load Noun Picker
    func nounsTapped () {
        print("nouns tapped")
        self.nounsField.becomeFirstResponder()
        
        // Clear placeholder while editing
        self.nounsField.placeholder = ""
    }

    func locationTapped () {
        print("location tapped")
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }

    // Handle taps on near tabs
    @IBAction func myLocationTapped(sender: UIButton) {
        nearTabTapped(sender)
    }
    
    @IBAction func thisAreaTapped(sender: UIButton) {
        nearTabTapped(sender)
    }
    
    @IBAction func addressTapped(sender: UIButton) {
        nearTabTapped(sender)
    }
    
    func nearTabTapped (button: UIButton) {
        print("\(button.currentTitle) tapped")
        
        guard let tappedBtn = button as? UIButtonTab else {
            print("Could not convert button to UIButtonTab")
            return
        }
        
        // Set highlighted state for all tabs
        for tab in tabGroup {
            tab.selected = (tab == tappedBtn) ? true : false
        }
    }
    
    func setTabUnderline() {
        for tab in tabGroup {
            let attributes = [
                NSForegroundColorAttributeName : UIColor.whiteColor(),
                NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue
            ]
            
            tab.setAttributedTitle(NSAttributedString(string: tab.currentAttributedTitle!.string, attributes: attributes), forState: UIControlState.Selected)
        }
    }
    
    // Hide address field and resize container to fit
    func hideAddressField () {
        self.addressField.hidden = true
        
        // Subtract address field height from container
        containerHeight.constant -= addressField.frame.height
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        if textField == nounsField {
            
            if textField.text == "" {
                textField.placeholder = nounPL
            }
            
        }
    }
    
    @IBAction func closeTapped(sender: UIButton) {
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }
    
    @IBAction func searchTapped(sender: AnyObject) {
        print("search tapped")
        
        self.noun = (self.nounsField.text != "") ? self.nounsField.text : nil
        
        var point: CLLocationCoordinate2D? = nil
        
        // Get coord from entered location or current location
        if self.coord != nil {
            point = self.coord
            
        } else if DistanceTracker.sharedInstance.latestCoord != nil {
            point = DistanceTracker.sharedInstance.latestCoord
            
        } else {
            print("No location is available. Please add one to search")
            return
        }
        
        // Remove focus from nouns field
        self.nounsField.resignFirstResponder()
        
        let marker_aggregator = MarkerAggregator()
        marker_aggregator.delegate = self.parentController!
        marker_aggregator.loadNearPoint(point!, noun: self.noun);
    }
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        
        self.addressField.text = place.formattedAddress
        
        self.coord = place.coordinate
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    // User canceled the operation.
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

// Subclass with 5 left/right padding
class UISearchField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}

class UIButtonTab: UIButton {
    
    // Set state and corresponding styles
    func setHighlight(highlight: Bool) {
        
        if highlight {
            self.selected = true

            
        } else {
            
            // remove underline
//            let title = NSMutableAttributedString()
//            title.appendAttributedString(NSAttributedString(string: self.currentAttributedTitle!.string, attributes: nil))
//            self.setAttributedTitle(title, forState: .Normal)
        }
        
        //self.selected = highlight
    }
}

