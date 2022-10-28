//
//  ToolCurveGenerator.swift
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


class ToolCurveGenerator {
    struct PenSettings {
        let minPenSizeMultiplier: CGFloat = 0.4
        let maxPixSpeed: Double = 800
        let minPixSpeed: Double = 50
        /// какой продолжительности отдается шлейф за кистью
        var plumePointsCount: CGFloat = 10
        /// 0 - minPixSpeed, 1 - maxPixSpeed
        var plumeLastSpeedPercent: CGFloat = 0.2
    }
    
    struct MarkerSettings {
        let angle: CGFloat = .pi * (70 / 180)
        let minSizePercent: CGFloat = 0.5
    }
    
    var mode: ToolType = .pen
    var pen = PenSettings()
    var marker = MarkerSettings()
    var toolSize: CGFloat = 30
    var scrollZoomScale: CGFloat = 1
    var markerBendPoints: [CGPoint] = []
    
    // Only for pen
    func finishPlumAnimation(points: [PanPoint], onLayer: CAShapeLayer, duration: Double) {
        var penSett = pen
        let startPlumePointsCount = pen.plumePointsCount
        let startPlumeLastSpeedPercent = pen.plumeLastSpeedPercent
        _ = DisplayLinkAnimator.animate(duration: duration) { percent in
//            if onLayer.superlayer == nil { return }
            penSett.plumePointsCount = (1-percent) * startPlumePointsCount
            penSett.plumeLastSpeedPercent = percent * (1 - startPlumeLastSpeedPercent) + startPlumeLastSpeedPercent
            let restorePen = self.pen
            self.pen = penSett
            let path = self.generatePolygon(points: points)
            self.pen = restorePen
            onLayer.path = path.cgPath
        }
    }
    
    func generateStrokePolygon(points: [PanPoint]) -> UIBezierPath {
        let traj = generateSmoothTrajectory(points: points, plumePointsCount: pen.plumePointsCount)
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
        let traj = generateSmoothTrajectory(points: points, plumePointsCount: withPlume ? pen.plumePointsCount : 0)
//        print("Points count", points.count)
        let bezier = trajectoryToPenPoly(traj: traj)
        return bezier
    }
    // MARK: - private
    fileprivate struct DrawBezierInfo {
        var point: CGPoint
        var control: CGPoint?
        var speed: Double
    }
    private let gausDistWindow: CGFloat = 300
    
    private func generateSmoothTrajectory(points: [PanPoint], plumePointsCount: CGFloat) -> [DrawBezierInfo] {
        if points.count < 2 {
            return points.map({DrawBezierInfo(point: $0.point, control: $0.point, speed: pen.minPixSpeed)})
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
            let lastPlumSpeed = pen.plumeLastSpeedPercent * (pen.maxPixSpeed - pen.minPixSpeed) * scrollZoomScale
            PenPlume.makePlumeOnEndPath(points: &points, lastNPoints: plumePointsCount, lastPointOverrideSpeed: lastPlumSpeed)
        }
        
        if points.count < 2 {
            return points.map({DrawBezierInfo(point: $0.point, control: $0.point, speed: pen.minPixSpeed)})
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
            var size: CGFloat = toolSize
            if mode == .pen {
                size = penSize(speed: traj[0].speed)
            }
            bezier = UIBezierPath(ovalIn: CGRect(mid: traj[0].point, size: CGSize(width: size, height: size)))
            return bezier
        }
        
        // рисуем по правой стороне в одну сторону, и по левой в обратную
        // проходим по массиву 2 раза
        if mode == .pen {
            penStartCirleLeftRightConterClock(start: traj[0], end: traj[1], moveToStart: true, bezier: &bezier)
            penRightSide(traj: traj, reversed: false, bezier: &bezier)
            
            penStartCirleLeftRightConterClock(start: traj[traj.count-1], end: traj[traj.count-2], moveToStart: false, bezier: &bezier)
            penRightSide(traj: traj, reversed: true, bezier: &bezier)
            
            bezier.close()
        } else if mode == .marker || mode == .neon || mode == .pencil {
            markerBendPoints = []
            trajToBezier(traj: traj, reversed: false, bezier: &bezier)
            
//            bezier.append(markerEllipse(inPoint: traj[0].point))
//            bezier.append(markerEllipse(inPoint: traj.last!.point))
        }
        
//        UIGraphicsEndImageContext()
        return bezier
    }
    
    private func markerSize(direction: CGFloat) -> CGFloat {
        var dAngle = abs(marker.angle - direction)
        while dAngle > .pi / 2 {
            dAngle -= .pi
        }
        let percent: CGFloat = (abs(dAngle) / (.pi / 2))
        return percent.percentToRange(min: marker.minSizePercent*toolSize, max: toolSize)
    }
    
//    private func markerSize(normal: CGPoint) -> CGFloat {
//        let dir = atan2(normal.x, normal.y) // swap x/y to get line direction
//        return markerSize(direction: dir)
//    }
    private func markerOffset(normal: CGPoint) -> CGPoint {
        let dir = atan2(normal.x, normal.y) // swap x/y to get line direction
        let size = markerSize(direction: dir)
        return normal.mulitply(size)
    }
    
