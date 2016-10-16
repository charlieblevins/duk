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

    @IBOutlet weak var NounRowLabel: UILabel!
    @IBOutlet weak var iconView: MarkerIconView!
    
    
    override func awakeFromNib() {

        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
