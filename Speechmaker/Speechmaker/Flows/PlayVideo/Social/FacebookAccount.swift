//
//  FacebookAccount.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/18/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import Accounts
import Social

let FACEBOOK_API_URL = URL(string: "https://graph-video.facebook.com/v2.3/me/videos")

// Based on https://github.com/liu044100/SocialVideoHelper/blob/master/SocialVideoHelper.m
class FacebookAccount : SocialAccount {
    let accountStore: ACAccountStore = ACAccountStore()
    var accountType: ACAccountType {
        return accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierFacebook)
    }
    var name = "Facebook"
    
    func getAccounts(_ success: @escaping (_ accounts: [ACAccount]) -> (), failure: @escaping (_ error: NSError) -> ()) {
        guard SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) else {
            let error = SpeechmakerError(code: 666, localizedDescription: "You have no Facebook accounts for this device. Please go to your iOS settings and sign in to your account.")
            failure(error)
            return
        }
        
        let accounts = accountStore.accounts(with: accountType) as? [ACAccount]
        if (accounts != nil && accounts!.count > 0) {
            success(accounts!)
        } else {
            self.requestReadPermissions({
                self.requestWritePermissions({
                    dispatch_main {
                        let accounts = self.accountStore.accounts(with: self.accountType) as! [ACAccount]
                        success(accounts)
                    }
                }, failure: failure)
            }, failure: failure)
        }
    }
    
    func usernameForAccount(_ account: ACAccount) -> String {
        return account.userFullName
    }
    
    func postVideo(_ videoData: Data, account: ACAccount, text: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        self.renewCredentials(account, success: {
            self.postVideoStage1(videoData, account: account, text: text, success: { (uploadSessionId) in
                self.postVideoStage2(videoData, account: account, text: text, uploadSessionId: uploadSessionId, success: { () in
                    self.postVideoStage3(videoData, account: account, text: text, uploadSessionId: uploadSessionId, success: success, failure: failure)
                }, failure: failure)
            }, failure: failure)
        }, failure: failure)
    }
    
    fileprivate func postVideoStage1(_ videoData: Data, account: ACAccount, text: String, success: @escaping (_ uploadSessionId: String) -> (), failure: @escaping (_ error: NSError) -> ()) {
        let parameters = ["access_token" : account.credential.oauthToken,
                          "upload_phase" : "start",
                          "file_size" : String(videoData.count)]
        let postVideoRequest = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: .POST, url: FACEBOOK_API_URL, parameters: parameters)
        postVideoRequest?.account = account
        postVideoRequest?.perform { (responseData, urlResponse, error) in
            if (error != nil) {
                log("FAILED IN STAGE 1")
                failure(error as! NSError)
            } else {
                let json = JSON(data: responseData!)
                if (json["error"].exists()) {
                    log("FAILED IN STAGE 1")
                    failure(SpeechmakerError(code: 666, localizedDescription: "An unknown error has occurred uploading your video"))
                    return;
                }
                
                let uploadSessionId = json["upload_session_id"].string!
                success(uploadSessionId)
            }
        }
    }
    
    fileprivate func postVideoStage2(_ videoData: Data, account: ACAccount, text: String, uploadSessionId: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        let parameters = ["access_token" : account.credential.oauthToken,
                          "upload_phase" : "transfer",
                          "start_offset" : "0",
                          "upload_session_id" : uploadSessionId]
        let postVideoRequest = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: .POST, url: FACEBOOK_API_URL, parameters: parameters)
        postVideoRequest?.account = account
        postVideoRequest?.addMultipartData(videoData, withName: "video_file_chunk", type: "video/mp4", filename: "video")
        postVideoRequest?.perform { (responseData, urlResponse, error) in
            if (error != nil) {
                log("FAILED IN STAGE 2")
                failure(error as! NSError)
            } else {
                success()
            }
        }
    }

    fileprivate func postVideoStage3(_ videoData: Data, account: ACAccount, text: String, uploadSessionId: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        let parameters = ["access_token" : account.credential.oauthToken,
                          "upload_phase" : "finish",
                          "description" : text,
                          "upload_session_id" : uploadSessionId]
        let postVideoRequest = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: .POST, url: FACEBOOK_API_URL, parameters: parameters)
        postVideoRequest?.account = account
        postVideoRequest?.perform { (responseData, urlResponse, error) in
            if (error != nil) {
                log("FAILED IN STAGE 3")
                failure(error as! NSError)
            } else {
                success()
            }
        }
    }
    
    fileprivate func requestReadPermissions(_ success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        let options: [AnyHashable: Any] = [ACFacebookAudienceKey : ACFacebookAudienceOnlyMe,
                                               ACFacebookAppIdKey : FACEBOOK_APP_ID,
                                               ACFacebookPermissionsKey : ["basic_info"]]
        self.accountStore.requestAccessToAccounts(with: accountType, options: options) { (wasGranted, error) in
            if (wasGranted && error == nil) {
                success()
            } else if !wasGranted {
                let permissionsError = SpeechmakerError(code: 662, localizedDescription: "You must allow " + SPEECHMAKER_APP_NAME + " the requested permissions to your Facebook account in order to post this video.")
                failure(permissionsError)
            } else {
                failure(error as! NSError)
            }
        }
    }
    
    fileprivate func requestWritePermissions(_ success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        let options: [AnyHashable: Any] = [ACFacebookAudienceKey : ACFacebookAudienceEveryone,
                                               ACFacebookAppIdKey : FACEBOOK_APP_ID,
                                               ACFacebookPermissionsKey : ["publish_actions"]]
        self.accountStore.requestAccessToAccounts(with: accountType, options: options) { (wasGranted, error) in
            if (wasGranted && error == nil) {
                success()
            } else if !wasGranted {
                let permissionsError = SpeechmakerError(code: 662, localizedDescription: "You must allow " + SPEECHMAKER_APP_NAME + " the requested permissions to your Facebook account in order to post this video.")
                failure(permissionsError)
            } else {
                failure(error as! NSError)
            }
        }
    }
    
    fileprivate func renewCredentials(_ account: ACAccount, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        self.accountStore.renewCredentials(for: account) { (renewResult, error) in
            if (error == nil) {
                switch(renewResult) {
                case .renewed:
                    success()
                case .rejected:
                    let error = SpeechmakerError(code: 300, localizedDescription: "User renewal rejected")
                    failure(error)
                case .failed:
                    let error = SpeechmakerError(code: 301, localizedDescription: "User renewal failed")
                    failure(error)
                }
            } else {
                failure(error as! NSError)
            }
        }
    }
}
