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
    
    var iconView: IconImageView = IconImageView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // ensure icon view is below spinner
        self.addSubview(self.iconView)
        
        self.addSubview(spinner)
    }
    
    func setNoun (_ noun: String?) {
        
        self.stopSpinner()
        
        // If nil, set to placeholder
        guard let final_noun = noun else {
            self.iconView.image = UIImage(named: "photoMarker2")
            return
        }
        
        // load the icon
        self.startSpinner()
        
        self.iconView.load(final_noun, complete: {
            self.stopSpinner()
            
            self.spinner.removeFromSuperview()
        })
    }
    
    func startSpinner () {
        self.spinner.isHidden = false
        self.spinner.startAnimating()
    }
    
    func stopSpinner () {
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
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

class IconImageView: UIImageView {
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        globalInit()
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
        globalInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        globalInit()
    }
    
    func globalInit () {
        
        // set placeholder
        self.image = UIImage(named: "photoMarker2")
    }
    
    func load (_ noun: String, complete: @escaping ()->Void) {
        
        let file = MarkerIconView.filenameFromNoun(noun)
        
        self.kf.setImage(
            with: URL(string: "http://dukapp.io/icon/\(file)?key=b185052862d41f43b2e3ffb06ed8b335")!,
            placeholder: UIImage(named: "photoMarker2"),
            options: nil,
            progressBlock: nil,
            completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                if error !== nil {
                    print("image GET failed: \(String(describing: error))")
                    
                } else {
                    self.image = image
                }
                
                complete()
        })
    }
}
