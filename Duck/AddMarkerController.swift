//
//  AddMarkerController.swift
//  Duck
//
//  Created by Charlie Blevins on 10/3/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//
// This is the marker builder page.
// This page is used to build a marker including an icon and photo

import UIKit

class AddMarkerController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var PhotoSection: UIView!
    @IBOutlet weak var TextSection: UIView!
    
    @IBOutlet weak var cameraPhoto: UIImageView!
    @IBOutlet weak var addPhotoBtn: UIButton!
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Marker"
        print("AddPhotoMarkerController view loaded")
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // Add styles
        self.stylePhotoSection()
        self.addBottomBorder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stylePhotoSection () {
        //PhotoSection.layer.borderColor = UIColor.darkGrayColor().CGColor
        //PhotoSection.layer.borderWidth = 2
    }
    
    func addBottomBorder () {
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0.0, y: PhotoSection.frame.height - 1, width: PhotoSection.frame.size.width, height: 1.0)
        bottomBorder.backgroundColor = UIColor.blackColor().CGColor
        PhotoSection.layer.addSublayer(bottomBorder)
    }
    
    // Load camera to take photo
    @IBAction func addPhoto(sender: UIButton) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .Camera
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // Display taken photo
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            cameraPhoto.contentMode = .ScaleAspectFit
            cameraPhoto.image = pickedImage
            cameraPhoto.layer.masksToBounds = true
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
