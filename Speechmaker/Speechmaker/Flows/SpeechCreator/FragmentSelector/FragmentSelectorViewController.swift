//
//  FragmentSelectorViewController.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/4/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import MagicalRecord

private let PAUSE_SENTINAL = "\u{200B}"
private let SCROLL_VIEW_CONTENT_INSET: CGFloat = 20

class FragmentSelectorViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var noWordsFoundLabel: UILabel!
    
    var isDisabled = false
    var delegate: FragmentSelectorViewControllerDelegate!
    var fragments: [Fragment] = []
    
    func giveFocus() {
        self.textView.becomeFirstResponder()
    }
    
    // MARK: CollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fragments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FragmentSelectorCollectionViewCell", for: indexPath) as! FragmentSelectorCollectionViewCell
        cell.fragment = fragments[(indexPath as NSIndexPath).row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.fragmentSelectorViewControllerDelegateDidSelectFragment(fragments[(indexPath as NSIndexPath).row])
        textView.text = ""
        view.isHidden = true
    }

    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        view.isHidden = textView.text.characters.count == 0
        if (textView.text == PAUSE_SENTINAL) {
            fragments = Pause.mr_findAll() as! [Pause]
        } else {
            let fetchRequest = Word.mr_createFetchRequest()
            fetchRequest.predicate = NSPredicate(format: "alphanumericText BEGINSWITH[cd] %@", textView.text)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true, selector:#selector(NSString.caseInsensitiveCompare(_:)))]
            fragments = Word.mr_executeFetchRequest(fetchRequest) as! [Word]
        }
        
        noWordsFoundLabel.isHidden = fragments.count > 0
        
        self.collectionView.reloadData()
        self.collectionView.contentOffset = CGPoint.zero
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        let inset = self.collectionView.collectionViewLayout.collectionViewContentSize.height > self.collectionView.frame.size.height ? SCROLL_VIEW_CONTENT_INSET : 0;
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, inset, 0)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // If it's not just one character changing for whatever reason
        if (text.characters.count >= 2) {
            return false
        // If delete is tapped and there's no text, we should delete a word
        } else if (NSEqualRanges(range, NSMakeRange(0, 0)) && text.characters.count == 0) {
            self.delegate.fragmentSelectorViewControllerDelegateDidDeleteFragment()
            return true
        // If it's disabled
        } else if (isDisabled) {
            return false
        // Otherwise let the delete go through
        } else if (range.length == 1 && text.characters.count == 0) {
            return true
        // Cap the characters
        } else if (textView.text.characters.count > 8) {
            return false
        // If it's punctuation
        } else if (text.containsCharactersFromSet(CharacterSet.punctuationCharacters) || text == " ") {
            if (textView.text.characters.count == 0) {
                textView.text = PAUSE_SENTINAL
                textViewDidChange(textView)
            }
            return false
        // If we're already in pause mode
        } else if (textView.text == PAUSE_SENTINAL) {
            return false
        // Only allow alphanumeric
        } else if (text.containsCharactersFromSet(CharacterSet.letters)) {
            return true
        }
        
        return false
    }
}

protocol FragmentSelectorViewControllerDelegate {
    func fragmentSelectorViewControllerDelegateDidSelectFragment(_ fragment: Fragment)
    func fragmentSelectorViewControllerDelegateDidDeleteFragment()
}
