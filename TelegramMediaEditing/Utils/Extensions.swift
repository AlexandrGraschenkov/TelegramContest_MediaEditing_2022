//
//  Extensions.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 11.10.2022.
//

import UIKit

extension Comparable {
    func clamp(_ minVal: Self, _ maxVal: Self) -> Self {
        let v = min(self, maxVal)
        return max(v, minVal)
    }
}

extension CGPoint {
    func distance() -> CGFloat {
        return sqrt(x * x + y * y)
    }
    func add(_ p: CGPoint) -> CGPoint {
        return CGPoint(x: x + p.x, y: y + p.y)
    }
    func substract(_ p: CGPoint) -> CGPoint {
        return CGPoint(x: x - p.x, y: y - p.y)
    }
    func mulitply(_ val: CGFloat) -> CGPoint {
        return CGPoint(x: x * val, y: y * val)
    }
    var norm: CGPoint {
        let d = distance()
        return CGPoint(x: x / d, y: y / d)
    }
    // clockwise
    var rot90: CGPoint {
        return CGPoint(x: y, y: -x)
    }
    var rot180: CGPoint {
        return CGPoint(x: -x, y: -y)
    }
    var rot270: CGPoint {
        return CGPoint(x: -y, y: x)
    }
}

extension CGSize {
    var point: CGPoint {
        return CGPoint(x: width, y: height)
    }
    
    func add(_ other: CGSize) -> CGSize {
        return CGSize(width: width + other.width, height: height + other.height)
    }
    
    func substract(_ other: CGSize) -> CGSize {
        return CGSize(width: width - other.width, height: height - other.height)
    }
    
    func mulitply(_ val: CGFloat) -> CGSize {
        return CGSize(width: width * val, height: height * val)
    }
    
    func integral() -> CGSize {
        return CGSize(width: round(width), height: round(height))
    }
    
    func aspectFit(maxSize: CGSize, maxScale: CGFloat = 0) -> CGSize {
        let scale = max(self.width / maxSize.width,
                        self.height / maxSize.height)
        if scale < maxScale { return self }
        return CGSize(width: width / scale, height: height / scale)
    }
    
    func aspectFill(maxSize: CGSize, maxScale: CGFloat = 0) -> CGSize {
        let scale = min(self.width / maxSize.width,
                        self.height / maxSize.height)
        if scale < maxScale { return self }
        return CGSize(width: width / scale, height: height / scale)
    }
}

extension CGPoint {
    var size: CGSize {
        return CGSize(width: x, height: y)
    }
}

extension CGRect {
    init(mid: CGPoint, size: CGSize) {
        let origin = mid.substract(size.point.mulitply(0.5))
        self.init(origin: origin, size: size)
    }
    
    var mid: CGPoint {
        set {
            origin = CGPoint(x: newValue.x - width/2, y: newValue.y - height/2)
        }
        get {
            return CGPoint(x: midX, y: midY)
        }
    }
    
    func inset(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> CGRect {
        return self.inset(by: UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    func round(scale: CGFloat = 1.0) -> CGRect {
        let appl: (CGFloat)->(CGFloat) = { ($0 * scale).rounded() / scale }
        let p1 = CGPoint(x: appl(minX), y: appl(minY))
        let p2 = CGPoint(x: appl(maxX), y: appl(maxY))
        
        let r = CGRect(x: p1.x, y: p1.y, width: p2.x-p1.x, height: p2.y-p1.y)
        return r
    }
}

extension FloatingPoint {
    func percent(min: Self, max: Self) -> Self {
        let dx = max - min
        return (self - min) / (max - min)
    }
    func percentToRange(min: Self, max: Self) -> Self {
        return (max - min)*self + min
    }
}
