//
//  UIZoomableImage.swift
//  Duck
//
//  Created by Charlie Blevins on 4/18/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit

protocol ZoomableImageDelegate {}

class ZoomableImageView: UIImageView {
    
    var allowZoom: Bool = false
    
    var delegate: UIViewController? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Make view tappable
        self.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(_:)))
        self.addGestureRecognizer(tapRecognizer)
    }
    
    func imageTapped (_ gestureRecognizer: UITapGestureRecognizer) {
        
        if allowZoom == false {
            print("Image tapped but allowZoom is false")
            return Void()
        }
        
        // Add this image to the zoomable view controller
        let zoomView = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "ImageZoomView") as! ImageZoomViewController
        zoomView.fullImage = self.image
        
        // Navigate to zoomable view
        self.delegate?.present(zoomView, animated: true, completion: nil)
    }
}
