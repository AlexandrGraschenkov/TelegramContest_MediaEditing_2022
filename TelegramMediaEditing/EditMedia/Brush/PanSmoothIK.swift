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
    fileprivate var smoothPoints: [PanPoint] = []
    fileprivate var lastPoints: [PanPoint] = []
    fileprivate var lastPointsFilterTime: TimeInterval = 0.2
    fileprivate var maxDistOffset: CGFloat = 30
    fileprivate var lastPoint: PanPoint?
    fileprivate lazy var debugLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.lineWidth = 10
        shape.strokeColor = UIColor.green.cgColor
        shape.fillColor = nil
        return shape
    }()
    fileprivate lazy var debugLayer2: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.strokeColor = nil
        shape.fillColor = UIColor.blue.cgColor
        return shape
    }()
    var scale: CGFloat = 1.0
    var debugView: UIView?
    
    func start() {
        lastPoint = nil
        smoothPoints.removeAll()
        lastPoints.removeAll()
//        if let debugView = debugView {
//
//            DispatchQueue.main.async {
//                debugView.layer.addSublayer(self.debugLayer)
//                debugView.layer.addSublayer(self.debugLayer2)
//            }
//        }
    }
    
    func end() {
        debugLayer.removeFromSuperlayer()
        debugLayer.removeFromSuperlayer()
    }
    
    func update(point: PanPoint) {
        lastPoints.append(point)
        while lastPoints.count > 1 && point.time - lastPoints.first!.time > lastPointsFilterTime {
            lastPoints.remove(at: 0)
        }
        if smoothPoints.isEmpty {
            lastPoint = point
            smoothPoints.append(point)
            updateDebug2()
            return
        }
        lastPoint = PanPoint(point: point.point, time: point.time+2)
        defer {
            let path = UIBezierPath()
            path.move(to: lastPoint!.point)
            path.addLine(to: smoothPoints.last!.point)
            debugLayer.path = path.cgPath
        }
        
        let lineLenght = calcLineLength(points: lastPoints)
        let dt = lastPoints.last!.time - lastPoints.first!.time
        let speed = dt > 0.00001 ? lineLenght / dt : 0
        // larger speed => larger offset dist
        let maxBrushOffset = log(speed/2/scale+1) * 2 * scale // just gogle it to understand formula of log
//        print(speed, maxBrushOffset, log(speed/2/scale+1) * 2)
        let dist = smoothPoints.last!.point.distance(p: point.point)
        if dist < maxBrushOffset {
            return
        }
        var offset = smoothPoints.last!.point.substract(point.point)
        offset = offset.norm.mulitply(maxBrushOffset)
        let newPoint = point.point.add(offset)
        if newPoint.distance(p: smoothPoints.last!.point) < 14 {
            return
        }
        smoothPoints.append(PanPoint(point: newPoint, time: point.time))
        updateDebug2()
        
//        if points.count > 1 && points[points.count-1].time - points[points.count-2].time < skipTime {
//            _ = points.popLast()
//        }
//        points.append(point)
    }
    
    fileprivate func updateDebug2() {
//        let bezier = UIBezierPath()
//        for p in smoothPoints {
//            bezier.append(UIBezierPath(ovalIn: CGRect(mid: p.point, size: CGSize(width: 5*scale, height: 5*scale))))
//        }
//        debugLayer2.path = bezier.cgPath
    }
    
    fileprivate func calcLineLength(points: [PanPoint]) -> CGFloat {
        var sumDist: CGFloat = 0
        for i in 1..<points.count {
            sumDist += points[i-1].point.distance(p: points[i].point)
        }
        return sumDist
    }
}
