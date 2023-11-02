//
//  Error.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/17/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

class SpeechmakerError: NSError {
    init(code: Int, localizedDescription: String) {
        super.init(domain: "com.ethanjdiamond.speechmaker", code: code,
                   userInfo: [NSLocalizedDescriptionKey : localizedDescription])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
