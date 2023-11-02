//
//  SpeechmakerService.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/7/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import Alamofire
import Crashlytics

private let BASE_URL = SPEECHMAKER_API_BASE_URL + "/" + SPEECHMAKER_API_STAGE + "/" + API_FOLDER_NAME + "/"
private let FRAGMENTS_URL = BASE_URL + "fragments/"

class SpeechmakerService {
    static let instance = SpeechmakerService()
    
    fileprivate init() {}
    
    func getFragments(_ complete: @escaping (_ words: [String], _ pauses: [String]) -> (), failure: @escaping (_ error: NSError) -> ()) {
        Alamofire.request(FRAGMENTS_URL
            ).responseJSON { response in
            guard response.result.isSuccess else {
                log("Service call to " + FRAGMENTS_URL + " failed")
                failure(response.result.error! as NSError)
                return
            }
            
            let json = JSON(response.result.value!)
            if json["words"] != nil && json["pauses"] != nil {
                let words = json["words"].arrayValue.map { $0.string! }
                let pauses = json["pauses"].arrayValue.map { $0.string! }
                complete(words, pauses)
            } else {
                failure(SpeechmakerError(code: 68, localizedDescription: "Fragment download failed due to unanticipated response"))
            }
        }
    }
    
    func getFragmentVideo(_ fragmentVideo: FragmentVideo, downloadFolder: String, success: @escaping (_ fragmentVideo: FragmentVideo) -> (), failure: @escaping (_ error: NSError) -> ()) {
        if (fragmentVideo.url == nil) {
            downloadUrl(fragmentVideo, downloadFolder: downloadFolder, success: { (FragmentVideo) in
                self.downloadVideo(fragmentVideo, downloadFolder: downloadFolder, success: success, failure: failure)
            }, failure: failure)
        } else {
            self.downloadVideo(fragmentVideo, downloadFolder: downloadFolder, success: success, failure: failure)
        }
    }
    
    fileprivate func downloadUrl(_ fragmentVideo: FragmentVideo, downloadFolder: String, success: @escaping (_ fragmentVideo: FragmentVideo) -> (), failure: @escaping (_ error: NSError) -> ()) {
        // Download the word url
        let url = FRAGMENTS_URL + fragmentVideo.fragment.apiUrlFolder + "/" + fragmentVideo.fragment.text!
        Alamofire.request(url).responseJSON { response in
            guard response.result.isSuccess else {
                log("Service call to " + url + " failed")
                failure(response.result.error! as NSError)
                return
            }
            
            let json = JSON(response.result.value!)
            let urlString = json["url"].string
            
            if let urlString = urlString {
                fragmentVideo.url = URL(string: urlString)
                fragmentVideo.localURL = URL(fileURLWithPath: downloadFolder + fragmentVideo.fragment.text! + "/" + fragmentVideo.url!.lastPathComponent)
                success(fragmentVideo)
            } else {
                failure(SpeechmakerError(code: 67, localizedDescription: "Url download failed due to unanticipated response"))
            }
        }
    }
    
    fileprivate func downloadVideo(_ fragmentVideo: FragmentVideo, downloadFolder: String, success: @escaping (_ fragmentVideo: FragmentVideo) -> (), failure: @escaping (_ error: NSError) -> ()) {
        FileManager.default.createDirectoryAtPathIfNotPresent(fragmentVideo.localURL!.deletingLastPathComponent().path)
        
        // If it doesn't exist, try to download it, otherwise mark it as complete
        if (!FileManager.default.fileExists(atPath: fragmentVideo.localURL!.path)) {
            Alamofire.download(fragmentVideo.url!, to: { (_, _) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                (destinationURL: fragmentVideo.localURL!, options: .createIntermediateDirectories)
            }).downloadProgress(closure: { (progress) in
                fragmentVideo.downloadProgress = Float(progress.fractionCompleted)
            }).response(completionHandler: { (response) in
                guard response.error == nil else {
                    // This means it tried to download to somewhere that already has it. We should ignore that since it's there already.
                    if (response.error! as NSError).code == 516 {
                        success(fragmentVideo)
                        return
                    }
                    
                    failure(response.error! as NSError)
                    return
                }
                
                let contentType = response.response?.allHeaderFields["Content-Type"] as? String
                if let contentType = contentType {
                    if (contentType == "video/mp4") {
                        log("Succeeded downloading \"\(fragmentVideo.fragment.text!)\"")
                        success(fragmentVideo)
                        return
                    }
                }
                
                try! FileManager.default.removeItem(at: fragmentVideo.localURL!)
                failure(SpeechmakerError(code: 42, localizedDescription: "Tried to download a video that was not a video (\(contentType))"))
            })
        } else {
            fragmentVideo.downloadProgress = 1.0
            log("Already cached \"\(fragmentVideo.fragment.text!)\"")
            success(fragmentVideo)
        }
    }
}
