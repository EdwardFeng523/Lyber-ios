//
//  CustomTableViewCell.swift
//  Lyber
//
//  Created by Edward Feng on 6/18/18.
//  Copyright © 2018 Edward Feng. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // Icon image
    @IBOutlet weak var iconDisplay: UIImageView!
    
    // Price range label
    @IBOutlet weak var priceRange: UILabel!
    
    // Estimate time label
    @IBOutlet weak var estimateTime: UILabel!
    
    // Type label
    @IBOutlet weak var type: UILabel!
}
