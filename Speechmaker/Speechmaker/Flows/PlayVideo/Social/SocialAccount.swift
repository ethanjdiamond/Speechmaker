//
//  SocialAccount.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/18/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import Accounts

public protocol SocialAccount {
    var name: String { get }
    
    func getAccounts(_ success: @escaping (_ accounts: [ACAccount]) -> (), failure: @escaping (_ error: NSError) -> ())
    func postVideo(_ videoData: Data, account: ACAccount, text: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ())
    func usernameForAccount(_ account: ACAccount) -> String
}
