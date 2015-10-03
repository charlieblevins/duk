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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add A Marker"

        print("Loaded add marker view...")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
