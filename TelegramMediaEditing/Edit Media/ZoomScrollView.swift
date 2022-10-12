//
//  ZoomScrollView.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 12.10.2022.
//

import UIKit

class ZoomScrollView: UIScrollView {

    func setup(content: UIView) {
        if let prevContent = self.content {
            prevContent.removeFromSuperview()
        }
        self.content = content
        addSubview(content)
//        content.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = .fast
        delegate = self
        contentSize = content.bounds.size
        print("Start content size", contentSize)
        
        screenScale = UIScreen.main.scale
        updateZoomScale()
        centerScrollViewContents()
    }

    fileprivate(set) var content: UIView!
    fileprivate var screenScale: CGFloat!
    override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                updateZoomScale()
                centerScrollViewContents()
                
                // keep in center
                contentOffset = CGPoint(x: -safeAreaInsets.left - contentInset.left ,
                                        y: -safeAreaInsets.top - contentInset.top)
            }
        }
    }
    
    
    fileprivate func centerScrollViewContents() {
        var horizontalInset: CGFloat = 0
        var verticalInset: CGFloat = 0
        
        if contentSize.width < bounds.width {
            horizontalInset = (bounds.width - contentSize.width) * 0.5
            horizontalInset = max(0, horizontalInset)
        }
        
        if contentSize.height < bounds.height {
            verticalInset = (bounds.height - contentSize.height) * 0.5
            verticalInset = max(0, verticalInset)
        }
        
        // http://petersteinberger.com/blog/2013/how-to-center-uiscrollview/
        let inset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        if inset != contentInset {
            contentInset = inset
        }
    }
    
    fileprivate func updateZoomScale() {
        let scaleWidth = bounds.size.width / content.bounds.width
        let scaleHeight = bounds.size.height / content.bounds.height
        let minimumScale = min(scaleWidth, scaleHeight)
        
        minimumZoomScale = minimumScale
        maximumZoomScale = max(minimumScale, maximumZoomScale)
        
        zoomScale = minimumZoomScale
    }
    
    fileprivate var prevZoom: CGFloat = 0
}

extension ZoomScrollView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return content
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let zoom = max(minimumZoomScale, min(maximumZoomScale, zoomScale))
        if prevZoom != zoom {
//            print("----", zoom)
            prevZoom = zoom
            centerScrollViewContents()
        } else {
//            print("•••", zoomScale)
        }
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        centerScrollViewContents()
    }
}