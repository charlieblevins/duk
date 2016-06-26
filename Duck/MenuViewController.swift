//
//  MenuViewController.swift
//  Duck
//
//  Created by Charlie Blevins on 6/25/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    @IBOutlet weak var MyMarkersView: UIView!
    @IBOutlet weak var myAccountView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("menu view")

        // Handle my markers tap
        self.handleTapOn(MyMarkersView, handler: #selector(self.didTapMyMarkers(_:)))
        
        // Handle my account tap
        self.handleTapOn(myAccountView, handler: #selector(self.didTapMyAccount(_:)))
    }

    func didTapMyAccount (sender: UITapGestureRecognizer) {
        goToView("AccountViewController")
    }
    
    func didTapMyMarkers (sender: UITapGestureRecognizer) {
        goToView("MyMarkersController")
    }
    
    func goToView (controller: String) {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier(controller)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func handleTapOn (section: UIView, handler: Selector) {
        let tap = UITapGestureRecognizer(target: self, action: handler)
        section.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
