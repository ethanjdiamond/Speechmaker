//
//  LoadingView.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/20/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

// Taken from https://www.raywenderlich.com/94302/implement-circular-image-loader-animation-cashapelayer
@IBDesignable
class LoadingView: UIView {
    let circlePathLayer = CAShapeLayer()
    @IBInspectable var lineWidth: CGFloat = 8.0 {
        didSet {
            circlePathLayer.lineWidth = lineWidth
        }
    }
    @IBInspectable var strokeColor: UIColor = UIColor.white {
        didSet {
            circlePathLayer.strokeColor = strokeColor.cgColor
        }
    }
    
    var progress: Float {
        get {
            return Float(circlePathLayer.strokeEnd)
        }
        set {
            circlePathLayer.strokeEnd = CGFloat(max(0, min(1, newValue)))
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        configure()
    }
    
    func configure() {
        backgroundColor = UIColor.clear
        circlePathLayer.frame = bounds
        circlePathLayer.lineWidth = lineWidth
        circlePathLayer.fillColor = UIColor.clear.cgColor
        circlePathLayer.strokeColor = strokeColor.cgColor
        circlePathLayer.strokeEnd = 0
        layer.addSublayer(circlePathLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circlePathLayer.frame = bounds
        circlePathLayer.path = circlePath().cgPath
    }
    
    func circlePath() -> UIBezierPath {
        return UIBezierPath(ovalIn: circleFrame())
    }
    
    func circleFrame() -> CGRect {
        var circleFrame = CGRect(x: 0, y: 0, width: frame.size.width - lineWidth, height: frame.size.height - lineWidth)
        circleFrame.origin.x = circlePathLayer.bounds.midX - circleFrame.midX
        circleFrame.origin.y = circlePathLayer.bounds.midY - circleFrame.midY
        return circleFrame
    }
    
    override func prepareForInterfaceBuilder() {
        circlePathLayer.strokeEnd = 1
    }
}
