//
//  Globals.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/3/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import Foundation

let SPEECHMAKER_API_BASE_URL = "https://5qez50qs31.execute-api.us-east-1.amazonaws.com"

#if DEBUG
let SPEECHMAKER_API_STAGE = "prod"
let SPEECHMAKER_CAN_LOG = true
#else
let SPEECHMAKER_API_STAGE = "prod"
let SPEECHMAKER_CAN_LOG = false
#endif

func log(_ string: String) {
    if (SPEECHMAKER_CAN_LOG) {
        print(string)
    }
}
