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
    var pubBtn: UIButton? = nil
    var statusBar: UILabel? = nil
    var unpublish: UIButton? = nil
    var pendingBadge: UILabel? = nil
    var publicBadge: UILabel? = nil
    var loader: UIAlertController? = nil
    var publicBadgeTopConstraint: NSLayoutConstraint? = nil
    var master: MyMarkersController? = nil
    var curBadge: UIView? = nil
    
    var pendingUnpublish: Bool = false
    
    var indexPath: IndexPath? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideUnpublish),
            name: Notification.Name("UnpublishBtnShown"),
            object: nil
        )
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
    
    // Remove the current badge and append a new one
    func appendBadge (_ badge: UIView) {
        
        // Remove old
        if self.curBadge != nil {
            self.curBadge?.removeFromSuperview()
        }
        
        self.contentView.addSubview(badge)
        self.curBadge = badge
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
        appendBadge(statusBar!)
        
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
    
    // Append pending badge
    func appendPendingBadge () {
        
        // Add publish button
        pendingBadge = UILabel()
        pendingBadge!.frame.size = CGSize(width: 120, height: 30)
        pendingBadge!.text = "Pending"
        
        // white text and orange background
        pendingBadge!.textColor = UIColor.white
        
        let orange = UIColor(red: 239, green: 108, blue: 0) // Orange
        pendingBadge!.layer.backgroundColor = orange.cgColor
        
        // rounded corners
        pendingBadge!.layer.cornerRadius = 3
        
        //center text
        pendingBadge!.textAlignment = .center
        
        pendingBadge!.translatesAutoresizingMaskIntoConstraints = false
        
        appendBadge(pendingBadge!)
        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: pendingBadge!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -10
        )
        
        // This constraint used to animate for unpublish toggle
        let topC = NSLayoutConstraint(
            item: pendingBadge!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        let wdtC = NSLayoutConstraint(
            item: pendingBadge!,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 66
        )
        let hgtC = NSLayoutConstraint(
            item: pendingBadge!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 30
        )
        
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, topC, wdtC, hgtC])
        
        // Handle tap
        // Even though IB says this is already true, it isn't
        pendingBadge!.isUserInteractionEnabled = true
        pendingBadge!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(alertPendingInfo)))
    }
    
    func alertPendingInfo () {
        let alertController = UIAlertController(title: "Pending Status",
                                                message: "This marker is awaiting approval. Approval generally takes 12-24 hours.",
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        self.master?.present(alertController, animated: true, completion: nil)
    }
    
    // Show a public badge for published markers
    func appendPublicBadge () {
        
        // Add publish button
        publicBadge = UILabel()
        publicBadge!.frame.size = CGSize(width: 120, height: 30)
        publicBadge!.text = "Public"
        
        // white text and green background
        publicBadge!.textColor = UIColor.white
        
        let fGreen = UIColor(red: 56, green: 150, blue: 57) // Forest green
        publicBadge!.layer.backgroundColor = fGreen.cgColor
        
        // rounded corners
        publicBadge!.layer.cornerRadius = 3
        
        //center text
        publicBadge!.textAlignment = .center
        
        publicBadge!.translatesAutoresizingMaskIntoConstraints = false
        
        appendBadge(publicBadge!)
        
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
        publicBadge!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(alertPublicInfo)))
    }
    
    func alertPublicInfo () {
        let alertController = UIAlertController(title: "Public",
                                                message: "This marker is publicly viewable.",
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        self.master?.present(alertController, animated: true, completion: nil)
    }
    
    func appendDeniedBadge () {
        
        // Add publish button
        let deniedBadge = UILabel()
        deniedBadge.frame.size = CGSize(width: 120, height: 30)
        deniedBadge.text = "Not Approved"
        
        // white text and orange background
        deniedBadge.textColor = UIColor.white
        
        let orange = UIColor(red: 40, green: 53, blue: 157) // Purple
        deniedBadge.layer.backgroundColor = orange.cgColor
        
        // rounded corners
        deniedBadge.layer.cornerRadius = 3
        
        //center text
        deniedBadge.textAlignment = .center
        
        deniedBadge.translatesAutoresizingMaskIntoConstraints = false
        
        appendBadge(deniedBadge)
        
        // Position with constraints
        let hrzC = NSLayoutConstraint(
            item: deniedBadge,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -10
        )
        
        // This constraint used to animate for unpublish toggle
        let topC = NSLayoutConstraint(
            item: deniedBadge,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        let wdtC = NSLayoutConstraint(
            item: deniedBadge,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 66
        )
        let hgtC = NSLayoutConstraint(
            item: deniedBadge,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 30
        )
        
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, topC, wdtC, hgtC])
        
        // Handle tap
        // Even though IB says this is already true, it isn't
        deniedBadge.isUserInteractionEnabled = true
        deniedBadge.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(alertDeniedInfo)))
    }
    
    func alertDeniedInfo () {
        let alertController = UIAlertController(title: "Not Approved",
                                                message: "Every so often a marker does not meet Duk's photo guidelines. Please check your email for more information about why this marker received this status.",
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        self.master?.present(alertController, animated: true, completion: nil)
    }
    
    func hideUnpublish () {
        if unpublish != nil {
            toggleUnpublish()
        }
    }
    
    // Append un-publish btn
    // DEPRECATED - no longer used
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
        
        // Notify all rows
        let notifName = Notification.Name("UnpublishBtnShown")
        NotificationCenter.default.post(name: notifName, object: nil)
        
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
        
        // Receive tap
        unpublish!.isUserInteractionEnabled = true
        unpublish!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(unpublishMarker)))
    }
    
    func appendPublishBtn () {
        
        // Add publish button
        pubBtn = UIButton(type: .system)
        
        pubBtn!.setTitle("Publish", for: UIControlState())
        pubBtn!.translatesAutoresizingMaskIntoConstraints = false
        
        pubBtn!.addTarget(self, action: #selector(self.publishTapped), for: .touchUpInside)
        
        appendBadge(pubBtn!)
        
        // Position with contraints
        let hrzC = NSLayoutConstraint(
            item: pubBtn!,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: -12
        )
        let vrtC = NSLayoutConstraint(
            item: pubBtn!,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        let hgtC = NSLayoutConstraint(
            item: pubBtn!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 30
        )
        
        // Activate all constraints
        NSLayoutConstraint.activate([hrzC, vrtC, hgtC])
    }
    
    func publishTapped () {
        self.master!.publishAction(self)
    }
    
    // Delete a marker from the server and mark the local marker as local
    func unpublishMarker () {
        
        guard self.markerData != nil else {
            print("Cannot unpublish. No id available")
            return
        }
        
        guard let pid = self.markerData?.public_id else {
            print("Cannot unpublish. Marker has no public id")
            return
        }
        
        self.master!.getCredentials({ credentials in
            
            self.setLoading(loading: true, message: "Unpublishing...")
            
            // If marker is not stored locally - first download it
            if self.markerData?.timestamp == nil {
                self.requestMarkerDownload(pid)
                
            // Marker exists locally - proceed with unpublish
            } else {
                self.requestUnpublish(pid, credentials: credentials)
            }
        })
    }
    
    func requestMarkerDownload(_ public_id: String) {
        let req = ApiRequest()
        req.delegate = self
        
        self.pendingUnpublish = true
        
        let marker_params: Dictionary<String, Any> = [
            "public_id": public_id,
            "photo_size": ["sm", "md", "full"]
        ]
        let params: Array<Dictionary<String, Any>> = [marker_params]
        
        req.getMarkerDataById(params)
    }
    
    func requestUnpublish(_ public_id: String, credentials: Credentials) {
        let req = ApiRequest()
        req.delegate = self
        req.deleteMarker(public_id, credentials: credentials)
    }
    
    // Show/hide an activity indicator
    func setLoading(loading: Bool, message: String?) {
        
        // Hide
        if !loading {
            self.loader?.dismiss(animated: false, completion: nil)
            self.loader = nil
            
        // Show
        } else {
            
            let message = (message != nil) ? message : "Loading..."
            self.loader = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            
            self.loader!.view.tintColor = UIColor.black
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = .gray
            loadingIndicator.startAnimating();
            
            loader!.view.addSubview(loadingIndicator)
            self.master?.present(loader!, animated: true, completion: nil)
        }
    }
    
    func getPhoto () {
        
        guard var marker = self.markerData else {
            print("cannot load photo for cell without assigned marker")
            return
        }
        
        // Photo stored locally
        if marker.timestamp != nil {
            
            // Begin photo lookup on new thread
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                
                marker.loadPropFromCore(prop: "photo_sm", propLoaded: {
                    data in
                    
                    if data == nil {
                        print("Prop lookeup for marker returned nil")
                        return
                    }
                    
                    guard let typed_data = data as? Data else {
                        print("lookup returned data not convertible to data type")
                        return
                    }
                    
                    // Send image back to main thread for display
                    DispatchQueue.main.async {
                        self.markerImage.image = UIImage(data: typed_data)
                    }
                })
            }
            return
        }
        
        // Load from server
        if let id = marker.public_id {
            let url_str = "http://dukapp.io/photos/\(id)_sm.jpg"
            let url = URL(string: url_str)
            self.markerImage.kf.setImage(
                with: url,
                placeholder: nil,
                options: nil,
                progressBlock: nil,
                completionHandler: { (image, error, cacheType, imageURL) -> () in
                    
                    if error !== nil {
                        print("image GET failed: \(error)")
                        return Void()
                    }
                    
                    self.markerImage.image = image
            })
        }
    }
    
    // MARK: upload delegate method handlers
    func reqDidStart() {
        if pubBtn != nil {
            pubBtn?.removeFromSuperview()
        }
    }
    
    // Show progress
    func uploadDidProgress(_ progress: Float) {
        let percentage = Int(progress * 100)
        self.updateStatus("\(percentage)% complete")
    }
    
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        
        if (method == .publishMarker) {
            print("upload complete")
            
            // Save new data to core data
            let timestamp: Double = self.markerData!.timestamp!
            
            guard let data_convert = data["data"] as? [String: Any] else {
                print("unexpected data structure at reqDidComplete")
                return
            }
            
            guard let pubID: String = data_convert["_id"] as? String else {
                print("could not get _id from response")
                return
            }
            
            master!.updateMarkerEntity(timestamp, publicID: pubID)
            
            // Request is no longer active
            MyMarkersController.active_requests.removeValue(forKey: timestamp)
            
            self.statusBar?.removeFromSuperview()
            self.appendPendingBadge()
        
        // Unpublish
        } else if (method == .deleteById) {
            print("unpublish/delete complete")
            
            master!.updateMarkerEntity(self.markerData!.timestamp!, publicID: nil)
            
            // Remove loading overlay
            self.setLoading(loading: false, message: nil)
            
            // Reload this cell
            if let index = self.indexPath, let parent = master {
                parent.tableView.reloadRows(at: [index], with: .automatic)
            }
        
        // Assume marker download request
        } else if (method == .getMarkerDataById) {
            
            // Convert returned to marker objects
            guard let returned = data.value(forKey: "data") as? Array<Any> else {
                print("Returned markers could not be converted to an array")
                return
            }
            
            guard returned.count > 0 else {
                print("No public markers returned by getMArkerDataById")
                return
            }
            
            guard let data_dic: NSDictionary = returned[0] as? NSDictionary else {
                print("could not cast to NSDictionary")
                return
            }
            
            // Build marker instance
            guard var marker = Marker(fromPublicData: data_dic) else {
                print("could not build marker instance from data")
                return
            }
            
            // Generate timestamp
            marker.timestamp = Marker.generateTimestamp()
            
            // Save
            marker.saveInCore()
            
            if self.pendingUnpublish {
                self.unpublishMarker()
            }
        }

    }
    
    // Show alert on failure
    func reqDidFail(_ error: String, method: ApiMethod, code: Int) {
        if (method == .publishMarker) {
            print("upload failure")
            
            // Request is no longer active
            let timestamp: Double = self.markerData!.timestamp!
            MyMarkersController.active_requests.removeValue(forKey: timestamp)
            
            self.statusBar?.removeFromSuperview()
            self.appendPublishBtn()
            
            // Pop alert with error message
            master!.popFailAlert(error)
        } else if (method == .deleteById) {
            
            // If marker not found, treat as success
            if code == 404 {
                self.reqDidComplete(NSDictionary(), method: method, code: code)
                return
            }
            
            print("unpublish failure: \(error)")
            
            self.setLoading(loading: false, message: nil)
            
            self.toggleUnpublish()
            
            let alertController = UIAlertController(title: "Unpublish Failed",
                                                    message: error,
                                                    preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            
            self.master?.present(alertController, animated: true, completion: nil)
        }
    }
}
