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
        var markers_wrapper: MarkersWrapperController? = nil
        var add_my_markers = true
        
        // Back to my markers, if my markers is in hierarchy
        for controller in (self.navigationController?.viewControllers)! {
            if controller.isKind(of: MarkersWrapperController.self) {
                markers_wrapper = controller as? MarkersWrapperController
                add_my_markers = false
                break
            }
        }
        
        // no markers controller in stack, make one
        if markers_wrapper == nil {
            
            // add my markers view to stack
            markers_wrapper = self.storyboard!.instantiateViewController(withIdentifier: "MarkersWrapperController") as? MarkersWrapperController
        }
        
        guard let final_controller = markers_wrapper else {
            print("Error: unable to find or create markers controller")
            return
        }
        
        guard let my_markers = final_controller.table as? MyMarkersController else {
            print("Error: MarkersWrapper did not have mymarkers child controller")
            return
        }
        
        // Pass data to delegate
        // pending_publish should already be a dictionary containing a table indexpath
        guard let marker = self.markerData else {
            print("Error: markerData is nil in publishMarker")
            return
        }
        my_markers.pending_publish["marker"] = marker
        
        if add_my_markers {
            self.navigationController?.pushViewController(final_controller, animated: true)
        }
        
        // remove this view from stack
        let ind = self.navigationController?.viewControllers.index(where: {
            $0.isKind(of: PublishConfirmController.self)
        })
        if let i = ind {
            self.navigationController?.viewControllers.remove(at: i)
        }
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







