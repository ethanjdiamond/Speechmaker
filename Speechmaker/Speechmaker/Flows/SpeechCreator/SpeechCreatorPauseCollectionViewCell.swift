//
//  SpeechCreatorPauseCollectionViewCell.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 9/4/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

@IBDesignable
class SpeechCreatorPauseCollectionViewCell: UICollectionViewCell {
    @IBOutlet var roundedBackgroundView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        roundedBackgroundView.layer.cornerRadius = 6.0
        roundedBackgroundView.layer.masksToBounds = true
        roundedBackgroundView.alpha = 0.5
    }
}
