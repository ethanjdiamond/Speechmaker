//
//  VideoDownloadManager.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/7/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import Crashlytics

private let DOWNLOAD_FOLDER = NSTemporaryDirectory() + "videos/"

class VideoDownloadManager {
    fileprivate lazy var operationQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download video queue"
        queue.maxConcurrentOperationCount = 5
        return queue
    }()
    
    init() {
        FileManager.default.createDirectoryAtPathIfNotPresent(DOWNLOAD_FOLDER)
    }
    
    func downloadVideo(_ fragmentVideo: FragmentVideo, success: (() -> ())? = nil, failure: ((_ fragmentVideo: FragmentVideo, _ error: NSError) -> ())? = nil) {
        operationQueue.addOperation {
            var didSucceed = false
            let semaphore = DispatchSemaphore(value: 0)
            SpeechmakerService.instance.getFragmentVideo(fragmentVideo, downloadFolder: DOWNLOAD_FOLDER, success: { (FragmentVideo) in
                didSucceed = true
                semaphore.signal()
            }, failure: { (error) in
                log("Failed downloading \"\(fragmentVideo.fragment.text!)\"")
                Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] Failed Downloading Fragment", customAttributes: ["error" : error.localizedDescription, "fragment" : fragmentVideo.fragment.text])
                failure?(fragmentVideo, error)
                semaphore.signal()
            })
            let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            
            if (didSucceed) {
                success?()
            }
        }
    }
    
    func downloadVideos(_ fragmentVideos: [FragmentVideo], progress:((_ progress: Float) -> ())? = nil, success: (() -> ())? = nil, failure: ((_ fragmentVideo: FragmentVideo, _ error: NSError) -> ())? = nil) {
        for fragmentVideo in fragmentVideos {
            downloadVideo(fragmentVideo, success: {
                progress?(max(0, Float(fragmentVideos.count - self.operationQueue.operationCount)) / Float(fragmentVideos.count))
                if (self.operationQueue.operationCount == 1) { // 1 left means this is the last one
                    success?()
                }
            }, failure: { (fragmentVideo, error) in
                self.cancelOperations()
                failure?(fragmentVideo, error)
            })
        }
    }
    
    func cancelOperations() {
        operationQueue.cancelAllOperations()
    }
    
    func clearCachedVideos() {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: DOWNLOAD_FOLDER)
        while let file = enumerator?.nextObject() as? String {
            try! fileManager.removeItem(atPath: DOWNLOAD_FOLDER + file)
        }
    }
    
    func clearCachedVideo(_ fragmentVideo: FragmentVideo) {
        if (fragmentVideo.localURL != nil) {
            try! FileManager.default.removeItem(atPath: fragmentVideo.localURL!.path)
        }
    }
}
