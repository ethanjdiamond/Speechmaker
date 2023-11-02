//
//  AppVersion.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/28/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

open class AppVersion : Comparable {
    open let majorVersion: Int
    open let minorVersion: Int
    open let patchVersion: Int
    open var stringValue: String {
        return "\(majorVersion).\(minorVersion).\(patchVersion)"
    }

    init(versionString: String) {
        let versionSplit = versionString.components(separatedBy: ".")
        majorVersion = versionSplit.count >= 1 ? Int(versionSplit[0])! : 0
        minorVersion = versionSplit.count >= 2 ? Int(versionSplit[1])! : 0
        patchVersion = versionSplit.count >= 3 ? Int(versionSplit[2])! : 0
    }
    
    static func currentVersion() -> AppVersion {
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        return AppVersion(versionString: versionString)
    }
}

public func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
    return lhs.majorVersion == rhs.majorVersion && lhs.minorVersion == rhs.minorVersion && lhs.patchVersion == rhs.patchVersion
}

public func <(lhs: AppVersion, rhs: AppVersion) -> Bool {
    if lhs.majorVersion == rhs.majorVersion {
        if lhs.minorVersion == rhs.minorVersion {
            return lhs.patchVersion < rhs.patchVersion
        } else {
            return lhs.minorVersion < rhs.minorVersion
        }
    } else {
        return lhs.majorVersion < rhs.majorVersion
    }
}
