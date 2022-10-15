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
}

class BrushCurveGenerator {
    enum BrushType {
        case standart
    }
    let maxPixSpeed: Double = 3000
    let minPixSpeed: Double = 100
    var brushSize: CGFloat = 30
    var minBrushSizeMultiplier: CGFloat = 0.3
    /// какой продолжительности отдается шлейф за кистью
    var plumeDurationSec: CFTimeInterval = 0.5
    
    
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
    
    func generatePolygon(type: BrushType, points: [PanPoint]) -> UIBezierPath {
        let traj = generateSmoothTrajectory(points: points)
        print("Points count", points.count)
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
        
        var result: [DrawBezierInfo] = []
        // reserve first point, change it later
        result.append(DrawBezierInfo(point: .zero, control: nil, speed: 0))
        for i in 1..<points.count {
            let p1 = points[i-1]
            let p2 = points[i]
            let info = DrawBezierInfo(point: p1.mid(p: p2),
                                      control: p2.point,
                                      speed: p1.speed(p: p2))
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
        
        // рисуем по правой стороне в одну сторону, и по левой в обратную
        // проходим по массиву 2 раза
        brushStartCirleLeftRightConterClock(start: traj[0], end: traj[1], moveToStart: true, bezier: &bezier)
        brushRightSide(traj: traj, reversed: false, bezier: &bezier)
        
        brushStartCirleLeftRightConterClock(start: traj[traj.count-1], end: traj[traj.count-2], moveToStart: false, bezier: &bezier)
        brushRightSide(traj: traj, reversed: true, bezier: &bezier)
        
        bezier.close()
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
    
    private func brushRightSide(traj: [DrawBezierInfo], reversed: Bool, bezier: inout UIBezierPath) {
        var prev: DrawBezierInfo?
        for curr in (reversed ? traj.reversed() : traj) {
            guard let prevVal = prev else {
                prev = curr
                continue
            }
            let dir = curr.point.substract(prevVal.point)
            let rightNorm = dir.norm.rot90
            let fromSize = brushSize(speed: prevVal.speed)
            let toSize = brushSize(speed: curr.speed)
            
            let fromOffset = rightNorm.mulitply(fromSize)
            let toOffset = rightNorm.mulitply(toSize)
//            let from = prevVal.point.add(fromOffset)
            let to = curr.point.add(toOffset)
            if var control = reversed ? curr.control : prevVal.control {
                control = control.add(fromOffset.add(toOffset).mulitply(0.5))
                bezier.addQuadCurve(to: to, controlPoint: control)
            } else {
                // straight line
                bezier.addLine(to: to)
            }
            prev = curr
        }
    }
    
    private func brushSize(speed: Double) -> CGFloat {
        return speed
            .percent(min: maxPixSpeed, max: minPixSpeed)
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
