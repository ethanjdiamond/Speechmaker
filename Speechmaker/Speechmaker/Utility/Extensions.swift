//
//  Extensions.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/13/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

func delay(_ delay: Double, closure: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func dispatch_main(_ closure: @escaping () -> ()) {
    DispatchQueue.main.async(execute: closure)
}

extension FileManager {
    func removeItemAtPathIfPresent(_ path: String) {
        if (self.fileExists(atPath: path)) {
            try! self.removeItem(atPath: path)
        }
    }
    
    func createDirectoryAtPathIfNotPresent(_ path: String) {
        if !self.fileExists(atPath: path) {
            try! self.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

extension UIAlertController {
    static func alert(_ string: String) {
        let alertController = UIAlertController(title: nil, message: string, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))
        UIApplication.shared.keyWindow?.rootViewController!.present(alertController, animated: true, completion: nil)
    }
}

extension String {
    func containsCharactersFromSet(_ characterSet: CharacterSet) -> Bool {
        return rangeOfCharacter(from: characterSet, options: NSString.CompareOptions.diacriticInsensitive, range:nil) != nil
    }
}

// From http://stackoverflow.com/questions/438046/iphone-slide-to-unlock-animation
extension UIView {
    func shimmer() {
        let transparency:CGFloat = 0.75
        let gradientWidth: CGFloat = 40
        
        let gradientMask = CAGradientLayer()
        gradientMask.frame = self.bounds
        let gradientSize = gradientWidth/self.frame.size.width
        let gradient = UIColor(white: 1, alpha: transparency)
        let startLocations = [0, gradientSize/2, gradientSize]
        let endLocations = [(1 - gradientSize), (1 - gradientSize/2), 1]
        let animation = CABasicAnimation(keyPath: "locations")
        
        gradientMask.colors = [gradient.cgColor, UIColor.white.cgColor, gradient.cgColor]
        gradientMask.locations = startLocations as [NSNumber]?
        gradientMask.startPoint = CGPoint(x: 0 - (gradientSize*2), y: 0.5)
        gradientMask.endPoint = CGPoint(x: 1 + gradientSize, y: 0.5)
        
        self.layer.mask = gradientMask
        
        animation.fromValue = startLocations
        animation.toValue = endLocations
        animation.repeatCount = HUGE
        animation.duration = 3
        
        gradientMask.add(animation, forKey: "animateGradient")
    }
}

private let reachability = Reachability()
extension Reachability {
    public static var instance: Reachability {
        get {
            return reachability!
        }
    }
}
