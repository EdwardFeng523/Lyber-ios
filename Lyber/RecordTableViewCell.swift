//
//  RecordTableViewCell.swift
//  Lyber
//
//  Created by Edward Feng on 7/7/18.
//  Copyright © 2018 Edward Feng. All rights reserved.
//

import UIKit

class RecordTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBOutlet weak var to: UILabel!
    
    @IBOutlet weak var from: UILabel!
    
    @IBOutlet weak var type: UILabel!
    
    @IBOutlet weak var price: UILabel!
    
    @IBOutlet weak var time: UILabel!
}
