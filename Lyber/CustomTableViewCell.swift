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
    
    @IBOutlet weak var iconDisplay: UIImageView!
    
    @IBOutlet weak var priceRange: UILabel!
    
    @IBOutlet weak var estimateTime: UILabel!
    
    @IBOutlet weak var type: UILabel!
}
