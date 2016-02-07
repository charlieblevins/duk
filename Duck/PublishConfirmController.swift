//
//  PublishConfirmController.swift
//  Duck
//
//  Created by Charlie Blevins on 2/2/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class PublishConfirmController: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var markerData: AnyObject? = nil
    var loginData: AnyObject? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Publish Marker"
        
        if markerData !== nil {
            
            // Populate marker data in view
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
    
    
    @IBAction func ChangeDateAction(sender: UIButton) {
        
        // Present PopOverDate in modal view
        let popOverDate = PopOverDate()
        popOverDate.modalPresentationStyle = .Popover
        
        let popover = popOverDate.popoverPresentationController
        //popOverDate.popoverPresentationController.preferredContentSize = CGSizeMake(100, 100)
        popover!.delegate = self

        popover!.sourceRect = CGRect(
            x: 0,
            y: 0,
            width: 1,
            height: 1)
        popover!.sourceView = sender
        
        self.presentViewController(popOverDate, animated: true, completion: nil)
        
    }
}
