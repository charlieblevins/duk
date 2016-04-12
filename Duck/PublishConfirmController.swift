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

class PublishConfirmController: UIViewController, UIPopoverPresentationControllerDelegate, PopOverDateDelegate {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var markerData: AnyObject? = nil
    var loginData: AnyObject? = nil
    var timeFromDayPicker: String?
    var request: ApiRequest? = nil
    
    var delegate: PublishSuccessDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Publish Marker"
        
        // Define uploading state for publish btn
        publishBtn.setTitle("Uploading...", forState: .Selected)
        
        progressView.setProgress(0.0, animated: true)
        
        // Populate marker data in view
        if markerData !== nil {
            
            let tags = markerData!.valueForKey("tags") as! String
            tagLabel.text = tags
            
            let imageData: NSData = markerData!.valueForKey("photo") as! NSData
            imageView.contentMode = .ScaleAspectFit
            imageView.image = UIImage(data: imageData)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    // Restrict to potrait view only
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    @IBAction func ChangeDateAction(sender: UIButton) {
        
        // Present PopOverDate in modal view
        let popOverDate = PopOverDate()
        
        // If a future date has already been chosen
        // send it back as the default
        if timeFromDayPicker != nil {
            popOverDate.choice = timeFromDayPicker
        }
        
        // Define delegate for my custom view within popover
        popOverDate.delegate = self
        
        // Show view as popover
        popOverDate.modalPresentationStyle = .Popover
        if let popover = popOverDate.popoverPresentationController {
            
            // Define delegate for popover controller
            popover.delegate = self
            
            // Define size of popover
            popover.sourceRect = CGRect(
                x: 0,
                y: 0,
                width: 100,
                height: 100)
            popover.sourceView = sender
        }
        
        self.presentViewController(popOverDate, animated: true, completion: nil)
    }
    
    // Receive data message from PopOverDate controller
    func savePublishDate(chosenTime: String?) {

        timeFromDayPicker = chosenTime
        
        // Update UI to show newly chosen time
        if timeFromDayPicker != nil {
            dateLabel.text = timeFromDayPicker
        }
    }
    
    @IBAction func publishMarker(sender: AnyObject) {
        
        // Pass data to delegate
        if self.delegate != nil && self.markerData != nil && self.loginData != nil {

            self.delegate!.pending_publish = Dictionary()
            self.delegate!.pending_publish!["marker"] = Marker(fromCoreData: self.markerData!)
            self.delegate!.pending_publish!["credentials"] = Credentials(fromCoreData: self.loginData!)
        }
        
        // Back to my markers
        self.navigationController?.popViewControllerAnimated(true)
    }

    
//    
//    // Show upload began
//    func uploadDidStart() {
//        publishBtn.selected = true
//        
//        if self.delegate != nil {
//            
//            guard markerData != nil else {
//                print("Could not get timestamp from marker data")
//                return
//            }
//            
//            backToMyMarkers()
//        
//            let timestamp = self.markerData!.valueForKey("timestamp") as! Double
//            
//            // Pass timestamp and request instance back to my markers
//            if self.delegate!.pending_publish != nil {
//                self.delegate!.pending_publish!["request"] = self.request!
//                self.delegate!.pending_publish!["timestamp"] = timestamp
//            }
//        }
//    }
    
//    func uploadDidProgress(progress: Float) {
//        
//    }
//    
//    func uploadDidComplete(data: NSDictionary) {
//        
//    }
//    
//    func uploadDidFail(error: String) {
//        
//    }
//    

}







