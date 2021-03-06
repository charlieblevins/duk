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
    var offlineSwitch: UISwitch? = nil
    
    var pendingUnpublish: Bool = false
    
    var indexPath: IndexPath? {
        get {
            guard let parent = self.master else {
                return nil
            }
            return parent.tableView.indexPath(for: self)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setData (_ marker: Marker) {
        
        // Get marker data
        self.markerData = marker
        
        if let tags = self.markerData?.tags {
            self.tagsLabel?.attributedText = Marker.formatNouns(tags)
        }
        
        self.tagsLabel?.lineBreakMode = .byWordWrapping
        self.tagsLabel?.numberOfLines = 3
        
        // Remove right side subviews
        self.resetRight()
        
        // Get Photo
        self.getPhoto()
    }
    
    
    // Set the UI of the cell depending on it's published status
    func setPublishStatus () {
        
        guard let marker = self.markerData else {
            print("Error: Cell has no associated marker data. Cannot set status")
            return
        }
        
        if marker.public_id != nil && marker.approved != nil {
            
            switch marker.approved! {
            case .denied:
                self.appendDeniedBadge()
                break
            case .pending:
                self.appendPendingBadge()
                break
            case .approved:
                self.appendPublicBadge()
            }
            
        } else {
            self.appendPublishBtn()
        }
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
        
        if (master == nil || master!.isViewLoaded == false) {
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
        statusBar!.textColor = UIColor.purple
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
        
        self.pendingUnpublish = false
        
        guard self.markerData != nil else {
            print("Cannot unpublish. No id available")
            return
        }
        
        guard let pid = self.markerData?.public_id else {
            print("Cannot unpublish. Marker has no public id")
            return
        }
        
        self.master!.getCredentials({ credentials in
            
            self.setLoading(loading: true, message: "Unpublishing...", completion: nil)
            
            // If marker is not stored locally - first download it
            if self.markerData?.timestamp == nil {
                self.requestMarkerDownload(pid, completion: { success in
                    
                    if success {
                        self.requestUnpublish(pid, credentials: credentials)
                        
                    // Download failed
                    } else {
                        print("marker download failed. Cannot unpublish")
                        self.setLoading(loading: false, message: nil, completion: nil)
                    }
                })
                
            // Marker exists locally - proceed with unpublish
            } else {
                self.requestUnpublish(pid, credentials: credentials)
            }
        })
    }
    
    func requestMarkerDownload(_ public_id: String, completion: ((_ success: Bool) -> Void)?) {
        let marker_request = MarkerRequest()
        
        let sizes: [MarkerRequest.PhotoSizes] = [.sm, .md, .full]
        let marker_param = MarkerRequest.LoadByIdParamsSingle(public_id, sizes: sizes)
        
        marker_request.loadById([marker_param], completion: {markers in
            
            guard let marker = markers?[0] else {
                print("no markers returned")
                completion?(false)
                return
            }
            
            // Generate timestamp
            marker.timestamp = Marker.generateTimestamp()
            
            // No longer public
            marker.approved = nil
            marker.public_id = nil
            
            // Save in core
            marker.saveInCore()
            
            // Update own marker data
            self.markerData = marker
            
            // Update for table data source
            if let index = self.indexPath?.row, let parent = self.master {
                parent.setSavedMarker(index, marker: marker)
            } else {
                print("could not update table data source: No index path or parent reference")
            }
            
            completion?(true)
            
        }, failure: {
            completion?(false)
        })
    }
    
    func requestUnpublish(_ public_id: String, credentials: Credentials) {
        let req = ApiRequest()
        req.delegate = self
        req.deleteMarker(public_id, credentials: credentials)
    }
    
    // Show/hide an activity indicator
    func setLoading(loading: Bool, message: String?, completion: (()->Void)?) {
        
        // Hide
        if !loading {
            self.loader?.dismiss(animated: false, completion: completion)
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
        
        guard let marker = self.markerData else {
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
                placeholder: UIImage(named: "photoMarker2"),
                options: nil,
                progressBlock: nil,
                completionHandler: { (image, error, cacheType, imageURL) -> () in
                    
                    if error !== nil {
                        print("image GET failed: \(String(describing: error))")
                        self.markerImage.image = UIImage(named: "photoMarker2")
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
        self.updateStatus("\(percentage)%")
    }
    
    
    func reqDidComplete(_ data: NSDictionary, method: ApiMethod, code: Int) {
        
        if (method == .publishMarker) {
            print("upload complete")
            
            // Save new data to core data
            guard let marker = self.markerData else {
                print("error: cell has no marker data")
                return
            }
            
            guard let timestamp: Double = marker.timestamp else {
                print("error: cannot publish marker without timestamp")
                return
            }
            
            guard let data_convert = data["data"] as? [String: Any] else {
                print("unexpected data structure at reqDidComplete")
                return
            }
            
            guard let pubID: String = data_convert["_id"] as? String else {
                print("could not get _id from response")
                return
            }
            
            guard let user_id = Credentials.sharedInstance?.id else {
                print("Error: no user id available. Cannot update published marker")
                return
            }
            
            guard let parent = self.master else {
                print("error: no reference to parent view in table cell")
                return
            }
            
            // Updates core data and table data source
            parent.updateMarkerEntity(timestamp, publicID: pubID, approved: .pending, user_id: user_id)
            
            // Request is no longer active
            MyMarkersController.active_requests.removeValue(forKey: timestamp)
            
            // Reload this cell
            if let index = self.indexPath {
                parent.tableView.reloadRows(at: [index], with: .automatic)
            }
        
        // Unpublish
        } else if (method == .deleteById) {
            print("unpublish/delete complete")
            
            guard let parent = self.master else {
                print("error: cell has no parent reference")
                return
            }
            
            guard let marker = self.markerData else {
                print("error: cell has no marker reference")
                return
            }
            
            guard let timestamp = marker.timestamp else {
                print("error: cell has no timestmap")
                return
            }
            
            parent.updateMarkerEntity(timestamp, publicID: nil, approved: nil, user_id: nil)
            
            // Remove loading overlay
            self.setLoading(loading: false, message: nil, completion: nil)
            
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
                print("No public markers returned by getMarkerDataById")
                return
            }
            
            guard let data_dic: NSDictionary = returned[0] as? NSDictionary else {
                print("could not cast to NSDictionary")
                return
            }
            
            // Build marker instance
            guard let marker = Marker(fromPublicData: data_dic) else {
                print("could not build marker instance from data")
                return
            }
            
            // Generate timestamp
            marker.timestamp = Marker.generateTimestamp()
            
            guard let user_id = Credentials.sharedInstance?.id else {
                print("Error: no user id available. Cannot save downloaded marker")
                return
            }
            marker.user_id = user_id
            
            // Save
            marker.saveInCore()
            
            // Update for table data source
            if let index = self.indexPath?.row, let parent = master {
                parent.setSavedMarker(index, marker: marker)
            } else {
                print("could not update table data source: No index path or parent reference")
            }
            
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
            
            self.setLoading(loading: false, message: nil, completion: {
                self.master?.popAlert("Unpublish Failed", text: error)
            })
        }
    }
}
