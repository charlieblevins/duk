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
    var timeFromDayPicker: String?
    
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
        progressView.setProgress(progress, animated: true)
    }
    
    // Save new data to core data
    func uploadDidComplete(data: NSDictionary) {
        print("upload complete")
    }
    
    // Show alert on failure
    func uploadDidFail(error: String) {
        
        print("upload failure")
        
        // Reset publish button and progress bar
        publishBtn.selected = false
        progressView.setProgress(0.0, animated: false)
        
        // Pop alert with error message
        popFailAlert(error)
    }
    
    func popFailAlert(text:String) {
        let alertController = UIAlertController(title: "Upload Failure",
            message: text,
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
}







