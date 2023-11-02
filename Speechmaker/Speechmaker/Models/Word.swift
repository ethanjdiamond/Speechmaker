//
//  Word.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/3/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import Foundation
import CoreData

class Word: Fragment {
    override var apiUrlFolder: String { return "words" }
    override var displayText: String { return text! }
}
