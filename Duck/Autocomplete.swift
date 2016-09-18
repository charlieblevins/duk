//
//  Autocomplete.swift
//  Duck
//
//  Created by Charlie Blevins on 11/22/15.
//  Copyright © 2015 Charlie Blevins. All rights reserved.
//

import Foundation
import UIKit

protocol AutocompleteDelegate {
    func willChooseTag(_ autocomplete: Autocomplete, tag: UIButton)
}

open class Autocomplete: NSObject {
    
    open var itemHeight: CGFloat = 20
    open var itemWidth: CGFloat = 200
    open var backgroundColor: CGColor = UIColor.white.cgColor
    
    var delegate: AutocompleteDelegate?
    
    fileprivate var iconModel: IconModel?
    fileprivate var autocompleteView: UIView?
    fileprivate var tagBubbles: UIView?
    

    
    override init () {
        print("new Autocomplete instance")
    }
    
    // Takes a string. Finds all matching icons and returns a ui view containing
    // each matching icon as a button
    open func suggest (_ search: String) -> UIView? {
        
        // Load icon data
        if iconModel == nil {
            iconModel = IconModel()
        }
        
        let matchingIcons: [IconModel.Icon] = findMatchingIcons(search)
        
        // No icons were found
        if (matchingIcons.count == 0) {
            
            // Remove autocomplete if exists
            if (autocompleteView != nil) {
                autocompleteView!.removeFromSuperview()
                autocompleteView = nil
            }

            return autocompleteView
        }
        
        // Display matching items in dropdown
        // Limit to 5 results
        
        
        // Measure amount of space needed
        let height = CGFloat(matchingIcons.count) * self.itemHeight
        
        // Build/show autocomplete container
        if autocompleteView === nil {
            
            let aFrame = CGRect(x: 0, y: 0, width: self.itemWidth, height: height)
            autocompleteView = UIView(frame: aFrame)
            autocompleteView!.layer.backgroundColor = self.backgroundColor
            
            // If autocomplete exists but results have changed
        } else if autocompleteView!.frame.height != height {
            
            // Set new autocomplete height
            autocompleteView!.frame.size.height = height
            
            // Clear old results
            autocompleteView!.subviews.forEach({ $0.removeFromSuperview() })
        }
        
        // Append suggestions (icon names)
        let limit = matchingIcons.count
        for i in 0 ..< limit {
            
            let icon = matchingIcons[i]
            
            // Increase y value for each suggestion
            let yPos = CGFloat(i) * self.itemHeight
            
            // Get icon
            let iconImg = UIImage(named: icon.imageName)
            
            // Build button
            let iconBtn: UIButton = UIButton(frame: CGRect(x: 0, y: yPos, width: self.itemWidth, height: self.itemHeight))
            iconBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            iconBtn.imageView?.frame = CGRect(x: 2, y: 2, width: self.itemWidth - 4, height: self.itemHeight - 4)
            iconBtn.setImage(iconImg, for: UIControlState())
            iconBtn.setTitleColor(UIColor.gray, for: UIControlState())
            iconBtn.setTitle(icon.tag, for: UIControlState())
            
            // Set button image insets (padding)
            iconBtn.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
            
            // Listen for tap
            iconBtn.addTarget(self, action: #selector(Autocomplete.willChooseTag(_:)), for: .touchUpInside)
            
            // Add to super
            autocompleteView!.addSubview(iconBtn)
            
        } // End for loop

        
        return autocompleteView!
    }
    
    func willChooseTag(_ sender: UIButton) {
        delegate?.willChooseTag(self, tag: sender)
    }
    
    // Get array of icons that match a search
    fileprivate func findMatchingIcons (_ search: String) -> [IconModel.Icon] {
        return iconModel!.icons.filter({
            
            // Check if icon tag contains typed text
            let foundString: Range? = $0.tag.range(of: search)
            
            // all characters of search string match first characters of Icon name
            if foundString != nil && foundString!.lowerBound == search.startIndex {
                return true
            } else {
                return false
            }
        })
    }
}
