//
//  CustomCollectionViewLayout.swift
//  testCollectionView
//
//  Created by Sergio Ortiz on 10.10.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

protocol CustomCollectionViewDelegate: class {
     func theNumberOfItemsInCollectionView() -> Int
}

extension CustomCollectionViewDelegate {
    func heightForContentInItem(inCollectionView collectionView: UICollectionView, at indexPath: IndexPath) -> CGFloat {
        return 0
    }
}

class CustomCollectionViewLayout: UICollectionViewLayout {
    fileprivate let numberOfColumns = 2
    fileprivate let cellPadding: CGFloat = 15
    fileprivate let cellHeight: CGFloat = 130
    
    weak var delegate: CustomCollectionViewDelegate?
    
    //An array to cache the calculated attributes
    fileprivate var cache = [UICollectionViewLayoutAttributes]()
    
    //For content size
    // need to calculate the height of our content size dynamically, so for now we will just set it to 0
    fileprivate var contentHeight: CGFloat = 0
    
    // The width is the same as the width of the collection view’s bounds
    fileprivate var contentWidth: CGFloat {
        guard let collectionView = collectionView else {return 0}
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    // 2. Use the collectionViewContentSize method to return the overall size of the entire content area based on your initial calculations.
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    // 1. se the prepareLayout method to perform the up-front calculations needed to provide layout information.  We override the prepare() method. This is where all our measurements take place.
    // called periodically, whenever we need to perform layout operations
    override func prepare() {
        // Calculate only if the cache is empty
        cache.removeAll()
        guard cache.isEmpty == true, let collectionView = collectionView  else {return}
        
        // Width of each column: dividing the content’s width by the number of columns
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        
        //we create an empty array for x offset of each column
        var xOffset = [CGFloat]()
        
        //Getting the xOffset based on the column and column width
        for column in 0..<numberOfColumns {
            if column == 0 {
                xOffset.append(0)
            }
            if column == 1 {
                xOffset.append(columnWidth)
            }
        }
        
        // Empty array of y offsets, different depending on the column
        var column = 0
        var yOffset = [CGFloat]()
        
        //For each item in a collection view
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            
            //Different offset based on what column the item is
            for column in 0..<numberOfColumns {
                switch column {
                case 0:
                    //yOffset.append(0)
                    yOffset.append(cellPadding)
                case 1:
                    yOffset.append(cellPadding)
                    //yOffset.append(cellPadding + cellHeight * 0.5)
                //case 2: yOffset.append(cellPadding + cellHeight)
                default:
                    break
                }
            }
            //Measuring the frame. Width and height is the same
            let height = cellPadding * 2 + cellHeight
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: columnWidth)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            //Creating attributres for the layout of each cell and caching them
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
            //We increase the max height of the content as we get more items
            contentHeight = max(collectionView.frame.height, frame.maxY)
            
            //We increase the yOffset, too
            //yOffset[column] = yOffset[column] + 1.30 * (height)
            yOffset[column] = yOffset[column] + 1.25 * (height - cellPadding)
            
            let numberOfItems = delegate?.theNumberOfItemsInCollectionView()
            
            //Changing column so the next item will be added to a different column
            if let numberOfItems = numberOfItems, indexPath.item == numberOfItems - 1
            {
                //In case we get to the last cell, we check the column of the cell before
                //The last one, and based on that, we change the column
                switch column {
                case 0:
                    column = 2
                case 2:
                    column = 0
                case 1:
                    column = 2
                default:
                    return
                }
            } else  {
                column = column < (numberOfColumns - 1) ? (column + 1) : 0
            }
        }
        
    }
    
    // 3. Use the layoutAttributesForElementsInRect: method to return the attributes for cells and views that are in the specified rectangle.
    //Is called  to determine which items are visible in the given rect
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        //Loop through the cache and look for items in the rect
        for attribute in cache {
            if attribute.frame.intersects(rect) {
                visibleLayoutAttributes.append(attribute)
            }
        }
        
        return visibleLayoutAttributes
    }
    
    //The attributes for the item at the indexPath
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
    
    
}
