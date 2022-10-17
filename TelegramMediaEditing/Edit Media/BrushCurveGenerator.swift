//
//  BrushCurveGenerator.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 14.10.2022.
//

import UIKit

struct PanPoint {
    internal init(point: CGPoint, time: CFTimeInterval = CACurrentMediaTime()) {
        self.point = point
        self.time = time
    }
    
    let point: CGPoint
    let time: CFTimeInterval
    var speed: Double?
}

extension PanPoint: SimplifyValue, Point2f {
    var xValue: Double { point.x }
    var yValue: Double { point.y }
}

//extension PanPoint: SimplifyValue, Point3f {
//    var xValue: Double { point.x }
//    var yValue: Double { point.y }
//    var zValue: Double { time }
//}

class BrushCurveGenerator {
    enum BrushType {
        case standart
    }
    let maxPixSpeed: Double = 1000
    let minPixSpeed: Double = 100
    var brushSize: CGFloat = 30
    var minBrushSizeMultiplier: CGFloat = 0.3
    /// какой продолжительности отдается шлейф за кистью
    var plumeDurationSec: CFTimeInterval = 0.5
    var scrollZoomScale: CGFloat = 1
    
    
    func testSquare() -> UIBezierPath {
        var points = [
            PanPoint(point: CGPoint(x: 0, y: 0), time: 0),
            PanPoint(point: CGPoint(x: 100, y: 0), time: 1),
            PanPoint(point: CGPoint(x: 100, y: 100), time: 1.4),
            PanPoint(point: CGPoint(x: 0, y: 100), time: 1.5)
        ]
        let poly = generatePolygon(type: .standart, points: points)
        return poly
    }
//    func testCircleMinMaxSpeed() -> UIBezierPath {
//        var points: [PanPoint] = []
//        let count = 50
//        var time: Double = 0
//        for i in 0..<count {
//            let percent = CGFloat(i) / CGFloat(count)
//            let angl = percent * 2 * .pi
//            let p = CGPoint(x: cos(angl), y: sin(angl))
//            PanPoint(
//        }
//    }
    
