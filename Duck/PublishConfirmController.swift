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

    @IBOutlet weak var markerDataView: UIView!
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







