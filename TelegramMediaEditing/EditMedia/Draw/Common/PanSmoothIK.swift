//
//  PanSmoothIK.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 16.10.2022.
//

import UIKit

// Idea from iverse kinematics
class PanSmoothIK: NSObject {
    var points: [PanPoint] {
        if smoothPoints.isEmpty {
            return [lastPoint].compactMap({$0})
        } else if smoothPoints.last == lastPoint {
            return smoothPoints
        } else {
            return smoothPoints + [lastPoint].compactMap({$0})
        }
    }
    var smoothMultiplier: CGFloat = 1
    fileprivate var smoothPoints: [PanPoint] = []
    fileprivate var lastPoints: [PanPoint] = []
    fileprivate var lastPointsFilterTime: TimeInterval = 0.2
    fileprivate var maxDistOffset: CGFloat = 30
    fileprivate var lastPoint: PanPoint?
//    fileprivate lazy var debugLayer: CAShapeLayer = {
//        let shape = CAShapeLayer()
//        shape.lineWidth = 10
//        shape.strokeColor = UIColor.green.cgColor
//        shape.fillColor = nil
//        return shape
//    }()
//    fileprivate lazy var debugLayer2: CAShapeLayer = {
//        let shape = CAShapeLayer()
//        shape.strokeColor = nil
//        shape.fillColor = UIColor.blue.cgColor
//        return shape
//    }()
    var scale: CGFloat = 1.0
    var toolSize: CGFloat = 1
    var debugView: UIView?
//    var speedFilter = ABFilter()
    
    func start() {
        lastPoint = nil
        smoothPoints.removeAll()
        lastPoints.removeAll()
//        speedFilter.reset(value: nil)
//        if let debugView = debugView {
//
//            DispatchQueue.main.async {
//                debugView.layer.addSublayer(self.debugLayer)
//                debugView.layer.addSublayer(self.debugLayer2)
//            }
//        }
    }
    
    func end() {
//        debugLayer.removeFromSuperlayer()
//        debugLayer.removeFromSuperlayer()
    }
    
    func update(point: PanPoint) {
        lastPoints.append(point)
        while lastPoints.count > 1 && point.time - lastPoints.first!.time > lastPointsFilterTime {
            lastPoints.remove(at: 0)
        }
        if smoothPoints.isEmpty {
            lastPoint = point
            smoothPoints.append(point)
//            updateDebug2()
            return
        }
        lastPoint = PanPoint(point: point.point, time: point.time+0.001)
        
        let lineLenght = calcLineLength(points: lastPoints)
        let dt = lastPoints.last!.time - lastPoints.first!.time
        let speed = dt > 0.00001 ? lineLenght / dt : 0
        // larger speed => larger offset dist
        var maxPanOffset = log(speed/2/scale+1) * 3 * scale + 2 // just google it to understand formula of log
//        print(speed, maxPanOffset, log(speed/2/scale+1) * 2)
        
        // the smaller the brush, the more accurately you need to draw
        let mult = toolSize.percent(min: 1, max: 30).percentToRange(min: 0.2, max: 1.5)
        maxPanOffset *= mult * smoothMultiplier
//        maxPanOffset *= smoothMultiplier
        
        let dist = smoothPoints.last!.point.distance(p: point.point)
        if dist < maxPanOffset {
            return
        }
        var offset = smoothPoints.last!.point.subtract(point.point)
        offset = offset.norm.multiply(maxPanOffset)
        let newPoint = point.point.add(offset)
        if newPoint.distance(p: smoothPoints.last!.point) < scale*2 {
            return
        }
        if newPoint.x.isNaN {
            print("wtf")
        }
        smoothPoints.append(PanPoint(point: newPoint, time: point.time, speed: speed))
    }
    
    fileprivate func calcLineLength(points: [PanPoint]) -> CGFloat {
        var sumDist: CGFloat = 0
        for i in 1..<points.count {
            sumDist += points[i-1].point.distance(p: points[i].point)
        }
        return sumDist
    }
}
