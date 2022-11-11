//
//  ArrowDetector.swift
//  BezierHitTest
//
//  Created by Alexander Graschenkov on 03.11.2022.
//

import UIKit

final class ArrowClassifier {

    static func detectArrow(points: [CGPoint]) -> (from: CGPoint, to: CGPoint)? {
        if let res = checkPoints(points: points) {
            return res
        }
        if let res = checkPoints(points: points.reversed()) {
            return res
        }
        return nil
    }
    
    fileprivate static func isRightSide(a: CGPoint, b: CGPoint, c: CGPoint) -> Bool {
         return ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)) > 0
    }
    
    fileprivate static func projectT(p: CGPoint, from: CGPoint, to: CGPoint) -> CGFloat {
        let fromTo = to.subtract(from)
        let val = fromTo.dot(p.subtract(from))
        return val / fromTo.distanceSqr()
    }
    
    fileprivate static func checkPoints(points: [CGPoint]) -> (from: CGPoint, to: CGPoint)? {
        if points.count < 4 { return nil }
        
        //
        var endLineIdx: Int = 1
        var cosVal: CGFloat = 1
        while endLineIdx < points.count-1 && cosVal > 0.5 {
            endLineIdx += 1
            let v1 = points[endLineIdx-1].subtract(points[0])
            let v2 = points[endLineIdx].subtract(points[endLineIdx-1])
            cosVal = v1.normDot(v2)
        }
        if endLineIdx+1 >= points.count || cosVal > -0.2 {
            // we have line, but not arrow
            return nil
        }
        
        let from = points[0]
        let to = points[endLineIdx-1]
        // allow that some points can me little further that `to` point
        let to2 = to.subtract(from).multiply(1.05).add(from)
        let fromTo2Norm = to2.subtract(from).norm
        
        // force points must be on both sides of the line
        var sides: [Int] = [0, 0]
        let tAllowInterval = 0.6..<1.0
        let cosMaxValThresh = -0.6
        
        for i in endLineIdx..<points.count {
            let p = points[i]
            let t = projectT(p: p, from: from, to: to2)
            let cosVal = fromTo2Norm.dot(p.subtract(to2).norm)
            if !tAllowInterval.contains(t) || cosVal > cosMaxValThresh {
                return nil
            }
            
            let left = isRightSide(a: from, b: to, c: p)
            if left {
                sides[0] += 1
            } else {
                sides[1] += 1
            }
        }
        
        if sides[0] > 0 && sides[1] > 0 {
            return (from, to)
        } else {
            return nil
        }
    }
}
