//
//  MainNavigation.swift
//  Duck
//
//  Created by Charlie Blevins on 10/1/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import UIKit

class MainNavigation: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loaded Main Navigation...")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        
        if let visibleView = self.visibleViewController {
            return visibleView.supportedInterfaceOrientations()
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
}