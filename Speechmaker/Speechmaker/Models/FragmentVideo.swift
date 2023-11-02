//
//  FragmentVideo.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/7/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

class FragmentVideo : Hashable {
    let fragment: Fragment
    var url: URL?
    var localURL: URL?
    var downloadProgress: Float = 0
    var hashValue: Int {
        return Unmanaged.passUnretained(self).toOpaque().hashValue
    }
    
    init(fragment: Fragment) {
        self.fragment = fragment
    }
}

func ==(lhs: FragmentVideo, rhs: FragmentVideo) -> Bool {
    return lhs === rhs
}
