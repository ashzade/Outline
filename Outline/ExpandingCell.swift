//
//  ExpandingCell.swift
//  Outline
//
//  Created by Ash Zade on 2017-12-26.
//  Copyright © 2017 Ash Zade. All rights reserved.
//

import UIKit
import NightNight

class ExpandingCell: UITableViewCell {
    @IBOutlet weak var textView: UITextView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textView.mixedBackgroundColor = MixedColor(normal: 0xffffff, night: 0x263238)
        
    }
    
}
