//
//  iconView.swift
//  Duck
//
//  Created by Charlie Blevins on 10/16/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import Foundation
import UIKit

class MarkerIconView: UIView {
    
    var iconView: UIImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        print("Have not handled normal init yet for marker icon view")
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(spinner)
    }
    
    func setNoun (_ noun: String?) {
        
        // If nil, set to placeholder
        guard noun != nil else {
            iconView.image = UIImage(named: "photoMarker")
            return
        }
        
        // load the icon
        spinner.startAnimating()
        
        MarkerIconView.loadIconImage(noun!, imageView: iconView, complete: {
            self.spinner.stopAnimating()
            self.spinner.isHidden = true
            
            self.spinner.removeFromSuperview()
            self.addSubview(self.iconView)
        })
    }
    
    static func loadIconImage (_ noun: String, imageView: UIImageView, complete: @escaping ()->Void) {
        
        let file = MarkerIconView.filenameFromNoun(noun)
        
        imageView.kf.setImage(
            with: URL(string: "http://dukapp.io/icon/\(file)?key=b185052862d41f43b2e3ffb06ed8b335")!,
            placeholder: UIImage(named: "photoMarker2"),
            options: nil,
            progressBlock: nil,
            completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                if error !== nil {
                    print("image GET failed: \(error)")
                    imageView.image = UIImage(named: "photoMarker2")
                    
                } else {
                    imageView.image = image
                }
                
                complete()
        })
    }
    
    
    // Create filename string from noun
    // for use with image creation api
    static func filenameFromNoun (_ noun: String) -> String {
        
        // Remove first char if it is a "#"
        var noun_no_hash = noun
        if noun[noun.startIndex] == "#" {
            noun_no_hash = noun.substring(from: noun.characters.index(after: noun.startIndex))
        }
        
        // Detect this iphone's resolution requirement
        let scale: Int = Int(UIScreen.main.scale)
        
        let file: String = "\(noun_no_hash)@\(scale)x.png"
        
        return file
    }
}
