//
//  SearchViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 7/23/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit
import GooglePlaces

class SearchBox: UIViewController, EditNounDelegate, GMSAutocompleteViewControllerDelegate {

    @IBOutlet weak var nounsField: UILabelPl!
    @IBOutlet weak var locationField: UILabelPl!

    var parentController: UIViewController? = nil
    
    // Add gestures when this view is added to it's parent
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.userInteractionEnabled = true
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nounsTapped)))
        
        self.nounsField.placeholder = "Anything"
        self.locationField.placeholder = "Anywhere"
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
        
        let nounViewController = self.parentController!.storyboard!.instantiateViewControllerWithIdentifier("NounViewController") as! NounViewController
        
        // Pass existing nouns if they are no the placeholder
        nounViewController.nounsRaw = (self.nounsField.text != self.nounsField.placeholder) ? self.nounsField.text : nil
        
        nounViewController.delegate = self
        
        // Push view onto stack
        self.parentController!.navigationController?.pushViewController(nounViewController, animated: true)
    }

    func locationTapped () {
        print("location tapped")
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func backTapped(sender: AnyObject) {
        self.removeFromParentViewController()
    }
    
    @IBAction func searchTapped(sender: AnyObject) {
        print("search tapped")
    }
    
    func nounsDidUpdate (nouns: String?) {
        self.nounsField.text = (nouns == nil ? "Anything" : nouns)
    }
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress)
        
        self.locationField.text = place.formattedAddress
        
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


