//
//  SpeechCreatorCursorCollectionViewCell.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/10/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

class SpeechCreatorCursorCollectionViewCell: UICollectionViewCell {
    @IBOutlet var cursor: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cursor.layer.add(Animations.Blink, forKey: "blink")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cursor.layer.add(Animations.Blink, forKey: "blink")
    }
}
