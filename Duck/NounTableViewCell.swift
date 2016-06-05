//
//  NounCellTableViewCell.swift
//  Duck
//
//  Created by Charlie Blevins on 5/29/16.
//  Copyright © 2016 Charlie Blevins. All rights reserved.
//

import UIKit
import Kingfisher

class NounTableViewCell: UITableViewCell {

    @IBOutlet weak var NounRowImage: UIImageView!
    @IBOutlet weak var NounRowActivity: UIActivityIndicatorView!
    @IBOutlet weak var NounRowLabel: UILabel!
    
    override func awakeFromNib() {

        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // Load an icon image from the server
    func loadIconImage (noun: String) {
        
        self.NounRowActivity.startAnimating()
        
        
        // Remove first char if it is a "#"
        var noun_no_hash = noun
        if noun[noun.startIndex] == "#" {
            noun_no_hash = noun.substringFromIndex(noun.startIndex.successor())
        }
        
        // Detect this iphone's resolution requirement
        let scale: Int = Int(UIScreen.mainScreen().scale)
        
        let file: String = "\(noun_no_hash)@\(scale)x.png"
        
        NounRowImage.kf_setImageWithURL(NSURL(string: "http://dukapp.io/icon/\(file)")!,
                                        placeholderImage: nil,
                                        optionsInfo: nil,
                                        progressBlock: nil,
                                        completionHandler: { (image, error, cacheType, imageURL) -> () in
                                            
                                            self.NounRowActivity.stopAnimating()
                                            self.NounRowActivity.hidden = true
                                            
                                            if error !== nil {
                                                print("image GET failed: \(error)")
                                                return Void()
                                            }
                                            
                                            self.NounRowImage.image = image
                                        })
        
    }
}
