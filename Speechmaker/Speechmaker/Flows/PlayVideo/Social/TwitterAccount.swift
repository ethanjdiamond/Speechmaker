//
//  TwitterAccount.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/18/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import Accounts
import Social

let TWITTER_API_UPLOAD_VIDEO_URL = URL(string: "https://upload.twitter.com/1.1/media/upload.json")
let TWITTER_API_TWEET_URL = URL(string: "https://api.twitter.com/1.1/statuses/update.json")
let MAX_VIDEO_CHUNK_SIZE = 1000 * 1000

class TwitterAccount: SocialAccount {
    let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    let accountStore: ACAccountStore = ACAccountStore()
    var accountType: ACAccountType {
        return accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
    }
    var name = "Twitter"
    
    func getAccounts(_ success: @escaping (_ accounts: [ACAccount]) -> (), failure: @escaping (_ error: NSError) -> ()) {
        guard SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) else {
            let error = SpeechmakerError(code: 666, localizedDescription: "You have no Twitter accounts for this device. Please go to your iOS settings and sign in to your account.")
            failure(error)
            return
        }
        
        let accounts = accountStore.accounts(with: accountType) as? [ACAccount]
        if (accounts != nil && accounts!.count > 0) {
            success(accounts!)
        } else {
            self.accountStore.requestAccessToAccounts(with: accountType, options: nil) { (wasGranted, error) in
                if (wasGranted && error == nil) {
                    let accounts = self.accountStore.accounts(with: self.accountType) as! [ACAccount]
                    dispatch_main {
                        success(accounts)
                    }
                } else if !wasGranted {
                    let permissionsError = SpeechmakerError(code: 662, localizedDescription: "You must allow " + SPEECHMAKER_APP_NAME + " applicable permissions to your Twitter account in order to post this video.")
                    failure(permissionsError)
                } else {
                    failure(error as! NSError)
                }
            }
        }
    }
    
    func usernameForAccount(_ account: ACAccount) -> String {
        return account.accountDescription
    }
    
    // Based on https://github.com/liu044100/SocialVideoHelper/blob/master/SocialVideoHelper.m
    func postVideo(_ videoData: Data, account: ACAccount, text: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        postVideoStage1(videoData, account: account, text: text, success: { (mediaId) in
            self.postVideoStage2(videoData, account: account, text: text, mediaId: mediaId, success: {
                self.postVideoStage3(videoData, account: account, text: text, mediaId: mediaId, success: {
                    self.postVideoStage4(videoData, account: account, text: text, mediaId: mediaId, success: {
                        self.postVideoStage5(videoData, account: account, text: text, mediaId: mediaId, success: success,
                                failure: failure)
                        }, failure: failure)
                }, failure: failure)
            }, failure: failure)
        }, failure: failure)
    }
    
    func postVideoStage1(_ videoData: Data, account: ACAccount, text: String, success: @escaping (_ mediaId: String) -> (), failure: @escaping (_ error: NSError) -> ()) {
        log("STAGE 1")
        let parameters = ["command" : "INIT",
                          "total_bytes" : String(videoData.count),
                          "media_type" : "video/mp4",
                          "media_category" : "tweet_video"]
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: TWITTER_API_UPLOAD_VIDEO_URL, parameters: parameters)
        request?.account = account
        request?.perform { (responseData, urlResponse, error) in
            if (error != nil) {
                log("FAILED IN STAGE 1")
                failure(error as! NSError)
            } else {
                let json = JSON.parse(String(data: responseData!, encoding: String.Encoding.utf8)!)
                let mediaIdString = json["media_id_string"].string!
                success(mediaIdString)
            }
        }
    }
    
    func postVideoStage2(_ videoData: Data, account: ACAccount, text: String, mediaId: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        log("STAGE 2")
        let chunks = separateToMultipartData(videoData)
        for (index, chunk) in chunks.enumerated() {
            log("APPENDING CHUNK")
            operationQueue.addOperation {
                let parameters = ["command" : "APPEND",
                                  "media_id" : mediaId,
                                  "segment_index" : String(index)]
                let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: TWITTER_API_UPLOAD_VIDEO_URL, parameters: parameters)
                let semaphore = DispatchSemaphore(value: 0);
                request?.account = account
                request?.addMultipartData(chunk, withName: "media", type: "video/mp4", filename: "video")
                request?.perform { (responseData, urlResponse, error) in
                    log(String(data: responseData!, encoding: String.Encoding.utf8)!)
                    if (error != nil) {
                        log("FAILED IN STAGE 2")
                        self.operationQueue.cancelAllOperations()
                        failure(error as! NSError)
                    } else  {
                        semaphore.signal();
                    }
                }
                let _ = semaphore.wait(timeout: DispatchTime.distantFuture);
            }
        }
        
        operationQueue.addOperation { 
            success()
        }
    }
    
    func postVideoStage3(_ videoData: Data, account: ACAccount, text: String, mediaId: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        log("STAGE 3")
        let parameters = ["command" : "FINALIZE",
                          "media_id" : mediaId]
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: TWITTER_API_UPLOAD_VIDEO_URL, parameters: parameters)
        request?.account = account
        request?.perform { (responseData, urlResponse, error) in
            log(String(data: responseData!, encoding: String.Encoding.utf8)!)
            if (error != nil) {
                log("FAILED IN STAGE 3")
                failure(error as! NSError)
            } else {
                success()
            }
        }
    }
    
    func postVideoStage4(_ videoData: Data, account: ACAccount, text: String, mediaId: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        log("STAGE 4")
        let parameters = ["command" : "STATUS",
                          "media_id" : mediaId]
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, url: TWITTER_API_UPLOAD_VIDEO_URL, parameters: parameters)
        request?.account = account
        request?.perform { (responseData, urlResponse, error) in
            if (error != nil) {
                log("FAILED IN STAGE 4")
                failure(error as! NSError)
            } else {
                log(String(data: responseData!, encoding: String.Encoding.utf8)!)
                let json = JSON.parse(String(data: responseData!, encoding: String.Encoding.utf8)!)
                let state = json["processing_info"]["state"].string!
                if state == "in_progress" {
                    let secs = json["processing_info"]["check_after_secs"].double!
                    log("RETRYING STAGE 4 after \(secs) SECONDS")
                    delay(secs, closure: {
                        self.postVideoStage4(videoData, account: account, text: text, mediaId: mediaId, success: success, failure: failure)
                    })
                } else if state == "succeeded" {
                    success()
                } else {
                    failure(SpeechmakerError(code: 1923, localizedDescription: "There was an error posting your video to Twitter."))
                }
            }
        }
    }
    
    func postVideoStage5(_ videoData: Data, account: ACAccount, text: String, mediaId: String, success: @escaping () -> (), failure: @escaping (_ error: NSError) -> ()) {
        log("STAGE 5")
        let parameters: [AnyHashable: Any] = ["status" : text,
                                              "media_ids" : [mediaId]]
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: TWITTER_API_TWEET_URL, parameters: parameters)
        request?.account = account
        request?.perform { (responseData, urlResponse, error) in
            log(String(data: responseData!, encoding: String.Encoding.utf8)!)
            if (error != nil) {
                log("FAILED IN STAGE 5")
                failure(error as! NSError)
            } else {
                let json = JSON.parse(String(data: responseData!, encoding: String.Encoding.utf8)!)
                if (json["errors"] != nil) {
                    failure(SpeechmakerError(code: 1923, localizedDescription: "There was an error posting your video to Twitter."))
                    return
                }
                success()
            }
        }
    }
    
    func separateToMultipartData(_ data: Data) -> [Data] {
        var multipartData: [Data] = []
        if (data.count <= MAX_VIDEO_CHUNK_SIZE) {
            multipartData.append(data)
        } else {
            let chunkCount = Int(ceil(Float(data.count) / Float(MAX_VIDEO_CHUNK_SIZE)))
            for index in 0..<chunkCount {
                let start = index * MAX_VIDEO_CHUNK_SIZE
                let range: Range<Int> = start..<start + min(MAX_VIDEO_CHUNK_SIZE, data.count - start)
                let subData = data.subdata(in: range)
                multipartData.append(subData)
            }
        }
        
        return multipartData
    }
}
