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
    var unpublish: UIButton? = nil
    var publicBadge: UILabel? = nil
    var publicBadgeTopConstraint: NSLayoutConstraint? = nil
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
    
    // Show a public badge for published markers
    func appendPublicBadge () {
        
        if publicBadge != nil {
            return
        }
        
        // Add publish button
        publicBadge = UILabel()
        publicBadge!.frame.size = CGSize(width: 120, height: 30)
        publicBadge!.text = "Public"
        
        // green text and border
        let fGreen = UIColor(red: 56, green: 150, blue: 57) // Forest green
        publicBadge!.textColor = fGreen
        publicBadge!.layer.borderColor = fGreen.cgColor
        publicBadge!.layer.borderWidth = 1
        
        // rounded corners
        publicBadge!.layer.cornerRadius = 3
        
        //center text
        publicBadge!.textAlignment = .center
        
        publicBadge!.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(publicBadge!)
        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: publicBadge!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -10
        )
        
        // This constraint used to animate for unpublish toggle
        publicBadgeTopConstraint = NSLayoutConstraint(
            item: publicBadge!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        let wdtC = NSLayoutConstraint(
            item: publicBadge!,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 66
        )
        let hgtC = NSLayoutConstraint(
            item: publicBadge!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 30
        )
        
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, publicBadgeTopConstraint!, wdtC, hgtC])
        
        // Handle tap
        // Even though IB says this is already true, it isn't
        publicBadge!.isUserInteractionEnabled = true
        publicBadge!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleUnpublish)))
    }
    
    // Append un-publish btn
    func toggleUnpublish () {
        
        // Hide
        if unpublish != nil {
            
            // set constant before animation
            publicBadgeTopConstraint!.constant = 0
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .allowAnimatedContent, animations: {
                // fade out
                self.unpublish?.alpha = 0.0
                
                // slide back
                self.contentView.layoutIfNeeded()
                
            }, completion: { finished in
                self.unpublish?.removeFromSuperview()
                self.unpublish = nil
            })
            return
        }
        
        // Show
        
        // Make a button
        unpublish = UIButton()
        unpublish!.frame.size = CGSize(width: 100, height: 30)
        unpublish!.setTitle("Unpublish", for: .normal)
        unpublish!.setTitleColor(UIColor(red: 0, green: 122, blue: 255), for: .normal)
        unpublish!.translatesAutoresizingMaskIntoConstraints = false
        
        // Append status bar (still hidden)
        unpublish!.alpha = 0
        self.contentView.addSubview(unpublish!)

        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: unpublish!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -10
        )
        let vrtC = NSLayoutConstraint(
            item: unpublish!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 20
        )
        let hgtC = NSLayoutConstraint(
            item: unpublish!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 30
        )
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, vrtC, hgtC])
        
        // layout constraints before animation
        self.contentView.layoutIfNeeded()
        
        // set constant before animation
        publicBadgeTopConstraint!.constant = -12
        UIView.animate(withDuration: 0.5, animations: {
            // fade in
            self.unpublish!.alpha = 1.0
            
            // slide up
            self.contentView.layoutIfNeeded()
        })
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
