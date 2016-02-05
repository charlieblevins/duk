//
//  PublishConfirmController.swift
//  Duck
//
//  Created by Charlie Blevins on 2/2/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class PublishConfirmController: UIViewController {
    
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var markerData: AnyObject? = nil
    var loginData: AnyObject? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if markerData !== nil {
            let tags = markerData?.valueForKey("tags") as! String
            tagLabel.text = tags
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
