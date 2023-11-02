//
//  SpeechCreatorCollectionViewLayout.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/12/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

private let TOP_COLLECTION_VIEW_PADDING: CGFloat = 15.0
private let BOTTOM_COLLECTION_VIEW_PADDING: CGFloat = 2.0
private let SIDE_COLLECTION_VIEW_PADDING: CGFloat = 10.0
private let CELL_HEIGHT: CGFloat = 24.0
private let MIN_CELL_WIDTH: CGFloat = 21.0
private let HORIZONTAL_CELL_PADDING: CGFloat = 8.0
private let VERTICAL_CELL_SPACING: CGFloat = 6.0
private let HORIZONTAL_CELL_SPACING: CGFloat = 2.0

class SpeechCreatorCollectionViewLayout: UICollectionViewLayout {
    var collectionViewLayoutAttributes: [UICollectionViewLayoutAttributes] = []
    lazy var font: UIFont = UIFont(name: "Helvetica", size: 12.0)!
    var collectionViewWidth: CGFloat {
        get {
            return self.collectionView!.frame.size.width
        }
    }
    
    override var collectionViewContentSize : CGSize {
        var height: CGFloat = CELL_HEIGHT
        if let lastLayoutAttributes = self.collectionViewLayoutAttributes.last {
            height = max(height, lastLayoutAttributes.frame.maxY)
        }

        return CGSize(width: collectionViewWidth, height: height + TOP_COLLECTION_VIEW_PADDING + BOTTOM_COLLECTION_VIEW_PADDING)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return collectionViewLayoutAttributes.filter {rect.intersects($0.frame)}
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return collectionViewLayoutAttributes[(indexPath as NSIndexPath).item]
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        
        collectionViewLayoutAttributes = []
        
        let fragmentVideos = (collectionView!.dataSource as! SpeechCreatorViewController).fragmentVideos
        
        var cellX = SIDE_COLLECTION_VIEW_PADDING
        var cellY = TOP_COLLECTION_VIEW_PADDING
        for (index, fragmentVideo) in fragmentVideos.enumerated() {
            let cellWidth = cellWidthForFragment(fragmentVideo?.fragment)
            if (cellX + cellWidth > collectionViewWidth - (2 * HORIZONTAL_CELL_SPACING)) {
                cellX = SIDE_COLLECTION_VIEW_PADDING
                cellY += CELL_HEIGHT + VERTICAL_CELL_SPACING
            }
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
            attributes.frame = CGRect(x: cellX, y: cellY, width: cellWidth, height: CELL_HEIGHT)
            collectionViewLayoutAttributes.append(attributes)
            
            cellX += cellWidth + HORIZONTAL_CELL_SPACING
        }
    }
    
    private func cellWidthForFragment(_ fragment: Fragment?) -> CGFloat {
        if fragment == nil {
            return MIN_CELL_WIDTH
        } else if fragment!.isKind(of: Pause.self) {
            return (fragment?.text == "long") ? MIN_CELL_WIDTH * 2 : MIN_CELL_WIDTH
        } else {
            let wordWidth = (fragment!.text! as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height:CELL_HEIGHT),
                                                                               options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                                               attributes: [NSFontAttributeName: font],
                                                                               context: nil).width
            return max(MIN_CELL_WIDTH, wordWidth + (2 * HORIZONTAL_CELL_PADDING))
        }
    }
}
