//
//  MarkersWrapperController.swift
//  Duck
//
//  Created by Charlie Blevins on 1/26/17.
//  Copyright © 2017 Charlie Blevins. All rights reserved.
//

import UIKit

class MarkersWrapperController: UIViewController {
    
    @IBOutlet weak var tabsContainer: UIView!
    @IBOutlet weak var toggleTable: UISegmentedControl!
    @IBOutlet weak var tableContainer: UIView!

    
    var table: UITableViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.showMyMarkers()
    }
    
    // Remove current table and add the selected one
    @IBAction func toggleTapped(_ sender: UISegmentedControl) {
        
        self.table?.view.removeFromSuperview()
        self.table?.removeFromParentViewController()
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.showMyMarkers()
            break
        case 1:
            self.showFavorites()
            break
        default:
            print("No table for segmented index")
            break
        }
    }
    
    func showMyMarkers () {
        
        if let controller_inst = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MyMarkersController") as? MyMarkersController {
            self.addTable(controller_inst)
        }
    }
    
    func showFavorites () {
        
        if let controller_inst = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FavoriteMarkersController") as? FavoriteMarkersController {
            self.addTable(controller_inst)
        }
    }
    
    func addTable(_ tableController: UITableViewController) {
        
        self.table = tableController
        
        self.addChildViewController(tableController)
        
        // Add view but hide until constraints are in place
        self.tableContainer.addSubview(tableController.view)
        
        // Turn off conclicting automatic constraints
        tableController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Full width
        let width_constraint = NSLayoutConstraint(
            item: tableController.view,
            attribute: .width,
            relatedBy: .equal,
            toItem: self.tableContainer,
            attribute: .width,
            multiplier: 1,
            constant: 0
        )
        width_constraint.isActive = true
        
        // Constant height
        let height_constraint = NSLayoutConstraint(
            item: tableController.view,
            attribute: .height,
            relatedBy: .equal,
            toItem: self.tableContainer,
            attribute: .height,
            multiplier: 1,
            constant: 0
        )
        height_constraint.isActive = true
        
        // Top
        let top_constraint = NSLayoutConstraint(
            item: tableController.view,
            attribute: .top,
            relatedBy: .equal,
            toItem: self.tableContainer,
            attribute: .top,
            multiplier: 1,
            constant: 0
        )
        top_constraint.isActive = true
        
        // Left
        let left_constraint = NSLayoutConstraint(
            item: tableController.view,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self.tableContainer,
            attribute: .leading,
            multiplier: 1,
            constant: 0
        )
        left_constraint.isActive = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
