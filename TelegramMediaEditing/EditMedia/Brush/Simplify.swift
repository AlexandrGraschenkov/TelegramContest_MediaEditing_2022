//
//  Simplify.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 15.10.2022.
//

import UIKit
import Foundation

public protocol SimplifyValue: Equatable {
    func sqrDist(other: Self) -> Double
    func sqrSegmentDist(s1: Self, s2: Self) -> Double
}
public protocol Point2f {
    var xValue: Double { get }
    var yValue: Double { get }
}
public extension Point2f {
    func sqrDist(other: Self) -> Double {
        return pow(xValue - other.xValue, 2) + pow(yValue - other.yValue, 2)
    }
    func sqrSegmentDist(s1: Self, s2: Self) -> Double {
        var x = s1.xValue
        var y = s1.yValue
        var dx = s2.xValue - x
        var dy = s2.yValue - y
        
        if dx != 0 || dy != 0 {
            let t = ((xValue - x) * dx + (yValue - y) * dy) / ((dx * dx) + (dy * dy))
            if t > 1 {
                x = s2.xValue
                y = s2.yValue
            } else if t > 0 {
                x += dx * t
                y += dy * t
            }
        }
        
        dx = xValue - x
        dy = yValue - y
        
        return (dx * dx) + (dy * dy)
    }
}

public protocol Point3f {
    var xValue: Double { get }
    var yValue: Double { get }
    var zValue: Double { get }
}
public extension Point3f {
    func sqrDist(other: Self) -> Double {
        return pow(xValue - other.xValue, 2) + pow(yValue - other.yValue, 2) + pow(zValue - other.zValue, 2)
    }
    func sqrSegmentDist(s1: Self, s2: Self) -> Double {
        var x = s1.xValue
        var y = s1.yValue
        var z = s1.zValue
        var dx = s2.xValue - x
        var dy = s2.yValue - y
        var dz = s2.zValue - z
        
        if dx != 0 || dy != 0 {
            let t = ((xValue - x) * dx + (yValue - y) * dy + (zValue - z) * dz) / ((dx * dx) + (dy * dy) + (dz * dz))
            if t > 1 {
                x = s2.xValue
                y = s2.yValue
                z = s2.zValue
            } else if t > 0 {
                x += dx * t
                y += dy * t
                z += dz * t
            }
        }
        
        dx = xValue - x
        dy = yValue - y
        dz = zValue - z
        
        return (dx * dx) + (dy * dy) + (dz * dz)
    }
}


open class Simplify {
//    /**
//     Calculate square distance
//
//     - parameter pointA: from point
//     - parameter pointB: to point
//
//     - returns: square distance between two points
//     */
//    fileprivate class func getSquareDistance<T:SimplifyValue>(_ pointA: T,_ pointB: T) -> Float {
//        let dx = pointA.xValue - pointB.xValue
//        let dy = pointA.yValue - pointB.yValue
//        let dz = pointA.zValue - pointB.zValue
//        return Float(pow(dx, 2) + pow(dy, 2) + pow(dz, 2))
//    }
//
//    /**
//     Calculate square distance from a point to a segment
//
//     - parameter point: from point
//     - parameter seg1: segment first point
//     - parameter seg2: segment last point
//     - returns: square distance between point to a segment
//     */
//    fileprivate class func getSquareSegmentDistance<T:SimplifyValue>(point p: T, seg1 s1: T, seg2 s2: T) -> Float {
//
//        var x = s1.xValue
//        var y = s1.yValue
//        var z = s1.zValue
//        var dx = s2.xValue - x
//        var dy = s2.yValue - y
//        var dz = s2.zValue - z
//
//        if dx != 0 || dy != 0 {
//            let t = ((p.xValue - x) * dx + (p.yValue - y) * dy) / ((dx * dx) + (dy * dy))
//            if t > 1 {
//                x = s2.xValue
//                y = s2.yValue
//            } else if t > 0 {
//                x += dx * t
//                y += dy * t
//            }
//        }
//
//        dx = p.xValue - x
//        dy = p.yValue - y
//
//        return Float((dx * dx) + (dy * dy))
//    }
    
    /**
     Simplify an array of points using the Ramer-Douglas-Peucker algorithm
     
     - parameter points:      An array of points
     - parameter tolerance:   Affects the amount of simplification (in the same metric as the point coordinates)
     
     - returns: Returns an array of simplified points
     */
    fileprivate class func simplifyDouglasPeucker<T:SimplifyValue>(_ points: [T], tolerance: Float!) -> [T] {
        if points.count <= 2 {
            return points
        }
        
        let lastPoint: Int = points.count - 1
        var result: [T] = [points.first!]
        simplifyDouglasPeuckerStep(points, first: 0, last: lastPoint, tolerance: tolerance, simplified: &result)
        result.append(points[lastPoint])
        return result
    }
    
    fileprivate class func simplifyDouglasPeuckerStep<T:SimplifyValue>(_ points: [T], first: Int, last: Int, tolerance: Float, simplified: inout [T]) {
        var maxSquareDistance = tolerance
        var index = 0
        
        for i in first + 1 ..< last {
            let sqDist = Float(points[i].sqrSegmentDist(s1: points[first], s2: points[last]))
            if sqDist > maxSquareDistance {
                index = i
                maxSquareDistance = sqDist
            }
        }
        
        if maxSquareDistance > tolerance {
            if index - first > 1 {
                simplifyDouglasPeuckerStep(points, first: first, last: index, tolerance: tolerance, simplified: &simplified)
            }
            simplified.append(points[index])
            if last - index > 1 {
                simplifyDouglasPeuckerStep(points, first: index, last: last, tolerance: tolerance, simplified: &simplified)
            }
        }
    }
    
    /**
     Simplify an array of points using the Radial Distance algorithm
     
     - parameter points:      An array of points
     - parameter tolerance:   Affects the amount of simplification (in the same metric as the point coordinates)
     
     - returns: Returns an array of simplified points
     */
    fileprivate class func simplifyRadialDistance<T:SimplifyValue>(_ points: [T], tolerance: Float!) -> [T] {
        if points.count <= 2 {
            return points
        }
        
        var prevPoint: T = points.first!
        var newPoints: [T] = [prevPoint]
        var point: T = points[1]
        
        for idx in 1 ..< points.count {
            point = points[idx]
            let distance = Float(point.sqrDist(other: prevPoint))
            if distance > tolerance! {
                newPoints.append(point)
                prevPoint = point
            }
        }
        
        if prevPoint != point {
            newPoints.append(point)
        }
        
        return newPoints
    }
    
    /**
     Returns an array of simplified points
     
     - parameter points:      An array of points
     - parameter tolerance:   Affects the amount of simplification (in the same metric as the point coordinates)
     - parameter highQuality: Excludes distance-based preprocessing step which leads to highest quality simplification but runs ~10-20 times slower
     
     - returns: Returns an array of simplified points
     */
    
    open class func simplify<T:SimplifyValue>(_ points: [T], tolerance: Float?, highQuality: Bool = false) -> [T] {
        if points.count <= 2 {
            return points
        }

        let squareTolerance = (tolerance != nil ? tolerance! * tolerance! : 1.0)
        var result: [T] = (highQuality == true ? points : simplifyRadialDistance(points, tolerance: squareTolerance))
        result = simplifyDouglasPeucker(result, tolerance: squareTolerance)
        return result
    }
}
