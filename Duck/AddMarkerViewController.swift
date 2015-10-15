//
//  AddMarkerViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 9/30/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//
// This is where the user chooses whether to add a "Marker" or a "Path"

import UIKit

class AddMarkerViewController: UIViewController {
    
    @IBOutlet weak var addMarker: UIButton!
    @IBOutlet weak var addPath: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Marker Type"

        print("Loaded add marker view...")
        
        // Button Actions
        addMarker.addTarget(self, action: "addMarker:", forControlEvents: UIControlEvents.TouchUpInside)
        addPath.addTarget(self, action: "addPathMarker:", forControlEvents: UIControlEvents.TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Add Photo Marker
    func addMarker(sender: UIButton!) {
        goToSubMarkerView("AddMarkerController")
    }
    
    // Add Path
    func addPathMarker(sender: UIButton!) {
        goToSubMarkerView("AddPathController")
    }

    // Go to a specific marker subview by controller name (string)
    func goToSubMarkerView(controller: String) {
        print("moving to view: " + controller)
        let newViewController = self.storyboard!.instantiateViewControllerWithIdentifier(controller)
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
}
