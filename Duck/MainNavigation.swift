//
//  MainNavigation.swift
//  Duck
//
//  Created by Charlie Blevins on 10/1/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import UIKit

extension UINavigationController {
    func popViewControllerWithHandler(completion: ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popViewControllerAnimated(true)
        CATransaction.commit()
    }
    func pushViewController(viewController: UIViewController, completion: ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.pushViewController(viewController, animated: true)
        CATransaction.commit()
    }
}

class MainNavigation: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loaded Main Navigation...")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

   
    // Restrict orientation for some views
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        
        if let visibleView = self.visibleViewController {
            return visibleView.supportedInterfaceOrientations()
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
}



// Explicitly override method to prevent following error:
// "UIAlertController:supportedInterfaceOrientations was invoked recursively!"
extension UIAlertController {
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    public override func shouldAutorotate() -> Bool {
        return false
    }
}