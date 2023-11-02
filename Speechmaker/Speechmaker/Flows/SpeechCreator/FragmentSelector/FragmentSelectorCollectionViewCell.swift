//
//  FragmentSelectorCollectionViewCell.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/4/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

@IBDesignable
class FragmentSelectorCollectionViewCell: UICollectionViewCell {
    @IBOutlet var roundedBackgroundView: UIView!
    @IBOutlet var wordLabel: UILabel!
    
    var fragment: Fragment? = nil {
        didSet {
            wordLabel.text = fragment?.displayText
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        roundedBackgroundView.layer.cornerRadius = 12.0
        roundedBackgroundView.layer.masksToBounds = true
    }
}