    private func markerEllipse(inPoint: CGPoint) -> UIBezierPath {
        let bezier = UIBezierPath(ovalIn: CGRect(mid: .zero, size: CGSize(width: toolSize, height: toolSize*marker.minSizePercent)))
        bezier.apply(CGAffineTransform(rotationAngle: marker.angle))
        bezier.apply(CGAffineTransform(translationX: inPoint.x, y: inPoint.y))
        return bezier
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

// MARK: - Pen
extension ToolCurveGenerator {
    fileprivate func penStartCirleLeftRightConterClock(start: DrawBezierInfo, end: DrawBezierInfo, moveToStart: Bool, bezier: inout UIBezierPath) {
        let dirNorm = end.point.substract(start.point).norm
        let startSize = penSize(speed: start.speed)
        let angl = atan2(dirNorm.y, dirNorm.x)
        bezier.addArc(withCenter: start.point, radius: startSize, startAngle: angl+CGFloat.pi*0.5, endAngle: angl+CGFloat.pi*1.5, clockwise: true)
    }
    
    fileprivate func penRightSide(traj: [DrawBezierInfo], reversed: Bool, bezier: inout UIBezierPath) {
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
    
    fileprivate func penSize(speed: Double) -> CGFloat {
        return speed
            .percent(min: pen.maxPixSpeed*scrollZoomScale, max: pen.minPixSpeed*scrollZoomScale)
            .clamp(0, 1)
            .percentToRange(min: pen.minPenSizeMultiplier * toolSize, max: toolSize)
    }
    
    fileprivate func optimizedManualBezier(from: CGPoint, to: CGPoint, control: CGPoint, fromWidth: CGFloat, toWidth: CGFloat, inOutBezier: inout UIBezierPath) {
        // generate points if we have curve on line
        
        let bezier = Bezier(from: from, to: to, control: control)
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
            let midP = bezier.getPoint(t: midT)
            
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
                pointsT.insert((bezier.getPoint(t: nextT), nextT), at: idx+2)
                continue
            }
            
            // check distance error, if it small we skip generating new point
            // don't forgot about offsets, it's final points
            localNormals = bezier.generateNormals(tArr: [p1.t, midT, p2.t], toRight: true)
            let p1w = p1.p.add(localNormals[0].mulitply(calcWidth(p1.t)))
            let midPw = midP.add(localNormals[1].mulitply(calcWidth(midT)))
            let p2w = p2.p.add(localNormals[2].mulitply(calcWidth(p2.t)))
            
            let distSqr = sqrDist(point: midPw, toLine: (p1w, p2w))
            if distSqr > maxPixErrSqr {
                pointsT.insert((midP, midT), at: idx) // TODO: we spend here lot of time, try other struct
                continue
            }
            
            // bend and error is too small, no need new points
            idx += 1
        }
        let normals = bezier.generateNormals(tArr: pointsT.map({$0.t}), toRight: true)
        
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
}

// MARK: - Marker
extension ToolCurveGenerator {
    
    fileprivate func trajToBezier(traj: [DrawBezierInfo], reversed: Bool, bezier: inout UIBezierPath) {
        var prev: DrawBezierInfo?
        
        var needMoveTo = true
        for idx in (reversed ? stride(from: traj.count-1, to: -1, by: -1) : stride(from: 0, to: traj.count, by: 1)) {
            let curr = traj[idx]
            guard let prevVal = prev else {
                prev = curr
                continue
            }
//
            let from = prevVal.point
            let to = curr.point
            if needMoveTo {
                bezier.move(to: from)
                needMoveTo = false
            }
            if let control = reversed ? curr.control : prevVal.control {
                bezier.addQuadCurve(to: to, controlPoint: control)
                
                // fix bend points works strange
                // maybe Apple math behid Bezier differ from curren implementation
//                addMarkerBendPoints(from: from, to: to, control: control)
            } else {
                // straight line
                bezier.addLine(to: to)
            }
            prev = curr
        }
    }
    
    fileprivate func addMarkerBendPoints(from: CGPoint, to: CGPoint, control: CGPoint) {
        let b = Bezier(from: from, to: to, control: control)
        var t = b.closestTtoControlSimple()
        var p = b.getPoint(t: t)
        let val = calcCosVal(p1: from, p2: p, p3: to)
        
        if val.isNaN || val > 0.4 { return }
        
        print(val)
        t = b.closestTtoControl()
        p = b.getPoint(t: t)
        markerBendPoints.append(p)
    }
}
