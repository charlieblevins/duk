//
//  CameraControlsOverlay.swift
//  Duck
//
//  Created by Charlie Blevins on 10/23/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

protocol CameraControlsOverlayDelegate {
    func didTapShutter ()
    func didTapClose ()
}

class CameraControlsOverlay: UIView {
    
    var delegate: CameraControlsOverlayDelegate? = nil
    
    @IBOutlet weak var shutter: UIButton!
    
    class func instanceFromNib() -> CameraControlsOverlay {
        return UINib(nibName: "CameraControlsOverlay", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CameraControlsOverlay
    }
    
    @IBAction func shutterTapped(_ sender: UIButton) {
        print("shutter tapped")
        
        if self.delegate != nil {
            self.delegate?.didTapShutter()
        }
    }
    @IBAction func closeTapped(_ sender: UIButton, forEvent event: UIEvent) {
        print("close tapped")
        
        if self.delegate != nil {
            self.delegate?.didTapClose()
        }
    }
}
