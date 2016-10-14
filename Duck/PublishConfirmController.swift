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
    var pending_publish: Dictionary<String, Any>? { get set }
}

class PublishConfirmController: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cautionBtn: UIButton!
    
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
            
            let tags = markerData!.tags
            tagLabel.text = tags
            
            let imageData: Data = markerData!.photo! as Data
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage(data: imageData)
        }
        
        cautionBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -10)
        //cautionBtn.imageEdgeInsets = UIEdgeInsetsMake(0, (cautionBtn.imageView?.frame.size.width)!, 0, -(cautionBtn.imageView?.frame.size.width)!)
        
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
    }
    
    @IBAction func publishMarker(_ sender: AnyObject) {
        
        // Pass data to delegate
        // pending_publish should already be a dictionary containing a table indexpath
        if self.delegate != nil && self.markerData != nil && self.delegate!.pending_publish != nil {

            self.delegate!.pending_publish!["marker"] = self.markerData!
        }
        
        // Back to my markers
        for controller in (self.navigationController?.viewControllers)! {
            if controller.isKind(of: MyMarkersController.self) {
                self.navigationController?.popToViewController(controller, animated: true)
                break;
            }
        }
        //self.navigationController?.popViewControllerAnimated(true)
    }

}







