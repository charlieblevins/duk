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
    @IBOutlet weak var locationField: UISearchField!

    var parentController: MapViewController? = nil
    
    var noun: String? = nil
    var coord: CLLocationCoordinate2D? = nil
    
    // Add gestures when this view is added to it's parent
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.userInteractionEnabled = true
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nounsTapped)))
        
        nounsField.text = "Anything"
        nounsField.delegate = self
        
        locationField.text = "My Location"
        locationField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        addTap(self.nounsField, action: #selector(nounsTapped))
        addTap(self.locationField, action: #selector(locationTapped))
        
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
    }

    func locationTapped () {
        print("location tapped")
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        if textField == nounsField {
            
            if textField.text == "" {
                textField.text = "Anything"
            }
            
        } else if textField == locationField {
            
            if textField.text == "" {
                textField.text = "My Location"
            }
        }
    }
    
    @IBAction func backTapped(sender: AnyObject) {
        self.removeFromParentViewController()
    }
    
    @IBAction func searchTapped(sender: AnyObject) {
        print("search tapped")
        
        self.noun = self.nounsField.text
        
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
        
        let marker_aggregator = MarkerAggregator()
        marker_aggregator.delegate = self.parentController!
        marker_aggregator.loadNearPoint(point!, noun: self.noun);
    }
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        
        self.locationField.text = place.formattedAddress
        
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

