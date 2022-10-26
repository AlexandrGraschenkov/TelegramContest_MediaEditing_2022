//
//  PenCurveGenerator.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 14.10.2022.
//

import UIKit

struct PanPoint: Equatable {
    internal init(point: CGPoint, time: CFTimeInterval = CACurrentMediaTime()) {
        self.point = point
        self.time = time
    }
    
    let point: CGPoint
    let time: CFTimeInterval
    var speed: Double?
}


struct PenCurveGenerator {
    let maxPixSpeed: Double = 800
    let minPixSpeed: Double = 50
    var penSize: CGFloat = 30
    var minBrushSizeMultiplier: CGFloat = 0.4
    var scrollZoomScale: CGFloat = 1
    /// какой продолжительности отдается шлейф за кистью
    var plumePointsCount: CGFloat = 10
    /// 0 - minPixSpeed, 1 - maxPixSpeed
    var plumeLastSpeedPercent: CGFloat = 0.2
    
    func finishPlumAnimation(points: [PanPoint], onLayer: CAShapeLayer, duration: Double) {
        var selfCopy = self
        let startPlumePointsCount = plumePointsCount
        let startPlumeLastSpeedPercent = plumeLastSpeedPercent
        _ = DisplayLinkAnimator.animate(duration: duration) { percent in
//            if onLayer.superlayer == nil { return }
            selfCopy.plumePointsCount = (1-percent) * startPlumePointsCount
            selfCopy.plumeLastSpeedPercent = percent * (1 - startPlumeLastSpeedPercent) + startPlumeLastSpeedPercent
            let path = selfCopy.generatePolygon(points: points)
            onLayer.path = path.cgPath
        }
    }
    
    func generateStrokePolygon(points: [PanPoint]) -> UIBezierPath {
        let traj = generateSmoothTrajectory(points: points, plumePointsCount: plumePointsCount)
        let bezier = UIBezierPath()
        if traj.count <= 1 {
            return bezier
        }
        bezier.move(to: traj[0].point)
        for (idx, info) in traj.enumerated() {
            if let control = info.control, idx+1 < traj.count {
                bezier.addQuadCurve(to: traj[idx+1].point, controlPoint: control)
            } else {
                bezier.addLine(to: info.point)
            }
        }
        return bezier
    }
    func generatePolygon(points: [PanPoint], withPlume: Bool = true) -> UIBezierPath {
        let traj = generateSmoothTrajectory(points: points, plumePointsCount: withPlume ? plumePointsCount : 0)
//        print("Points count", points.count)
        let bezier = trajectoryToPenPoly(traj: traj)
        return bezier
    }
    // MARK: - private
    private struct DrawBezierInfo {
        var point: CGPoint
        var control: CGPoint?
        var speed: Double
    }
    private let gausDistWindow: CGFloat = 300
    
    private func generateSmoothTrajectory(points: [PanPoint], plumePointsCount: CGFloat) -> [DrawBezierInfo] {
        if points.count < 2 {
            return points.map({DrawBezierInfo(point: $0.point, control: $0.point, speed: minPixSpeed)})
        }
        var points = points
        for idx in 0..<points.count {
            if idx == points.count-1 {
                points[idx].speed = points[idx-1].speed
            } else {
                points[idx].speed = points[idx+1].speed(p: points[idx])
            }
        }
        points = points.filter({$0.speed ?? 0 > 0})
        GausianSmooth.smoothSpeed(points: &points, distWindow: gausDistWindow * scrollZoomScale)
        if plumePointsCount > 0 {
            let lastPlumSpeed = plumeLastSpeedPercent * (maxPixSpeed - minPixSpeed) * scrollZoomScale
            PenPlume.makePlumeOnEndPath(points: &points, lastNPoints: plumePointsCount, lastPointOverrideSpeed: lastPlumSpeed)
        }
        
        if points.count < 2 {
            return points.map({DrawBezierInfo(point: $0.point, control: $0.point, speed: minPixSpeed)})
        }
        
        var result: [DrawBezierInfo] = []
        // reserve first point, change it later
        result.append(DrawBezierInfo(point: .zero, control: nil, speed: 0))
        for i in 1..<points.count {
            let p1 = points[i-1]
            let p2 = points[i]
            let info = DrawBezierInfo(point: p1.mid(p: p2),
                                      control: p2.point,
                                      speed: p1.speed ?? p1.speed(p: p2))
            result.append(info)
        }
        result[0] = DrawBezierInfo(point: points[0].point,
                                   control: nil,
                                   speed: result[1].speed)
        result.append(DrawBezierInfo(point: points.last!.point,
                                     control: nil,
                                     speed: result.last!.speed))
        return result
    }
    
//    private var debugContext: CGContext?
//    private var debugContextOffset: CGPoint?
    
