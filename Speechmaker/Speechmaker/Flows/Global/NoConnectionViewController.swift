//
//  NoConnectionViewController.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/28/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import Foundation
import UIKit

class NoConnectionViewController: UIViewController {
    @IBOutlet var loadingView: LoadingView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadingView.progress = 0.75
        loadingView.layer.add(Animations.Rotate, forKey: "rotate")
    }
}
