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

class AddMarkerController: UIViewController {

    @IBOutlet weak var IconSection: UIView!
    @IBOutlet weak var PhotoSection: UIView!
    @IBOutlet weak var TextSection: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Marker"
        print("AddPhotoMarkerController view loaded")
        // Do any additional setup after loading the view.
        
        // Add styles
        self.stylePhotoSection()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stylePhotoSection () {
        PhotoSection.layer.borderColor = UIColor.darkGrayColor().CGColor
        PhotoSection.layer.borderWidth = 2
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