    private func trajectoryToPenPoly(traj: [DrawBezierInfo]) -> UIBezierPath {
        var bezier = UIBezierPath()
        if traj.isEmpty { return bezier }
        if traj.count == 1 {
            let size = penSize(speed: traj[0].speed)
            bezier = UIBezierPath(ovalIn: CGRect(mid: traj[0].point, size: CGSize(width: size, height: size)))
            return bezier
        }
        
        // рисуем по правой стороне в одну сторону, и по левой в обратную
        // проходим по массиву 2 раза
        penStartCirleLeftRightConterClock(start: traj[0], end: traj[1], moveToStart: true, bezier: &bezier)
        penRightSide(traj: traj, reversed: false, bezier: &bezier)
        
        penStartCirleLeftRightConterClock(start: traj[traj.count-1], end: traj[traj.count-2], moveToStart: false, bezier: &bezier)
        penRightSide(traj: traj, reversed: true, bezier: &bezier)
        
        bezier.close()
        UIGraphicsEndImageContext()
        return bezier
    }
    
    private func penStartCirleLeftRightConterClock(start: DrawBezierInfo, end: DrawBezierInfo, moveToStart: Bool, bezier: inout UIBezierPath) {
        let dirNorm = end.point.substract(start.point).norm
        let startSize = penSize(speed: start.speed)
        let angl = atan2(dirNorm.y, dirNorm.x)
        bezier.addArc(withCenter: start.point, radius: startSize, startAngle: angl+CGFloat.pi*0.5, endAngle: angl+CGFloat.pi*1.5, clockwise: true)
    }
    
    private func penRightSide(traj: [DrawBezierInfo], reversed: Bool, bezier: inout UIBezierPath) {
//        var debugBezier = UIBezierPath()
        var prev: DrawBezierInfo?
        
//        stride(from: 0, to: traj.count, by: 1)
//        stride(from: traj.count-1, to: -1, by: 1)
//        debugContext?.setFillColor(UIColor.blue.cgColor)
        for idx in (reversed ? stride(from: traj.count-1, to: -1, by: -1) : stride(from: 0, to: traj.count, by: 1)) {
            let curr = traj[idx]
            guard let prevVal = prev else {
                prev = curr
//                debugBezier.move(to: curr.control ?? curr.point)
                continue
            }
            let fromSize = penSize(speed: prevVal.speed)
            let toSize = penSize(speed: curr.speed)
            
            let from = prevVal.point
            let to = curr.point
            if let control = reversed ? curr.control : prevVal.control {
                optimizedManualBezier(from: from, to: to, control: control, fromWidth: fromSize, toWidth: toSize, inOutBezier: &bezier)
            } else {
                // straight line
                let norm = to.substract(from).norm.rot90
                bezier.addLine(to: to.add(norm.mulitply(toSize)))
//                    debugBezier.addLine(to: to)
            }
//            if let debugContext = debugContext, reversed {
//                let img = debugContext.makeImage().map({UIImage(cgImage: $0)})
//                print(img?.size)
//            }
            prev = curr
        }
    }
    
    fileprivate func optimizedManualBezier(from: CGPoint, to: CGPoint, control: CGPoint, fromWidth: CGFloat, toWidth: CGFloat, inOutBezier: inout UIBezierPath) {
        // generate points if we have curve on line
        
        let calcPoint: (CGFloat)->(CGPoint) = { (t: CGFloat) -> CGPoint in
            let t1 = pow(1 - t, 2)
            let t2 = 2.0 * (1 - t) * t
            let t3 = pow(t, 2)
            let p = from.mulitply(t1).add(control.mulitply(t2)).add(to.mulitply(t3))
            return p
        }
        let calcWidth: (CGFloat)->(CGFloat) = { fromWidth * (1-$0) + toWidth * $0 }
        let maxPixErr: CGFloat = 0.2
        let maxPixErrSqr = pow(maxPixErr, 2)
        let cosValThresh: CGFloat = 0.8
        
        var pointsT: [(p:CGPoint, t:CGFloat)] = [(from, 0), (to, 1)]
        var idx: Int = 1
        var localNormals: [CGPoint] = []
        let maxCount: Int = 200
        while idx < pointsT.count && pointsT.count < maxCount {
            let p1 = pointsT[idx-1]
            let p2 = pointsT[idx]
            
            // generate middle point and how swtrong is bend
            let midT = (p1.t + p2.t) / 2.0
            let midP = calcPoint(midT)
            
            var cosVal: CGFloat = 1
            if idx+1 < pointsT.count {
                cosVal = calcCosVal(p1: p1.p, p2: p2.p, p3: pointsT[idx+1].p)
                if cosVal.isNaN {
                    cosVal = 1
                }
            }
            
            if cosVal < cosValThresh {
                pointsT.insert((midP, midT), at: idx)
                // too strong bend, generate points by both side of bend
                let nextT = (pointsT[idx+1].t + pointsT[idx+2].t) / 2.0
                pointsT.insert((calcPoint(nextT), nextT), at: idx+2)
                continue
            }
            
            // check distance error, if it small we skip generating new point
            // don't forgot about offsets, it's final points
            localNormals = generateNormals(from: from, to: to, control: control, tArr: [p1.t, midT, p2.t], toRight: true)
            let p1w = p1.p.add(localNormals[0].mulitply(calcWidth(p1.t)))
            let midPw = midP.add(localNormals[1].mulitply(calcWidth(midT)))
            let p2w = p2.p.add(localNormals[2].mulitply(calcWidth(p2.t)))
            
            let distSqr = sqrDist(point: midPw, toLine: (p1w, p2w))
            if distSqr > maxPixErrSqr {
                pointsT.insert((midP, midT), at: idx)
                continue
            }
            
            // bend and error is too small, no need new points
            idx += 1
        }
        let normals = generateNormals(from: from, to: to, control: control, tArr: pointsT.map({$0.t}), toRight: true)
        
        for i in 0..<pointsT.count {
            let t = pointsT[i].t
            let width = fromWidth * (1-t) + toWidth * t
            let p = pointsT[i].p.add(normals[i].mulitply(width))
            if inOutBezier.isEmpty {
                inOutBezier.move(to: p)
            } else {
                inOutBezier.addLine(to: p)
            }
        }
    }
    
