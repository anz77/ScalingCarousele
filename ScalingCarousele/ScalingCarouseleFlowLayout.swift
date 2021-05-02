//
//  ScalingCarouseleFlowLayout.swift
//  ScalingCarousele
//
//  Created by Andrii Zuiok on 01.05.2021.
//

import UIKit

class ScalingCarouseleFlowLayout: UICollectionViewFlowLayout {
    
    var zoomFactor: CGFloat
    var activeDistanceFactor: CGFloat
    var scaleCenter: Bool
    
    init(activeDistanceFactor: CGFloat = 1.0, zoomFactor: CGFloat, scrollDirection: UICollectionView.ScrollDirection, itemSize: CGSize, scaleCenter: Bool = false) {
        self.activeDistanceFactor = activeDistanceFactor
        self.zoomFactor = zoomFactor
        self.scaleCenter = scaleCenter
        super.init()
        self.itemSize = itemSize
        self.scrollDirection = scrollDirection
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        guard let collectionView = collectionView else { fatalError() }
        
        let verticalInsets = (collectionView.frame.height - collectionView.adjustedContentInset.top - collectionView.adjustedContentInset.bottom - itemSize.height) / 2
        
        let horizontalInsets = (collectionView.frame.width - collectionView.adjustedContentInset.right - collectionView.adjustedContentInset.left - itemSize.width) / 2
        
        sectionInset = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)

        super.prepare()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }
        let rectAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)
        
        for attributes in rectAttributes where attributes.frame.intersects(visibleRect) {
            
            var distance = CGFloat.greatestFiniteMagnitude
            var activeDistance = CGFloat.greatestFiniteMagnitude
            switch scrollDirection {
            case .horizontal:
                distance = (visibleRect.midX - attributes.center.x)
                activeDistance = activeDistanceFactor * visibleRect.width
            case .vertical:
                distance = (visibleRect.midY - attributes.center.y)
                activeDistance = activeDistanceFactor * visibleRect.height
            default: fatalError()
            }
            
            let normalizedDistance = distance / activeDistance
 
            if scaleCenter {
                if distance.magnitude < activeDistance {
                    let zoom = 1 + zoomFactor * (1 - normalizedDistance.magnitude)
                    attributes.transform3D = CATransform3DMakeScale(zoom, zoom, 1)
                    attributes.zIndex = Int(zoom.rounded())
                }
            } else {
                if distance.magnitude < activeDistance {
                    let zoom = 1 - ((1 - zoomFactor) * normalizedDistance.magnitude)
                    attributes.transform3D = CATransform3DMakeScale(zoom, zoom, 1)
                    attributes.zIndex = Int(zoom.rounded())
                } else {
                    let zoom = zoomFactor
                    attributes.transform3D = CATransform3DMakeScale(zoom, zoom, 1)
                    attributes.zIndex = Int(zoom.rounded())
                }
            }
        }
        return rectAttributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return .zero }
        
        switch scrollDirection {
        case .horizontal:
            let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView.frame.width, height: collectionView.frame.height)
            let horizontalCenter = (proposedContentOffset.x + collectionView.frame.width / 2)
            guard let rectAttributes = super.layoutAttributesForElements(in: targetRect) else {return .zero}
            var offsetAdjustment = CGFloat.greatestFiniteMagnitude
            for layoutAttributes in rectAttributes {
                let itemHorizontalCenter = layoutAttributes.center.x
                if (itemHorizontalCenter - horizontalCenter).magnitude < offsetAdjustment.magnitude {
                    offsetAdjustment = itemHorizontalCenter - horizontalCenter
                }
            }
            return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
        case .vertical:
            let targetRect = CGRect(x: 0, y: proposedContentOffset.y, width: collectionView.frame.width, height: collectionView.frame.height)
            let verticalCenter = (proposedContentOffset.y + collectionView.frame.height / 2)
            guard let rectAttributes = super.layoutAttributesForElements(in: targetRect) else {return .zero}
            var offsetAdjustment = CGFloat.greatestFiniteMagnitude
            for layoutAttributes in rectAttributes {
                let itemVerticalCenter = layoutAttributes.center.y
                if (itemVerticalCenter - verticalCenter).magnitude < offsetAdjustment.magnitude {
                    offsetAdjustment = itemVerticalCenter - verticalCenter
                }
            }
            return CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y + offsetAdjustment)
        @unknown default:
            fatalError()
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}
