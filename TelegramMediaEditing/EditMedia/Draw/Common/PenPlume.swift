//
//  PenPlume.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 19.10.2022.
//

import UIKit

class PenPlume: NSObject {
    /// leave the plume behind the line, rewrite the speed only if it is greater
    static func makePlumeOnEndPath(points: inout [PanPoint], lastNPoints: CGFloat, lastPointOverrideSpeed: Double) {
        let startIdx = max(0, CGFloat(points.count) - lastNPoints)
        let startUpdateIdx = Int(floor(startIdx+1))
        if startUpdateIdx == points.count {
            if lastPointOverrideSpeed < points[startUpdateIdx-1].speed! {
                points[startUpdateIdx-1].speed = lastPointOverrideSpeed
            }
            return
        }
        
        let percent = startIdx - floor(startIdx)
        let startSpeed = (points[startUpdateIdx].speed!-points[startUpdateIdx-1].speed!) * percent + points[startUpdateIdx-1].speed!
        
        for i in startUpdateIdx..<points.count {
            let percent = Double(points.count - i) / (Double(points.count) - Double(startIdx))
            let speed = (startSpeed - lastPointOverrideSpeed) * percent + lastPointOverrideSpeed
            if speed < points[i].speed! {
                points[i].speed = speed
            }
        }
    }
    
    /// leave the plume behind the line, rewrite the speed only if it is greater
    static func makePlumeOnEndPath(points: inout [PanPoint], lastTimePoints: Double, lastPointOverrideSpeed: Double) {
        var pointsCount: CGFloat = 0
        var idx = points.count-2
        var lastTimePoints = lastTimePoints
        while idx >= 0 {
            let dt = points[idx+1].time - points[idx].time
            if dt < lastTimePoints {
                lastTimePoints -= dt
                pointsCount += 1
            } else {
                pointsCount += lastTimePoints / dt
                break
            }
            idx -= 1
        }
        print(pointsCount, points.count)
        makePlumeOnEndPath(points: &points, lastNPoints: pointsCount, lastPointOverrideSpeed: lastPointOverrideSpeed)
    }
}
