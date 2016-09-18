//
//  MainNavigation.swift
//  Duck
//
//  Created by Charlie Blevins on 10/1/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import UIKit

extension UINavigationController {
    func popViewControllerWithHandler(_ completion: @escaping ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popViewController(animated: true)
        CATransaction.commit()
    }
    func pushViewController(_ viewController: UIViewController, completion: @escaping ()->()) {
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
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        
        if let visibleView = self.visibleViewController {
            return visibleView.supportedInterfaceOrientations
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
}



// Explicitly override method to prevent following error:
// "UIAlertController:supportedInterfaceOrientations was invoked recursively!"
extension UIAlertController {
    open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    open override var shouldAutorotate : Bool {
        return false
    }
}
