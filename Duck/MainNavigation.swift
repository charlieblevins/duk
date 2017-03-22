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
    
    // Trim the underlying stack to maintain only the types in desired_stack. Re-orders remaining types to match
    // desired stack order
    func trimUnderlyingStack (_ desired_stack: [UIViewController.Type]) {
        //var desired_mutable = desired_stack
        
        if desired_stack.count == 0 {
            return
        }
        
        // Remove undesired types
        for (i, controller) in self.viewControllers.enumerated() {
            
            let controller_is_desired = desired_stack.contains(where: { type in
                controller.isKind(of: type)
            })
            
            if !controller_is_desired {
                self.viewControllers.remove(at: i)
            }
        }
        
        // Re-order
        self.viewControllers.sort(by: { a, b in
            let desired_a = desired_stack.index(where: { type in
                a.isKind(of: type)
            })
            let desired_b = desired_stack.index(where: { type in
                b.isKind(of: type)
            })
            
            return desired_a! < desired_b!
        })
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
