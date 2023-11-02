    //
//  SpeechCreatorWordCollectionViewCell.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/4/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

@IBDesignable
class SpeechCreatorWordCollectionViewCell: UICollectionViewCell {
    @IBOutlet var roundedBackgroundView: UIView!
    @IBOutlet var wordLabel: UILabel!

    var word: Word? = nil {
        didSet {
            wordLabel.text = word?.text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        roundedBackgroundView.layer.cornerRadius = 6.0
        roundedBackgroundView.layer.masksToBounds = true
    }
}
