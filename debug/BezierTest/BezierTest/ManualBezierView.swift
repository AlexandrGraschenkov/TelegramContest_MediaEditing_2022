//
//  ManualBezier.swift
//  BezierTest
//
//  Created by Alexander Graschenkov on 17.10.2022.
//

import UIKit

class ManualBezierView: UIView {

    enum Algo: Int {
        case fixedCount = 0, optimized1, optimized2
    }
    
    var points: [CGPoint] = [CGPoint(x: 100, y: 100), CGPoint(x: 200, y: 100), CGPoint(x: 300, y: 300)] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var offset1: CGFloat = 10 {
        didSet { setNeedsDisplay() }
    }
    var offset2: CGFloat = 10 {
        didSet { setNeedsDisplay() }
    }
    var algo: Algo = .fixedCount {
        didSet { setNeedsDisplay() }
    }
    var drawPoints: Bool = false {
        didSet { setNeedsDisplay() }
    }
    var drawResult: Bool = false {
        didSet {
            resultLayer.isHidden = !drawResult
        }
    }
    lazy var resultLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.strokeColor = UIColor.darkGray.cgColor
        l.lineWidth = 1
        l.fillColor = UIColor.green.cgColor
        l.isHidden = !drawResult
        superview?.layer.addSublayer(l)
        return l
    }()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let p1 = points[0]
        let control = points[1]
        let p2 = points[2]
        
        ctx.setLineWidth(2)
        UIColor.blue.setStroke()
        UIColor(red: 0.1, green: 0.6, blue: 0.1, alpha: 1).setFill()
        ctx.move(to: p1)
        ctx.addQuadCurve(to: p2, control: control)
        ctx.strokePath()
        
        let dotSize = CGSize(width: 7, height: 7)
        ctx.setLineDash(phase: 0, lengths: [5, 5])
        UIColor.gray.setStroke()
        ctx.move(to: p1)
        ctx.addLine(to: control)
        ctx.addLine(to: p2)
        ctx.strokePath()
        
        ctx.addEllipse(in: CGRect(mid: p1, size: dotSize))
        ctx.addEllipse(in: CGRect(mid: p2, size: dotSize))
        ctx.fillPath()
        UIColor.blue.setFill()
        ctx.fillEllipse(in: CGRect(mid: control, size: dotSize))
        
        // Manual bezier
        ctx.setLineDash(phase: 0, lengths: [])
        UIColor.systemRed.setStroke()
        var bezier = UIBezierPath()
        let points: [CGPoint]
        let points2: [CGPoint]
        switch algo {
        case .fixedCount:
            points = manualBezier(from: p1, to: p2, control: control, fromWidth: offset1, toWidth: offset2, inOutBezier: &bezier)
            points2 = manualBezier(from: p2, to: p1, control: control, fromWidth: offset2, toWidth: offset1, inOutBezier: &bezier)
        case .optimized1:
            points = optimizedManualBezier(from: p1, to: p2, control: control, fromWidth: offset1, toWidth: offset2, inOutBezier: &bezier)
            points2 = optimizedManualBezier(from: p2, to: p1, control: control, fromWidth: offset1, toWidth: offset1, inOutBezier: &bezier)
        case .optimized2:
            points = optimizedManualBezier2(from: p1, to: p2, control: control, fromWidth: offset1, toWidth: offset2, inOutBezier: &bezier)
            points2 = optimizedManualBezier2(from: p2, to: p1, control: control, fromWidth: offset2, toWidth: offset1, inOutBezier: &bezier)
        }
        
        for i in 0..<points.count {
            let p = points[i]
            if i == 0 { ctx.move(to: p) }
            else { ctx.addLine(to: p) }
        }
        ctx.strokePath()
        if drawPoints {
            for i in 0..<points.count {
                let p = points[i]
                ctx.addEllipse(in: CGRect(mid: p, size: CGSize(width: 4, height: 4)))
            }
        }
        ctx.setFillColor(UIColor.cyan.cgColor)
        ctx.fillPath()
        bezier.close()
        resultLayer.path = bezier.cgPath
        resultLayer.fillRule = .nonZero
    }
    
    private func generateNormals(points: [CGPoint], toRight: Bool) -> [CGPoint] {
        // angle of neigbor lines can be differ
        // so first calculate mean angle for each point
        // insead of angle use normal directed to right
        var normalArr: [CGPoint] = []
        normalArr.reserveCapacity(points.count)
        for idx in 0..<points.count {
            let i1 = max(0, idx - 1)
            let i2 = min(points.count-1, idx + 1)
            let dir: CGPoint = points[i2].substract(points[i1])
            let normDir = toRight ? dir.norm.rot90 : dir.norm.rot270
            normalArr.append(normDir)
        }
        return normalArr
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
            if toRight {
                normal = CGPoint(x: d.y / q, y: -d.x / q)
            } else {
                normal = CGPoint(x: -d.y / q, y: d.x / q)
            }
            normalArr.append(normal)
        }
        return normalArr
    }
    
    fileprivate func manualBezier(from: CGPoint, to: CGPoint, control: CGPoint, fromWidth: CGFloat, toWidth: CGFloat, inOutBezier: inout UIBezierPath) -> [CGPoint] {
        if from == to {
            return [from]
        }
        let segmentDistance: CGFloat = 2
        var numberOfSegments: Int = 60
//        if from != control && to != control {
//            let distance = from.distance(p: to)
//            let controlCosAngle = control.substract(from).normDot(to.substract(from))
//            let weight = max(5, distance) * (1-40*controlCosAngle)
//            numberOfSegments = min(128, max(Int(weight / segmentDistance), 2))
//
//            print("Num seg", numberOfSegments, "; Cos", controlCosAngle)
//            if controlCosAngle < 0 {
//                print("",terminator: "")
//            }
//        }
        
        var t: Double = 0.0
        let step = 1.0 / CGFloat(numberOfSegments)
        var points: [CGPoint] = []
        var widthArr: [CGFloat] = []
        points.reserveCapacity(numberOfSegments)
        widthArr.reserveCapacity(numberOfSegments)
        for _ in 0..<numberOfSegments {
            let t1 = pow(1 - t, 2)
            let t2 = 2.0 * (1 - t) * t
            let t3 = pow(t, 2)
            let p = from.mulitply(t1).add(control.mulitply(t2)).add(to.mulitply(t3))
            let w = fromWidth * (1-t) + toWidth * t
            points.append(p)
            widthArr.append(w)
            t += step
        }
        let normals = generateNormals(points: points, toRight: true)
        let ctx = UIGraphicsGetCurrentContext()
        
        for i in 0..<points.count {
            points[i] = points[i].add(normals[i].mulitply(widthArr[i]))
        }
        
        if inOutBezier.isEmpty {
            inOutBezier.move(to: points[0])
        }
        for i in 0..<points.count {
            let p = points[i]
            inOutBezier.addLine(to: p)
        }
        return points
    }
    
    
    fileprivate func calcCosVal(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
        return p3.substract(p2).normDot(p2.substract(p1))
    }
    fileprivate func optimizedManualBezier(from: CGPoint, to: CGPoint, control: CGPoint, fromWidth: CGFloat, toWidth: CGFloat, inOutBezier: inout UIBezierPath) -> [CGPoint] {
        // generate points if we have curve on line
        let cosThresh1 = 0.95
        let cosThresh2 = 0.98
        let calcPoint: (CGFloat)->((CGPoint)) = { (t: CGFloat) -> CGPoint in
            let t1 = pow(1 - t, 2)
            let t2 = 2.0 * (1 - t) * t
            let t3 = pow(t, 2)
            let p = from.mulitply(t1).add(control.mulitply(t2)).add(to.mulitply(t3))
            return p
        }
        
        var pointsT: [(p:CGPoint, t:CGFloat)] = [(from, 0), (calcPoint(0.5), 0.5), (to, 1)]
        var idx: Int = 1
        let maxThreshCount = 200
        while idx+1 < pointsT.count {
            var cosVal = calcCosVal(p1: pointsT[idx-1].p, p2: pointsT[idx].p, p3: pointsT[idx+1].p)
            if cosVal.isNaN {
                cosVal = 1
            }
            if cosVal > cosThresh2 {
                idx += 1
                continue
            }
            let d = pointsT[idx-1].p.distance(p: pointsT[idx].p)
            if cosVal > cosThresh1 && d < 10 {
                idx += 1
                continue
            }
            
            // split unlit we not get almost straight lines
            let midT1 = (pointsT[idx-1].t + pointsT[idx].t) / 2.0
            let midT2 = (pointsT[idx+1].t + pointsT[idx].t) / 2.0
            // insert order matter to not mess up with indexes
            pointsT.insert((calcPoint(midT2), midT2), at: idx+1)
            pointsT.insert((calcPoint(midT1), midT1), at: idx)
        }
        var points = pointsT.map({$0.p})
        let normals = generateNormals(points: points, toRight: true)
        
        if inOutBezier.isEmpty {
            inOutBezier.move(to: points[0])
        }
        for i in 0..<points.count {
            let t = pointsT[i].t
            let width = fromWidth * (1-t) + toWidth * t
            let p = points[i].add(normals[i].mulitply(width))
            inOutBezier.addLine(to: p)
            points[i] = p
        }
        
        return points
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
    
    fileprivate func generateDebugImage(points: [CGPoint], idx: Int, p: CGPoint) -> UIImage? {
        var tl = p
        var br = p
        for p in points {
            tl.x = min(p.x, tl.x)
            tl.y = min(p.y, tl.y)
            br.x = max(p.x, br.x)
            br.y = max(p.y, br.y)
        }
        var rect = CGRect(origin: tl, size: br.substract(tl).size)
        rect = rect.insetBy(dx: -10, dy: -10)
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.translateBy(x: -rect.minX, y: -rect.minY)
        ctx?.setFillColor(UIColor.white.cgColor)
        ctx?.fill(rect)
        ctx?.setLineWidth(2)
        
        ctx?.move(to: points[0])
        for point in points {
            ctx?.addLine(to: point)
        }
        ctx?.setStrokeColor(UIColor.blue.cgColor)
        ctx?.strokePath()
        ctx?.setStrokeColor(UIColor.red.cgColor)
        ctx?.move(to: points[idx-1])
        ctx?.addLine(to: p)
        ctx?.addLine(to: points[idx])
        ctx?.strokePath()
        
        ctx?.setFillColor(UIColor.darkGray.cgColor)
        for point in points {
            ctx?.fillEllipse(in: CGRect(mid: point, size: CGSize(width: 4, height: 4)))
        }
        ctx?.fillEllipse(in: CGRect(mid: p, size: CGSize(width: 4, height: 4)))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    
    fileprivate func getSide(point: CGPoint, line: (CGPoint, CGPoint)) -> Int {
        // 𝑑=(𝑥−𝑥1)(𝑦2−𝑦1)−(𝑦−𝑦1)(𝑥2−𝑥1)
        let d = (point.x - line.0.x) * (line.1.y - line.0.y) -
                (point.y - line.0.y) * (line.1.x - line.0.x);
        if d > 0 {
            return 1
        } else if d < 0 {
            return -1
        } else {
            return 0
        }
    }
    
    fileprivate func getQuadraticDerivative(points: [CGPoint], t: CGFloat) -> CGPoint {
        let mt = (1 - t)
        let d0 = CGPoint(x: 2 * (points[1].x - points[0].x), y: 2 * (points[1].y - points[0].y))
        let d1 = CGPoint(x: 2 * (points[2].x - points[1].x), y: 2 * (points[2].y - points[1].y))

        return CGPoint(x: mt * d0.x + t * d1.x,
                       y: mt * d0.y + t * d1.y)
    }
    
    fileprivate func optimizedManualBezier2(from: CGPoint, to: CGPoint, control: CGPoint, fromWidth: CGFloat, toWidth: CGFloat, inOutBezier: inout UIBezierPath) -> [CGPoint] {
        // generate points if we have curve on line
        
        let calcPoint: (CGFloat)->(CGPoint) = { (t: CGFloat) -> CGPoint in
            let t1 = pow(1 - t, 2)
            let t2 = 2.0 * (1 - t) * t
            let t3 = pow(t, 2)
            let p = from.mulitply(t1).add(control.mulitply(t2)).add(to.mulitply(t3))
            return p
        }
        let calcWidth: (CGFloat)->(CGFloat) = { fromWidth * (1-$0) + toWidth * $0 }
        let maxPixErr: CGFloat = 0.6
        let maxPixErrSqr = pow(maxPixErr, 2)
        let cosValThresh: CGFloat = 0.7
        
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
        
        var pointsOut: [CGPoint] = []
        pointsOut.reserveCapacity(pointsT.count)
        for i in 0..<pointsT.count {
            let t = pointsT[i].t
            let width = fromWidth * (1-t) + toWidth * t
            let p = pointsT[i].p.add(normals[i].mulitply(width))
            pointsOut.append(p)
            if inOutBezier.isEmpty {
                inOutBezier.move(to: p)
            } else {
                inOutBezier.addLine(to: p)
            }
        }
        return pointsOut
    }
}
