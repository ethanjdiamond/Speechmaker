//
//  FragmentSelectorCollectionViewLayout.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/9/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit

private let CELL_HEIGHT: CGFloat = 41.0
private let MIN_CELL_WIDTH: CGFloat = 41.0
private let HORIZONTAL_CELL_SPACING: CGFloat = 10.0
private let VERTICAL_CELL_SPACING: CGFloat = 10.0
private let HORIZONTAL_CELL_PADDING: CGFloat = 8.0

class FragmentSelectorCollectionViewLayout: UICollectionViewLayout {
    var collectionViewLayoutAttributes: [UICollectionViewLayoutAttributes] = []
    lazy var font: UIFont = UIFont(name: "Helvetica", size: 25.0)!
    var collectionViewWidth: CGFloat {
        get {
            return self.collectionView!.frame.size.width
        }
    }
    
    override var collectionViewContentSize : CGSize {
        var height: CGFloat = self.collectionView!.frame.height
        if let lastLayoutAttributes = self.collectionViewLayoutAttributes.last {
            height = max(height, lastLayoutAttributes.frame.maxY)
        }
        
        return CGSize(width: collectionViewWidth, height: height)
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
        
        let fragments = (collectionView!.dataSource as! FragmentSelectorViewController).fragments
        
        guard fragments.count > 0 else {
            return
        }
        
        var currentRow: [UICollectionViewLayoutAttributes] = []
        var currentRowIndex = 0
        for (index, fragment) in fragments.enumerated() {
            // Add the new attributes for the word
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
            attributes.frame = CGRect(x: 0, y: 0, width: cellWidthForFragment(fragment), height: CELL_HEIGHT)
            collectionViewLayoutAttributes.append(attributes)
            
            // If it needs go in a new row, center the previous row, otherwise add it to current row
            let currentRowWidth = currentRow.reduce(0, {$0 + $1.frame.size.width}) + (CGFloat(currentRow.count - 1) * HORIZONTAL_CELL_SPACING)
            let rowWidthPlusNewWord = currentRowWidth + HORIZONTAL_CELL_SPACING + attributes.frame.size.width
            if (rowWidthPlusNewWord > collectionViewWidth - (2 * HORIZONTAL_CELL_SPACING)) {
                centerAttributeRow(currentRow, rowIndex: currentRowIndex)
                currentRow = [attributes]
                currentRowIndex += 1
            } else {
                currentRow.append(attributes)
            }
        }
        
        // Center the last row
        centerAttributeRow(currentRow, rowIndex: currentRowIndex)
    }
    
    fileprivate func cellWidthForFragment(_ fragment: Fragment) -> CGFloat {
        let nsWord = (fragment.displayText as NSString)
        let wordWidth = nsWord.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height:CELL_HEIGHT),
                                                    options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                    attributes: [NSFontAttributeName: font],
                                                    context: nil).width
        return max(MIN_CELL_WIDTH, wordWidth + (2 * HORIZONTAL_CELL_PADDING))
    }
    
    fileprivate func centerAttributeRow(_ row: [UICollectionViewLayoutAttributes], rowIndex: Int) {
        let currentRowWidth = row.reduce(0, {$0 + $1.frame.size.width}) + (CGFloat(row.count - 1) * HORIZONTAL_CELL_SPACING)
        var cellX = ((collectionViewWidth - (2 * HORIZONTAL_CELL_SPACING) - currentRowWidth) / 2) + HORIZONTAL_CELL_SPACING
        for currentRowAttribute in row {
            currentRowAttribute.frame = currentRowAttribute.frame.offsetBy(dx: cellX, dy: (CELL_HEIGHT + VERTICAL_CELL_SPACING) * CGFloat(rowIndex))
            cellX += currentRowAttribute.frame.size.width + HORIZONTAL_CELL_SPACING
        }
    }
}
