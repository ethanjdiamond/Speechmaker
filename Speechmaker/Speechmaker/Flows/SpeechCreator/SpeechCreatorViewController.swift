//
//  SpeechCreatorViewController.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/3/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

private let SCROLL_VIEW_CONTENT_INSET: CGFloat = 20
private let MAX_WORD_COUNT = 100

class SpeechCreatorViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, FragmentSelectorViewControllerDelegate {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var collectionViewBottomLayout: NSLayoutConstraint!
    @IBOutlet var speechBubbleView: UIView!
    @IBOutlet var speechBubbleViewHeightLayout: NSLayoutConstraint!
    @IBOutlet var topBarView: UIView!
    @IBOutlet var topBarViewBottomLayout: NSLayoutConstraint!
    @IBOutlet var notConnectedView: UIView!
    @IBOutlet var countdownLabel: UILabel!
    let videoDownloadManager = VideoDownloadManager()
    var fragmentSelectorViewController: FragmentSelectorViewController!
    var fragmentVideos: [FragmentVideo?] = [nil] // The word video with a nil value is the cursor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SpeechCreatorViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SpeechCreatorViewController.willEnterForeground(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SpeechCreatorViewController.reachabilityStatusDidChange(_:)), name: ReachabilityChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SpeechCreatorViewController.willEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        // Set up fragment selector
        fragmentSelectorViewController = self.storyboard!.instantiateViewController(withIdentifier: "FragmentSelectorViewController") as! FragmentSelectorViewController
        fragmentSelectorViewController.delegate = self
        fragmentSelectorViewController.view.isHidden = true
        view.addSubview(fragmentSelectorViewController.view)
        fragmentSelectorViewController.giveFocus()
        
        // Add inset
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, SCROLL_VIEW_CONTENT_INSET, 0)
        
        // Round the speech bubble
        speechBubbleView.layer.cornerRadius = 12.0
        speechBubbleView.layer.masksToBounds = true
        
        // Shadow for the top bar on scroll
        topBarView.layer.shadowColor = UIColor.black.cgColor
        topBarView.layer.shadowOffset = CGSize(width: 0, height: 5)
        topBarView.layer.shadowOpacity = 0.0
        topBarView.layer.shadowRadius = 3
        
        reloadViewController(animateTopBar: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fragmentSelectorViewController.giveFocus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reachabilityStatusDidChange(nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: UIScrollView
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == self.scrollView) {
            topBarView.layer.shadowOpacity = min(0.2, Float(scrollView.contentOffset.y / 100))
        }
    }
    
    // MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fragmentVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (fragmentVideos[(indexPath as NSIndexPath).row] == nil) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "SpeechCreatorCursorCollectionViewCell", for: indexPath) as! SpeechCreatorCursorCollectionViewCell
        } else if (fragmentVideos[(indexPath as NSIndexPath).row]!.fragment is Pause) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "SpeechCreatorPauseCollectionViewCell", for: indexPath) as! SpeechCreatorPauseCollectionViewCell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpeechCreatorWordCollectionViewCell", for: indexPath) as! SpeechCreatorWordCollectionViewCell
            cell.word = fragmentVideos[(indexPath as NSIndexPath).row]?.fragment as? Word
            return cell
        }
    }
    
    // MARK: FragmentSelectorViewControllerDelegate
    
    func fragmentSelectorViewControllerDelegateDidSelectFragment(_ fragment: Fragment) {
        let fragmentVideo = FragmentVideo(fragment: fragment)
        fragmentVideos.insert(fragmentVideo, at: getCursorIndex())
        videoDownloadManager.downloadVideo(fragmentVideo)
        reloadViewController(animateTopBar: true)
    }
    
    func fragmentSelectorViewControllerDelegateDidDeleteFragment() {
        let cursorIndex = getCursorIndex()
        if (cursorIndex > 0) {
            let fragmentVideo = fragmentVideos.remove(at: getCursorIndex() - 1)
            videoDownloadManager.clearCachedVideo(fragmentVideo!)
            reloadViewController(animateTopBar: true)
        }
    }
    
    // MARK: IBAction
    
    @IBAction func doneButtonWasTapped() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "PlayVideoViewController") as! PlayVideoViewController
        controller.fragmentVideos = fragmentVideos.filter { $0 != nil }.flatMap { $0 }
        controller.videoDownloadManager = videoDownloadManager
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func clearButtonWasTapped() {
        UIView.animate(withDuration:
            
            0.3, animations: {
            self.scrollView.contentOffset = CGPoint.zero
        }, completion: { (_) in
            self.fragmentVideos = [nil]
            self.videoDownloadManager.clearCachedVideos()
            self.reloadViewController(animateTopBar: true)
        })
    }
    
    // MARK: Convenience
    
    fileprivate func getCursorIndex() -> Int {
        return fragmentVideos.index { return $0 == nil }!
    }
    
    fileprivate func reloadViewController(animateTopBar: Bool) {
        if (animateTopBar) {
            UIView.animate(withDuration: 0.5, animations: {
                self.topBarViewBottomLayout.constant = (self.fragmentVideos.count > 1) ? 0 : self.topBarView.frame.size.height
                self.topBarView.superview?.layoutIfNeeded()
            })
        }
        
        collectionView.reloadData()
        
        countdownLabel.text = "\(MAX_WORD_COUNT - fragmentVideos.count + 1)"
        fragmentSelectorViewController.isDisabled = fragmentVideos.count > MAX_WORD_COUNT
        
        self.speechBubbleViewHeightLayout.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height
        self.speechBubbleView.superview?.layoutIfNeeded()
        self.scrollView.contentSize = CGSize(width: self.scrollView.contentSize.width, height: self.speechBubbleView.frame.maxY)
        
        let bottomOffset = CGPoint(x: 0, y: max(0, self.scrollView.contentSize.height + self.scrollView.contentInset.bottom - self.scrollView.bounds.size.height))
        self.scrollView.setContentOffset(bottomOffset, animated: true)
    }
    
    // MARK: Notification Handlers
    
    @objc fileprivate func keyboardDidShow(_ notification: Notification) {
        // We need to shrink the scrollview to the top of the keyboard
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        collectionViewBottomLayout.constant = keyboardHeight
        fragmentSelectorViewController.view.frame.size.height = self.view.frame.size.height - keyboardHeight
    }
    
    @objc fileprivate func reachabilityStatusDidChange(_ notification: Notification?) {
        self.notConnectedView.isHidden = Reachability.instance.isReachable
    }
    
    @objc fileprivate func willEnterForeground(_ notification: Notification) {
        if navigationController?.topViewController == self {
            fragmentSelectorViewController.giveFocus()
        }
    }
}
