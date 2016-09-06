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

    var parentController: MapViewController
    
    var noun: String? = nil
    var coord: CLLocationCoordinate2D? = nil
    
    var nounPL: String? = "(Anything)"
    var locationPL: String? = "(My Location)"
    
    var tabGroup = [UIButtonTab]()
    
    init(_ parent: MapViewController) {
        self.parentController = parent
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not allowed")
    }

    // Add gestures when this view is added to it's parent
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.userInteractionEnabled = true
        
        // Name tabs
        myLocation.name = "my_location"
        thisArea.name = "this_area"
        address.name = "address"
        
        // Respond to taps
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nounsTapped)))
        
        nounsField.placeholder = nounPL
        nounsField.delegate = self
        
        // Set initial selection
        myLocation.selected = true
        
        // Register tab buttons as a group
        tabGroup = [myLocation, thisArea, address]
        
        // Set underline as selected state for tabs
        setTabUnderline()
        
        // Hide address field
        hideAddressField()
    }
    
    override func viewDidLayoutSubviews() {
        addTap(self.nounsField, action: #selector(nounsTapped))
        addTap(self.addressField, action: #selector(loadPlacesPicker))
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

    // Handle taps on near tabs
    @IBAction func myLocationTapped(sender: UIButton) {
        nearTabTapped(sender)
        hideAddressField()
    }
    
    @IBAction func thisAreaTapped(sender: UIButton) {
        nearTabTapped(sender)
        hideAddressField()
    }
    
    @IBAction func addressTapped(sender: UIButton) {
        loadPlacesPicker()
    }
    
    func loadPlacesPicker () {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
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
        
        if (!self.addressField.hidden) {
            self.addressField.hidden = true
            
            // Subtract address field height from container
            containerHeight.constant -= addressField.frame.height
        }
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
        var search_type: SearchType? = nil
        
        // Get tab name
        guard let tab_index = tabGroup.indexOf({ $0.selected }) else {
            print("selected tab not found")
            return
        }
        guard let tab_name = tabGroup[tab_index].name else {
            print("could not find name of tab")
            return
        }
        
        // Create aggregator
        let marker_aggregator = MarkerAggregator()
        marker_aggregator.delegate = self.parentController
        
        // Remove focus from nouns field
        self.nounsField.resignFirstResponder()
        
        // Get bounds for this_area
        if tab_name == "this_area" {
            
            search_type = .ThisArea
            
            // get map current bounds
            let vis_region = self.parentController.mapView.projection.visibleRegion()
            let NE = vis_region.farRight
            let SW = vis_region.nearLeft
            let bounds = GMSCoordinateBounds(coordinate: NE, coordinate: SW)
            marker_aggregator.loadWithinBounds(bounds, page: 1, noun: self.noun)
            return
        }
        
        
        if tab_name == "my_location" {
            
            point = DistanceTracker.sharedInstance.latestCoord
            search_type = .MyLocation
            
            guard point != nil else {
                print("could not get point from distance tracker")
                return
            }
        
        // Get coord set by g places
        } else if tab_name == "address" {
            
            guard self.coord != nil else {
                print("no coord exists")
                return
            }
            
            point = self.coord
            search_type = .Address
            
        } else {
            print("unrecognized tab_name")
            return
        }

        // Search near point
        marker_aggregator.loadNearPoint(point!, noun: self.noun, searchType: search_type!);
    }
    
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        
        self.addressField.text = place.formattedAddress
        
        self.addressField.selected = true
        
        self.coord = place.coordinate
        
        // Show address field
        if (self.addressField.hidden) {
            self.addressField.hidden = false
            containerHeight.constant += addressField.frame.height
        }
        
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
    
    var name: String? = nil
}

enum SearchType: Int {
    case MyLocation, Address, ThisArea
}

