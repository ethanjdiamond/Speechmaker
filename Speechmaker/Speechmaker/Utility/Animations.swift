//
//  Animations.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/28/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

struct Animations {
    static let Rotate: CAAnimation = {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.duration = 1.0
        animation.repeatCount = Float.infinity
        animation.fromValue = 0.0
        animation.toValue = 2 * M_PI
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.isRemovedOnCompletion = false
        return animation
    }()
    
    static let Blink: CAAnimation = {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 1.0
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.isRemovedOnCompletion = false
        return animation
    }()
}


