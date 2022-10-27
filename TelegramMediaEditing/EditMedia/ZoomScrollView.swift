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

    var onZoom: ((CGFloat)->())?
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
    
    @objc func zoomOut() {
        setZoomScale(minimumZoomScale, animated: true)
    }
    
    /// add insets to content, to center it on minimal zoom
    fileprivate func centerScrollViewContents() {
        var horizontalInset: CGFloat = 0
        var verticalInset: CGFloat = 0
        
        // contentSize changed during zoom, constraint it between min max sizes
        var size = contentSize
        let minSize = content.bounds.size.mulitply(minimumZoomScale)
        let maxSize = content.bounds.size.mulitply(maximumZoomScale)
        size.width = size.width.clamp(minSize.width, maxSize.width)
        size.height = size.height.clamp(minSize.height, maxSize.height)
        
        if size.width < bounds.width {
            horizontalInset = (bounds.width - size.width) * 0.5
            horizontalInset = max(0, horizontalInset)
        }
        
        if size.height < bounds.height {
            verticalInset = (bounds.height - size.height) * 0.5
            verticalInset = max(0, verticalInset)
        }
        
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
            onZoom?(zoom)
        } else {
//            print("•••", zoomScale)
        }
    }
}
