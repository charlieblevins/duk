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
    
    var markerData: Marker? = nil
    var statusBar: UILabel? = nil
    var master: MyMarkersController? = nil
    
    var indexPath: IndexPath? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
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
    
    func updateStatus (_ content: String) {
        
        if (master!.isViewLoaded == false) {
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
        statusBar!.frame.size = CGSize(width: 100, height: 30)
        statusBar!.text = "Status Placeholder"
        statusBar!.textColor = UIColor.red
        statusBar!.translatesAutoresizingMaskIntoConstraints = false
        
        // Append status bar
        self.contentView.addSubview(statusBar!)
        
        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: statusBar!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -10
        )
        let vrtC = NSLayoutConstraint(
            item: statusBar!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        let hgtC = NSLayoutConstraint(
            item: statusBar!,
            attribute: .height,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .height,
            multiplier: 1.0,
            constant: 0
        )
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, vrtC, hgtC])
    }
    
    // MARK: upload delegate method handlers
    func reqDidStart() {
        
    }
    
    // Show progress
    func uploadDidProgress(_ progress: Float) {
        let percentage = Int(progress * 100)
        self.updateStatus("\(percentage)% complete")
    }
    
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod) {
        print("upload complete")
        
        // Save new data to core data
        let timestamp: Double = self.markerData!.timestamp!
        
        guard let data_convert = data["data"] as? [String:String] else {
            print("unexpected data structure at reqDidComplete")
            return
        }
        
        guard let pubID: String = data_convert["_id"] else {
            print("could not get _id from response")
            return
        }
        
        master!.updateMarkerEntity(timestamp, publicID: pubID)
        
        // Alert that upload was successful
        //master!.popSuccessAlert()
        
        master!.tableView.reloadRows(at: [self.indexPath!], with: .right)
    }
    
    // Show alert on failure
    func reqDidFail(_ error: String, method: ApiMethod) {
        
        print("upload failure")
        
        master!.appendPublishBtn((self.indexPath! as NSIndexPath).row, cell: self)
        
        // Pop alert with error message
        master!.popFailAlert(error)
    }
}
