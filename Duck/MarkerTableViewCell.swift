//
//  MarkerTableViewCell.swift
//  Duck
//
//  Created by Charlie Blevins on 4/17/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class MarkerTableViewCell: UITableViewCell, ApiRequestDelegate {
    
    @IBOutlet weak var markerImage: UIImageView!
    @IBOutlet weak var tagsLabel: UILabel!
    
    var markerData: AnyObject? = nil
    var statusBar: UILabel? = nil
    var master: MyMarkersController? = nil
    
    var indexPath: NSIndexPath? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // Remove right-side subviews to prevent overlapping
    func resetRight () {
        let sviews = self.contentView.subviews
        
        for i in 0 ..< sviews.count {
            
            // Remove all subviews after second subview
            if i > 1 {
                sviews[i].removeFromSuperview()
            }
        }
    
    }
    
    func updateStatus (content: String) {
        
        if (master!.isViewLoaded() == false) {
            return Void()
        }
        
        if self.statusBar == nil {
            self.appendStatusBar()
        }
        
        self.statusBar!.text = content
    }
    
    // Append a status bar in this cell
    func appendStatusBar () {
        
        // Increase table cell height
        self.contentView.frame.size.height = self.contentView.frame.size.height + 30
        
        // Make a label to act as status bar
        statusBar = UILabel()
        statusBar!.frame.size = CGSizeMake(100, 30)
        statusBar!.text = "Status Placeholder"
        statusBar!.textColor = UIColor.redColor()
        statusBar!.translatesAutoresizingMaskIntoConstraints = false
        
        // Append status bar
        self.contentView.addSubview(statusBar!)
        
        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: statusBar!,
            attribute: .Trailing,
            relatedBy: .Equal,
            toItem: self.contentView,
            attribute: .Trailing,
            multiplier: 1.0,
            constant: -10
        )
        let vrtC = NSLayoutConstraint(
            item: statusBar!,
            attribute: .CenterY,
            relatedBy: .Equal,
            toItem: self.contentView,
            attribute: .CenterY,
            multiplier: 1.0,
            constant: 0
        )
        let hgtC = NSLayoutConstraint(
            item: statusBar!,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: self.contentView,
            attribute: .Height,
            multiplier: 1.0,
            constant: 0
        )
        
        // Activate all constraints
        NSLayoutConstraint.activateConstraints([hrzC, vrtC, hgtC])
    }
    
    // MARK: upload delegate method handlers
    func uploadDidStart() {
        
    }
    
    // Show progress
    func uploadDidProgress(progress: Float) {
        let percentage = Int(progress * 100)
        self.updateStatus("\(percentage)% complete")
    }
    
    
    func uploadDidComplete(data: NSDictionary) {
        print("upload complete")
        
        // Save new data to core data
        let timestamp: Double = self.markerData!.valueForKey("timestamp") as! Double
        let pubID: String = data["data"]!["_id"] as! String
        master!.updateMarkerEntity(timestamp, publicID: pubID)
        
        // Alert that upload was successful
        //master!.popSuccessAlert()
        
        master!.tableView.reloadRowsAtIndexPaths([self.indexPath!], withRowAnimation: .Right)
    }
    
    // Show alert on failure
    func uploadDidFail(error: String) {
        
        print("upload failure")
        
        master!.appendPublishBtn(self.indexPath!.row, cell: self)
        
        // Pop alert with error message
        master!.popFailAlert(error)
    }
}