    func generateStrokePolygon(type: BrushType, points: [PanPoint]) -> UIBezierPath {
        let traj = generateSmoothTrajectory(points: points)
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
    func generatePolygon(type: BrushType, points: [PanPoint]) -> UIBezierPath {
        let traj = generateSmoothTrajectory(points: points)
//        print("Points count", points.count)
        let bezier = trajectoryToBrushPoly(traj: traj)
        return bezier
    }
    // MARK: - private
    private struct DrawBezierInfo {
        var point: CGPoint
        var control: CGPoint?
        var speed: Double
    }
    
    private func generateSmoothTrajectory(points: [PanPoint]) -> [DrawBezierInfo] {
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
        if points.count < 2 {
            return points.map({DrawBezierInfo(point: $0.point, control: $0.point, speed: minPixSpeed)})
        }
        print("ªªª", 200 * scrollZoomScale)
        GausianSmooth.smoothSpeed(points: &points, distWindow: 200 * scrollZoomScale)
        
//        points = Simplify.simplify(points, tolerance: 10, highQuality: true)
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
    
    private var debugContext: CGContext?
    private var debugContextOffset: CGPoint?
    
    private func trajectoryToBrushPoly(traj: [DrawBezierInfo]) -> UIBezierPath {
        var bezier = UIBezierPath()
        if traj.isEmpty { return bezier }
        if traj.count == 1 {
            let size = brushSize(speed: traj[0].speed)
            bezier = UIBezierPath(ovalIn: CGRect(mid: traj[0].point, size: CGSize(width: size, height: size)))
            return bezier
        }
        if traj.count == 20 {
            print("test")
        }
        
        var minPoint = traj[0].point
        var maxPoint = traj[0].point
        for t in traj {
            minPoint.x = min(t.point.x, minPoint.x)
            minPoint.y = min(t.point.y, minPoint.y)
            maxPoint.x = max(t.point.x, maxPoint.x)
            maxPoint.y = max(t.point.y, maxPoint.y)
        }
        minPoint.x -= 50; minPoint.y -= 50
        maxPoint.x += 50; maxPoint.y += 50
        debugContextOffset = minPoint
        
        
        let contextSize = maxPoint.substract(minPoint).size
        UIGraphicsBeginImageContextWithOptions(contextSize, true, 0)
        debugContext = UIGraphicsGetCurrentContext()
        UIColor.white.setFill()
        UIColor.red.setStroke()
        debugContext?.fill(CGRect(origin: .zero, size: contextSize))
        debugContext?.translateBy(x: -minPoint.x, y: -minPoint.y)
        
        // рисуем по правой стороне в одну сторону, и по левой в обратную
        // проходим по массиву 2 раза
        brushStartCirleLeftRightConterClock(start: traj[0], end: traj[1], moveToStart: true, bezier: &bezier)
        brushRightSide(traj: traj, reversed: false, bezier: &bezier)
        
//        debugContext?.translateBy(x: 10, y: 0)
//        debugContext?.strokeLineSegments(between: [.zero, contextSize.point])
        
        brushStartCirleLeftRightConterClock(start: traj[traj.count-1], end: traj[traj.count-2], moveToStart: false, bezier: &bezier)
        brushRightSide(traj: traj, reversed: true, bezier: &bezier)
        
        bezier.close()
        UIGraphicsEndImageContext()
        return bezier
    }
    
    private func brushStartCirleLeftRightConterClock(start: DrawBezierInfo, end: DrawBezierInfo, moveToStart: Bool, bezier: inout UIBezierPath) {
        let dirNorm = end.point.substract(start.point).norm
        let startSize = brushSize(speed: start.speed)
        let angl = atan2(dirNorm.y, dirNorm.x)
//        if moveToStart {
//            let leftNorm = dirNorm.rot270
//            let startPoint = start.point.add(leftNorm.mulitply(startSize))
//            bezier.move(to: startPoint)
//        }
        bezier.addArc(withCenter: start.point, radius: startSize, startAngle: angl+CGFloat.pi*0.5, endAngle: angl+CGFloat.pi*1.5, clockwise: true)
    }
    
    private func generateNormals(traj: [DrawBezierInfo], toRight: Bool) -> [CGPoint] {
        // angle of neigbor lines can be differ
        // so first calculate mean angle for each point
        // insead of angle use normal directed to right
        var normalArr: [CGPoint] = []
        normalArr.reserveCapacity(traj.count)
        for idx in 0..<traj.count {
            let i1 = max(0, idx - 1)
            let i2 = min(traj.count-1, idx + 1)
            let dir: CGPoint = traj[i2].point.substract(traj[i1].point)
            let normDir = toRight ? dir.norm.rot90 : dir.norm.rot270
            normalArr.append(normDir)
        }
        return normalArr
    }
    
    private func brushRightSide(traj: [DrawBezierInfo], reversed: Bool, bezier: inout UIBezierPath) {
        var debugBezier = UIBezierPath()
        var prev: DrawBezierInfo?
        var prevIdx: Int = -1
        let rightNormalArr: [CGPoint] = generateNormals(traj: traj, toRight: !reversed)
        
//        stride(from: 0, to: traj.count, by: 1)
//        stride(from: traj.count-1, to: -1, by: 1)
        for idx in (reversed ? stride(from: traj.count-1, to: -1, by: -1) : stride(from: 0, to: traj.count, by: 1)) {
//        for idx in (reversed ? (0..<traj.count).reversed() : (0..<traj.count)) {
//
//        }
//        for curr in (reversed ? traj.reversed() : traj) {
            let curr = traj[idx]
            guard let prevVal = prev else {
                prev = curr
                prevIdx = idx
//                debugBezier.move(to: curr.control ?? curr.point)
                continue
            }
            let fromSize = brushSize(speed: prevVal.speed)
            let toSize = brushSize(speed: curr.speed)
            
            let fromOffset = rightNormalArr[prevIdx].mulitply(fromSize)
            let toOffset = rightNormalArr[idx].mulitply(toSize)
            let from = prevVal.point.add(fromOffset)
            let to = curr.point.add(toOffset)
            debugContext?.setLineWidth(1)
            debugContext?.setStrokeColor(UIColor.red.cgColor)
            debugContext?.setFillColor(UIColor.blue.cgColor)
            debugContext?.strokeLineSegments(between: [prevVal.point, curr.point])
            debugContext?.fillEllipse(in: CGRect(mid: prevVal.point, size: CGSize(width: 3, height: 3)))
            debugContext?.fillEllipse(in: CGRect(mid: curr.point, size: CGSize(width: 3, height: 3)))
            
            if var control = reversed ? curr.control : prevVal.control {
                debugContext?.setLineWidth(1)
                debugContext?.setStrokeColor(UIColor.green.cgColor)
                debugContext?.addEllipse(in: CGRect(mid: control, size: CGSize(width: 5, height: 5)))
                debugContext?.strokePath()
                
                control = control.add(fromOffset.add(toOffset).mulitply(0.5))
                bezier.addQuadCurve(to: to, controlPoint: control)
//                bezier.addLine(to: control)
                debugBezier.addLine(to: control)
                
                debugContext?.move(to: prevVal.point)
                debugContext?.addLine(to: from)
                debugContext?.move(to: curr.point)
                debugContext?.addLine(to: to)
                debugContext?.strokePath()
                
                debugContext?.setStrokeColor(UIColor.blue.cgColor)
                debugContext?.setLineWidth(2)
                debugContext?.move(to: from)
                debugContext?.addQuadCurve(to: to, control: control)
                debugContext?.strokePath()
                debugContext?.setLineWidth(1)
                debugContext?.addEllipse(in: CGRect(mid: control, size: CGSize(width: 5, height: 5)))
                debugContext?.strokePath()
            } else {
                // straight line
                bezier.addLine(to: to)
                debugBezier.addLine(to: to)
            }
            if let debugContext = debugContext, reversed {
                
                let img = debugContext.makeImage().map({UIImage(cgImage: $0)})
                print(img?.size)
            }
            prev = curr
            prevIdx = idx
        }
    }
    
    private func brushSize(speed: Double) -> CGFloat {
        return speed
            .percent(min: maxPixSpeed*scrollZoomScale, max: minPixSpeed*scrollZoomScale)
            .clamp(0, 1)
            .percentToRange(min: minBrushSizeMultiplier * brushSize, max: brushSize)
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
