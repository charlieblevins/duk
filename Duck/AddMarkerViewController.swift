//
//  AddMarkerViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 9/30/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import UIKit

class AddMarkerViewController: UIViewController {

    @IBOutlet weak var IconMarker: UIButton!
    @IBOutlet weak var PhotoMarker: UIButton!
    @IBOutlet weak var PathMarker: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add A Marker"

        print("Loaded add marker view...")
        
        IconMarker.addTarget(self, action: "addIconMarker:", forControlEvents: UIControlEvents.TouchUpInside)
        PhotoMarker.addTarget(self, action: "addPhotoMarker:", forControlEvents: UIControlEvents.TouchUpInside)
        PathMarker.addTarget(self, action: "addPathMarker:", forControlEvents: UIControlEvents.TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addIconMarker(sender: UIButton!) {
        print("addIconMarker...")
        
        let AddIconMarkerController = self.storyboard!.instantiateViewControllerWithIdentifier("AddIconMarkerController")
        self.navigationController?.pushViewController(AddIconMarkerController, animated: true)
    }
    
    func addPhotoMarker(sender: UIButton!) {
        print("addPhotoMarker...")
        
        let AddPhotoMarkerController = self.storyboard!.instantiateViewControllerWithIdentifier("AddPhotoMarkerController")
        self.navigationController?.pushViewController(AddPhotoMarkerController, animated: true)
    }
    
    func addPathMarker(sender: UIButton!) {
        print("addPathMarker...")
        
        let AddPathController = self.storyboard!.instantiateViewControllerWithIdentifier("AddPathController")
        self.navigationController?.pushViewController(AddPathController, animated: true)
    }

}
