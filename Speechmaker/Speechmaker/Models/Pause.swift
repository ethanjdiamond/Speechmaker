//
//  Pause.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 9/4/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import Foundation
import CoreData


class Pause: Fragment {
    override var apiUrlFolder: String { return "pauses" }
    override var displayText: String { return "[\(text!.capitalized) Pause]" }
}
