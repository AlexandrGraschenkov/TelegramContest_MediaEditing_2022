//
//  GausianSmooth.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 15.10.2022.
//

import UIKit

class GausianSmooth {
    static func smoothSpeed(points: inout [PanPoint], distWindow: CGFloat) {
//        if points.count > 10 {
//            print("test")
//        }
        
        let sigma = (distWindow-1)/6 // 99 percentile of gaus
        var speeds: [Double] = []
        let dists = generatePointTimeDistance(points: points)
        for idx in 0..<points.count {
            let (lower, upper) = getRange(points: points, dists: dists, idx: idx, distWindow: distWindow)
            let speed = smoothGausSpeed(points: points, dists: dists, center: idx, lower: lower, upper: upper, sigma: sigma)
            speeds.append(speed)
            if idx == 0 {
                print(upper, "<>", lower, "total", points.count)
            }
        }
        for idx in 0..<points.count {
            points[idx].speed = speeds[idx]
        }
    }
    
    
    
    // MARK: - private
    fileprivate static let invSqrt2pi = 0.3989422804014327
    fileprivate static func gaus(x: Double, m: Double, s: Double) -> Double {
        let a = (x - m) / s
        return invSqrt2pi / s * exp(-0.5 * a * a)
    }
    fileprivate static func generatePointTimeDistance(points: [PanPoint]) -> [CGFloat] {
        var distArr: [CGFloat] = [0]
        var lineLength: CGFloat = 0 
//        let timeScale: CGFloat = 100
        for i in 1..<points.count {
            lineLength += points[i-1].point.distance(p: points[i].point)
            // experiment with time dist
//            let dTime = timeScale * (points[i].time-points[i-1].time)
//            let dist = sqrt(pow(lineLength,2) + pow(dTime, 2))
            distArr.append(lineLength)
        }
        return distArr
    }
    
    fileprivate static func smoothGausSpeed(points: [PanPoint], dists: [CGFloat], center: Int, lower: Int, upper: Int, sigma: Double) -> Double {
        var gSum: Double = 0
        var speedSum: Double = 0
        for i in lower..<upper {
            let g = gaus(x: dists[i], m: dists[center], s: sigma)
            gSum += g
            speedSum += g*points[i].speed!
        }
        if gSum > 0 {
            speedSum /= gSum
        }
        return speedSum
    }
    
    fileprivate static func getRange(points: [PanPoint], idx: Int, timeWindow: Double) -> (lower: Int, upper: Int) {
        var lower = idx
        while lower > 0, abs(points[lower].time - points[idx].time) < timeWindow/2 {
            lower -= 1
        }
        if abs(points[lower].time - points[idx].time) > timeWindow {
            lower += 1
        }
        
        var upper = idx
        while upper < points.count-1, abs(points[upper].time - points[idx].time) < timeWindow {
            upper += 1
        }
        return (lower, upper)
    }
    
    fileprivate static func getRange(points: [PanPoint], dists: [CGFloat], idx: Int, distWindow: CGFloat) -> (lower: Int, upper: Int) {
        var lower = idx
        let halfWindow = distWindow/2
        while lower > 0, abs(dists[lower] - dists[idx]) < halfWindow {
            lower -= 1
        }
        if abs(dists[lower] - dists[idx]) > halfWindow {
            lower += 1
        }
        
        var upper = idx
        while upper < points.count-1, abs(dists[upper] - dists[idx]) < halfWindow {
            upper += 1
        }
        return (lower, upper)
    }
}
