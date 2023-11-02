//
//  VideoLoadingViewController.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/13/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

let OUTPUT_PATH = NSTemporaryDirectory() + "complete.mp4"
let SHARE_TMP_OUTPUT_PATH = NSTemporaryDirectory() + "tmp.mp4"
let SHARE_OUTPUT_PATH = NSTemporaryDirectory() + "trump_speechmaker.mp4"

class VideoLoadingViewController: UIViewController {
    @IBOutlet var loadingView: LoadingView!
    @IBOutlet var loadingLabel: UILabel!

    fileprivate var videoDownloadManager: VideoDownloadManager!
    fileprivate lazy var videoCombiner = VideoCombiner()
    fileprivate lazy var shareVideoCombiner = VideoCombiner()
    fileprivate lazy var mp4Converter = MP4Converter()
    var downloadProgress: Float = 0 { didSet { updateProgress() } }
    var combineProgress: Float = 0 { didSet { updateProgress() } }
    var combineShareProgress: Float = 0 { didSet { updateProgress() } }
    var convertProgress: Float = 0 { didSet { updateProgress() } }
    
    func loadFragmentVideos(_ fragmentVideos: [FragmentVideo], videoDownloadManager: VideoDownloadManager, success: @escaping (_ outputPath: String, _ shareOutputPath: String) -> (), failure: @escaping (_ fragmentVideo: FragmentVideo, _ error: NSError) -> ()) {
        
        self.videoDownloadManager = videoDownloadManager
        FileManager.default.removeItemAtPathIfPresent(OUTPUT_PATH)
        
        downloadVideos(fragmentVideos, success: {
            self.combineVideos(fragmentVideos, success: {
                self.combineVideosForShare(fragmentVideos, success: { 
                    self.convertVideo(URL(fileURLWithPath: SHARE_TMP_OUTPUT_PATH), success: {
                        success(OUTPUT_PATH, SHARE_OUTPUT_PATH)
                    })
                })
            })
        }, failure: failure)
    }
    
    fileprivate func downloadVideos(_ fragmentVideos: [FragmentVideo], success: @escaping () -> (), failure: @escaping (_ fragmentVideo: FragmentVideo, _ error: NSError) -> ()) {
        videoDownloadManager.downloadVideos(fragmentVideos, progress: { (progress) in
            self.downloadProgress = progress
        }, success: { [weak self] in
            self?.downloadProgress = 1
            success()
        }, failure: failure)
    }
    
    fileprivate func combineVideos(_ fragmentVideos: [FragmentVideo], success: @escaping () -> ()) {
        let urls = fragmentVideos.map { (fragmentVideo) -> URL in fragmentVideo.localURL!}
        videoCombiner.combineVideos(urls, outputPath: OUTPUT_PATH, progress: { [weak self] (progress) in
            self?.combineProgress = progress
        }, complete: { [weak self] in
            self?.combineProgress = 1
            success()
        })
    }
    
    fileprivate func combineVideosForShare(_ fragmentVideos: [FragmentVideo], success: @escaping () -> ()) {
        var urls = fragmentVideos.map { (fragmentVideo) -> URL in fragmentVideo.localURL!}
        urls.append(Bundle.main.url(forResource: "mark", withExtension: "mp4")!)
        shareVideoCombiner.combineVideos(urls, outputPath: SHARE_TMP_OUTPUT_PATH, progress: { [weak self] (progress) in
            self?.combineShareProgress = progress
        }, complete: { [weak self] in
            self?.combineShareProgress = 1
            success()
        })
    }
    
    fileprivate func convertVideo(_ url: URL, success: @escaping () -> ()) {
        mp4Converter.convertVideo(url, outputPath: SHARE_OUTPUT_PATH, progress: { [weak self] (progress) in
            self?.convertProgress = progress
        }, complete: { [weak self] in
            self?.convertProgress = 1
            success()
        })
    }
    
    fileprivate func updateProgress() {
        let progress = Float(downloadProgress + combineProgress + combineShareProgress + convertProgress) / 4.0
        dispatch_main {
            self.loadingView.progress = progress
            self.loadingLabel.text = String.localizedStringWithFormat("%.0f", floor(progress * 100))
        }
    }
}
