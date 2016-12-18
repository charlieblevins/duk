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
        
        self.view.isUserInteractionEnabled = true
        
        // Name tabs
        myLocation.name = "my_location"
        thisArea.name = "this_area"
        address.name = "address"
        
        // Respond to taps
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nounsTapped)))
        
        nounsField.placeholder = nounPL
        nounsField.delegate = self
        
        // Set initial selection
        myLocation.isSelected = true
        
        // Register tab buttons as a group
        tabGroup = [myLocation, thisArea, address]
        
        // Set underline as selected state for tabs
        setTabUnderline()
        
        // Hide address field
        self.addressField.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        addTap(self.nounsField, action: #selector(nounsTapped))
        addTap(self.addressField, action: #selector(loadPlacesPicker))
    }
    
    // Add tap recognizer to a subview
    func addTap (_ view: UIView, action: Selector) {
        
        // Even though IB says this is already true, it isn't
        view.isUserInteractionEnabled = true
        
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
    @IBAction func myLocationTapped(_ sender: UIButton) {
        nearTabTapped(sender)
        hideAddressField()
    }
    
    @IBAction func thisAreaTapped(_ sender: UIButton) {
        nearTabTapped(sender)
        hideAddressField()
    }
    
    @IBAction func addressTapped(_ sender: UIButton) {
        loadPlacesPicker()
    }
    
    func loadPlacesPicker () {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.present(autocompleteController, animated: true, completion: nil)
    }
    
    func nearTabTapped (_ button: UIButton) {
        print("\(button.currentTitle) tapped")
        
        guard let tappedBtn = button as? UIButtonTab else {
            print("Could not convert button to UIButtonTab")
            return
        }
        
        // Set highlighted state for all tabs
        for tab in tabGroup {
            tab.isSelected = (tab == tappedBtn) ? true : false
        }
    }
    
    func setTabUnderline() {
        for tab in tabGroup {
            let attributes = [
                NSForegroundColorAttributeName : UIColor.white,
                NSUnderlineStyleAttributeName : NSUnderlineStyle.styleSingle.rawValue
            ] as [String : Any]
            
            tab.setAttributedTitle(NSAttributedString(string: tab.currentAttributedTitle!.string, attributes: attributes), for: UIControlState.selected)
        }
    }
    
    // Hide address field and resize container to fit
    func hideAddressField () {
        
        if (!self.addressField.isHidden) {
            self.addressField.isHidden = true
            
            // Subtract address field height from container
            containerHeight.constant -= addressField.frame.height
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == nounsField {
            
            if textField.text == "" {
                textField.placeholder = nounPL
            }
            
        }
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }
    
    @IBAction func searchTapped(_ sender: AnyObject) {
        print("search tapped")
        
        self.noun = (self.nounsField.text != "") ? self.nounsField.text : nil
        
        var point: CLLocationCoordinate2D? = nil
        var search_type: SearchType? = nil
        
        // Get tab name
        guard let tab_index = tabGroup.index(where: { $0.isSelected }) else {
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
            
            search_type = .thisArea
            
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
            search_type = .myLocation
            
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
            search_type = .address
            
        } else {
            print("unrecognized tab_name")
            return
        }

        // Search near point
        marker_aggregator.loadNearPoint(point!, noun: self.noun, searchType: search_type!);
    }
    
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress as Any)
        
        self.addressField.text = place.formattedAddress
        
        self.addressField.isSelected = true
        
        self.coord = place.coordinate
        
        // Show address field
        if (self.addressField.isHidden) {
            self.addressField.isHidden = false
            containerHeight.constant += addressField.frame.height
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

// Subclass with 5 left/right padding
class UISearchField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}

class UIButtonTab: UIButton {
    
    var name: String? = nil
}

enum SearchType: Int {
    case myLocation, address, thisArea
}

