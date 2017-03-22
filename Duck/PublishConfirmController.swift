//
//  PublishConfirmController.swift
//  Duck
//
//  Created by Charlie Blevins on 2/2/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

protocol PublishSuccessDelegate {
    
    // Set details about a pending request
    var pending_publish: Dictionary<String, Any> { get set }
}

class PublishConfirmController: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var markerDataView: UIView!
    @IBOutlet weak var iconView: MarkerIconView!
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cautionBtn: UIButton!
    @IBOutlet weak var coords: UILabel!
    
    var markerData: Marker? = nil
    var timeFromDayPicker: String?
    var request: ApiRequest? = nil
    
    var delegate: PublishSuccessDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Publish Marker"
        
        // Define uploading state for publish btn
        publishBtn.setTitle("Uploading...", for: .selected)
        
        // Populate marker data in view
        if markerData != nil {
            
            guard let tags = markerData!.tags else {
                print("no tags exist for this marker")
                return
            }
            
            tagLabel.attributedText = Marker.formatNouns(tags)

            // Set marker icon
            iconView.setNoun(Marker.getPrimaryNoun(tags))
            
            // Set coords
            if let lat_lng = markerData!.getCoords() {
               coords.text = lat_lng
            }
            
            let imageData: Data = markerData!.photo! as Data
            imageView.image = UIImage(data: imageData)
            imageView.clipsToBounds = true
        }
        
        styleMarkerView()
        
        styleCaution()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    // Restrict to potrait view only
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    @IBAction func cautionTapped(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "Be Cautious",
                                                message: "Publishing photos of your current location can show the world where you are. If in doubt, wait to publish photos after leaving the location.",
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func publishMarker(_ sender: AnyObject) {
        
        
        
        // Organize the view controller stack for navigation to my markers upload
        // TODO: Move this method to nav controller
        // possible stack states:
        // marker-detail -> pub-confirm :: replace marker-detail with my-markers
        // my-markers -> marker-detail -> pub-confirm :: remove marker-detail
        // my-markers -> pub-confirm :: do nothing
        // should create stack: my-markers -> pub-confirm
        // Loop over views from top to bottom. After top (pub-confirm), remove each view that is NOT
        // my-markers. Stop looping when map-view is reached
        guard let nav = self.navigationController as? MainNavigation else {
            fatalError("Unexpected nav controller type")
        }
        nav.trimUnderlyingStack([MapViewController.self, MarkersWrapperController.self, PublishConfirmController.self])
        
        let stack = nav.viewControllers
        
        // If the middle view is not my-markers it must be created
        if stack[1].isKind(of: MarkersWrapperController.self) == false {
            
            guard let new_wrapper = self.storyboard!.instantiateViewController(withIdentifier: "MarkersWrapperController") as? MarkersWrapperController else {
                fatalError("Could not create MarkersWrapperController from storyboard")
            }
            nav.viewControllers.insert(new_wrapper, at: stack.count - 1)
            
            // Ensure my markers is the active nested table view
            if !new_wrapper.table.isKind(of: MyMarkersController.self) {
                new_wrapper.showMyMarkers()
            }
        }
        
        // Pass data to delegate
        // pending_publish should already be a dictionary containing a table indexpath
        guard let marker = self.markerData else {
            print("Error: markerData is nil in publishMarker")
            return
        }
        
        guard let markers_wrapper = nav.viewControllers[1] as? MarkersWrapperController else {
            fatalError("Expected index 1 to be MarkersWrapper")
        }
        guard let my_markers = markers_wrapper.table as? MyMarkersController else {
            fatalError("Expected wrapper table to be MyMarkers")
        }
        
        my_markers.pending_publish["marker"] = marker

        // navigate to my markers
        nav.popViewController(animated: true)
    }
    
    func styleMarkerView () {
        markerDataView.layer.borderColor = UIColor.gray.cgColor
        markerDataView.layer.borderWidth = 1
        markerDataView.layer.cornerRadius = 5
    }
    
    func styleCaution () {
        
        cautionBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 0)
        cautionBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0)
        
        cautionBtn.layer.borderColor = UIColor(colorLiteralRed: 255/255, green: 86/255, blue: 8/255, alpha: 1).cgColor
    }
}







