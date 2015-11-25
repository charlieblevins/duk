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
    func willChooseTag(autocomplete: Autocomplete, tag: UIButton)
}

public class Autocomplete: NSObject {
    
    public var itemHeight: CGFloat = 20
    public var itemWidth: CGFloat = 200
    public var backgroundColor: CGColor = UIColor.whiteColor().CGColor
    
    var delegate: AutocompleteDelegate?
    
    private var iconModel: IconModel?
    private var autocompleteView: UIView?
    private var tagBubbles: UIView?
    

    
    override init () {
        print("new Autocomplete instance")
    }
    
    // Takes a string. Finds all matching icons and returns a ui view containing
    // each matching icon as a button
    public func suggest (search: String) -> UIView? {
        
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
        for var i = 0; i < limit; ++i {
            
            let icon = matchingIcons[i]
            
            // Increase y value for each icon
            let yPos = CGFloat(i) * self.itemHeight
            
            // Build button
            let iconBtn: UIButton = UIButton(frame: CGRectMake(0, yPos, self.itemWidth, self.itemHeight))
            iconBtn.setTitleColor(UIColor.grayColor(), forState: .Normal)
            iconBtn.setTitle(icon.tag, forState: .Normal)
            
            // Listen for tap
            iconBtn.addTarget(self, action: "willChooseTag:", forControlEvents: .TouchUpInside)
            
            // Add to super
            autocompleteView!.addSubview(iconBtn)
            
        } // End for loop

        
        return autocompleteView!
    }
    
    func willChooseTag(sender: UIButton) {
        delegate?.willChooseTag(self, tag: sender)
    }
    
    // Get array of icons that match a search
    private func findMatchingIcons (search: String) -> [IconModel.Icon] {
        return iconModel!.icons.filter({
            
            // Check if icon tag contains typed text
            let foundString: Range? = $0.tag.rangeOfString(search)
            
            // all characters of search string match first characters of Icon name
            if foundString != nil && foundString!.startIndex == search.startIndex {
                return true
            } else {
                return false
            }
        })
    }
}