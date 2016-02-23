//
//  PublishConfirmController.swift
//  Duck
//
//  Created by Charlie Blevins on 2/2/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class PublishConfirmController: UIViewController, UIPopoverPresentationControllerDelegate, PopOverDateDelegate, ApiRequestDelegate {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var markerData: AnyObject? = nil
    var loginData: AnyObject? = nil
    
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

        // Update UI to show newly chosen time
        if let chosen = chosenTime {
            dateLabel.text = chosen
        }
    }
    
    func publishSuccess () {
        print("successful publish")
    }
    
    func publishFail (message: String?) {
        print("publish failed")
        if message != nil {
            print(message)
        }
    }
    
    @IBAction func publishMarker(sender: AnyObject) {
        guard self.markerData != nil else {
            print("marker data not present.")
            return
        }
        
        guard self.loginData != nil else {
            print("credentials not present.")
            return
        }
        
        let marker = Marker(fromCoreData: self.markerData!)
        let credentials = Credentials(fromCoreData: self.loginData!)
        
        let request = ApiRequest()
        request.delegate = self
        request.publishSingleMarker(credentials, marker: marker, successHandler: publishSuccess, failureHandler: publishFail)
    }
    
    
    // MARK: upload delegate method handlers
    
    // Show upload began
    func uploadDidStart() {
        publishBtn.selected = true
    }
    
    // Show progress
    func uploadDidProgress(progress: Float) {
        print(progress)
        progressView.setProgress(progress, animated: true)
    }
    
    // Save new data to core data
    func uploadDidComplete(data: NSDictionary) {
        print("upload complete")
    }
    
    func uploadDidFail(error: ErrorType) {
        print("upload failure")
        let err_msg = (error as NSError).userInfo["NSLocalizedDescription"] as! String
        print(err_msg)
    }
}