    private func penSize(speed: Double) -> CGFloat {
        return speed
            .percent(min: maxPixSpeed*scrollZoomScale, max: minPixSpeed*scrollZoomScale)
            .clamp(0, 1)
            .percentToRange(min: minBrushSizeMultiplier * penSize, max: penSize)
    }
    
    
    private func generateNormals(from: CGPoint, to: CGPoint, control: CGPoint, tArr: [CGFloat], toRight: Bool) -> [CGPoint] {
        // based on https://pomax.github.io/bezierinfo/chapters/pointvectors/pointvectors.js
        // https://pomax.github.io/bezierinfo/#pointvectors
        let d0 = CGPoint(x: 2 * (control.x - from.x), y: 2 * (control.y - from.y))
        let d1 = CGPoint(x: 2 * (to.x - control.x), y: 2 * (to.y - control.y))
        var normalArr: [CGPoint] = []
        normalArr.reserveCapacity(tArr.count)
        for t in tArr {
            let mt = (1 - t)
            let d = CGPoint(x: mt * d0.x + t * d1.x,
                            y: mt * d0.y + t * d1.y)
            
            let q = sqrt(d.x * d.x + d.y * d.y)
            let normal: CGPoint
            if q == 0 {
                let n = to.substract(from).norm
                normal = toRight ? n.rot90 : n.rot270
            } else if toRight {
                normal = CGPoint(x: d.y / q, y: -d.x / q)
            } else {
                normal = CGPoint(x: -d.y / q, y: d.x / q)
            }
            normalArr.append(normal)
        }
        return normalArr
    }
    
    fileprivate func getQuadraticDerivative(points: [CGPoint], t: CGFloat) -> CGPoint {
        let mt = (1 - t)
        let d0 = CGPoint(x: 2 * (points[1].x - points[0].x), y: 2 * (points[1].y - points[0].y))
        let d1 = CGPoint(x: 2 * (points[2].x - points[1].x), y: 2 * (points[2].y - points[1].y))

        return CGPoint(x: mt * d0.x + t * d1.x,
                       y: mt * d0.y + t * d1.y)
    }
    
    fileprivate func calcCosVal(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
        return p3.substract(p2).normDot(p2.substract(p1))
    }
    
    fileprivate func sqrDist(point: CGPoint, toLine: (CGPoint, CGPoint)) -> CGFloat {
        return project(point: point, toLine: toLine).p.distanceSqr(p: point)
    }
    
    fileprivate func project(point: CGPoint, toLine: (CGPoint, CGPoint)) -> (p: CGPoint, t: CGFloat) {
        // based on https://stackoverflow.com/a/1501725/820795
        let lineVec = toLine.1.substract(toLine.0)
        let l2 = lineVec.distanceSqr()  // i.e. |w-v|^2 -  avoid a sqrt
        if (l2 == 0.0) { return (toLine.0, 0) }   // v == w case
        
        let t = point.substract(toLine.0).dot(lineVec) / l2
        let proj = toLine.0.add(lineVec.mulitply(t))
        return (proj, t)
    }
}

private extension PanPoint {
    func mid(p: PanPoint) -> CGPoint {
        return CGPoint(x: (point.x + p.point.x) / 2.0,
                       y: (point.y + p.point.y) / 2.0)
    }
    func speed(p: PanPoint) -> Double {
        if abs(time - p.time) < 0.00001 {
            return 9999.0
        }
        
        let dist = p.point.substract(point).distance()
        let speed = dist / abs(time - p.time)
        return speed
    }
}
