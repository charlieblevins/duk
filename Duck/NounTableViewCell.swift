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
        Util.loadIconImage(noun, imageView: self.NounRowImage, activitIndicator: self.NounRowActivity)
    }
}