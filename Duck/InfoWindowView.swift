//
//  InfoWindowView.swift
//  Duck
//
//  Created by Charlie Blevins on 4/30/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

class InfoWindowView: UIView {

    @IBOutlet weak var loading: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var moreDetailBtn: UIButton!
    @IBOutlet weak var tags: UILabel!

    class func instanceFromNib() -> InfoWindowView {
        return UINib(nibName: "InfoWindow", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! InfoWindowView
    }
    
    // Bug fix: without this infowindow freezes
    override func didMoveToSuperview() {
        superview?.autoresizesSubviews = false;
    }
    
    
    @IBAction func didTapMoreDetail(_ sender: AnyObject) {
        print("more detail tapped")
    }
}
