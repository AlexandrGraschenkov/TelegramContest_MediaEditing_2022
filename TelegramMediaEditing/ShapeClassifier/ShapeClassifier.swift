//
//  ShapeClassifier.swift
//  BezierHitTest
//
//  Created by Alexander Graschenkov on 31.10.2022.
//

import UIKit
import CoreML

final class ShapeClassifier {
    
    enum Shape {
        case ellipse(center: CGPoint, size: CGSize)
        case rectangle(center: CGPoint, size: CGSize)
        case rhombus(center: CGPoint, size: CGFloat)
        case star(center: CGPoint, size: CGFloat)
        case triangle(center: CGPoint, size: CGFloat)
        case arrow(from: CGPoint, to: CGPoint)
    }
    
    static let shared = ShapeClassifier()
    
    func detect(points: [CGPoint], scale: CGFloat) -> Shape? {
        let bounds = getBounds(points: points)
        let avgSize = (bounds.width + bounds.height) / 2.0
        let sizeRatio = min(bounds.width, bounds.height) / max(bounds.width, bounds.height)
        
        let shapeInfo = getShapeInfo(points: points)
        if shapeInfo.circularity > 0.94 {
            // pretty easy to determine circle without neural net
            return .ellipse(center: bounds.mid, size: CGSize(width: avgSize, height: avgSize))
        }
        
        if let arrow = ArrowClassifier.detectArrow(points: points) {
            return .arrow(from: arrow.from, to: arrow.to)
        }
        
        // Otherwise process with neural net
        if #available(iOS 13.0, *) {
            let fitPoints = fitPointsIn(bounds: CGRect(x: 5, y: 5, width: 18, height: 18), points: points)
            drawContext(points: fitPoints, lineWidth: 2)
            
            //        let t1 = CACurrentMediaTime()
            guard let img = context.makeImage(),
                  let res = try? net.prediction(input: DrawnImageClassifier_8Input(imageWith: img)) else {
                return nil
            }
            
            //        let t2 = CACurrentMediaTime()
            
            print("NN pred: \(res.category); conv: \(shapeInfo.convexity); circ: \(shapeInfo.circularity)")
            let isConvex = shapeInfo.convexity > 0.8
            switch res.category {
            case "star", "mosquito":
                return .star(center: bounds.mid, size: avgSize)
            case "picture frame", "pillow", "square", "sandwich":
                if !isConvex { break }
                let size = sizeRatio > 0.8 ? CGSize(width: avgSize, height: avgSize) : bounds.size
                return .rectangle(center: bounds.mid, size: size)
            case "diamond":
                if !isConvex { break }
                let size = avgSize / sqrt(2)
                return .rhombus(center: bounds.mid, size: size)
            case "bracelet", "circle":
                if !isConvex { break }
                let size = sizeRatio > 0.8 ? CGSize(width: avgSize, height: avgSize) : bounds.size
                return .ellipse(center: bounds.mid, size: size)
            case "triangle":
                if !isConvex { break }
                return .triangle(center: bounds.mid, size: avgSize)
            default:
                break
            }
        }
//        return res1.category + " \(t2-t1)"
        return nil
    }

    // MARK: - fileprivate
    @available(iOS 13.0, *)
    private var net: DrawnImageClassifier_8 {
        if net_ == nil {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            net_ = try! DrawnImageClassifier_8(configuration: config)
        }
        return net_ as! DrawnImageClassifier_8
    }
    private var net_: Any?
    private lazy var context: CGContext = {
        let size = CGSize(width: 28, height: 28)
        let bytesPerRow = Int(size.width)
        let alignedBytesPerRow = ((bytesPerRow + (64 - 1)) / 64) * 64
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: alignedBytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        return context
    }()
    
    fileprivate func getBounds(points: [CGPoint]) -> CGRect {
        if points.isEmpty { return .zero }
        var minP = points[0]
        var maxP = points[0]
        for p in points {
            minP.x = min(minP.x, p.x)
            minP.y = min(minP.y, p.y)
            maxP.x = max(maxP.x, p.x)
            maxP.y = max(maxP.y, p.y)
        }
        return CGRect(origin: minP, size: CGSize(width: maxP.x-minP.x, height: maxP.y-minP.y))
    }
    
    fileprivate func fitPointsIn(bounds: CGRect, points: [CGPoint], saveProportions: Bool = false) -> [CGPoint] {
        var minP = points[0]
        var maxP = points[0]
        for p in points {
            minP.x = min(minP.x, p.x)
            minP.y = min(minP.y, p.y)
            maxP.x = max(maxP.x, p.x)
            maxP.y = max(maxP.y, p.y)
        }
        var pointsSize = CGSize(width: maxP.x - minP.x,
                                height: maxP.y - minP.y)
        
        if saveProportions {
            let maxSize = max(pointsSize.width, pointsSize.height)
            pointsSize = CGSize(width: maxSize, height: maxSize)
            let mid = minP.add(maxP).multiply(0.5)
            minP = CGPoint(x: mid.x - maxSize/2, y: mid.y - maxSize/2)
        }
        
        let newPoints = points.map { (p) -> CGPoint in
            let x = (p.x - minP.x) * bounds.width / pointsSize.width + bounds.minX
            let y = (p.y - minP.y) * bounds.height / pointsSize.height + bounds.minY
            return CGPoint(x: x, y: y)
        }
        return newPoints
    }
    
    fileprivate func drawContext(points: [CGPoint], lineWidth: CGFloat = 2) {
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: CGSize(width: context.width, height: context.height)))
        context.setFillColor(UIColor.clear.cgColor)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(lineWidth)
        
        for (i, p) in  points.enumerated() {
            if i == 0 {
                context.move(to: p)
            } else {
                context.addLine(to: p)
            }
        }
        context.strokePath()
    }
    
    
    fileprivate struct ShapeInfo {
        let moments: Moments
        let circularity: CGFloat
        let convexity: CGFloat
    }
    
    fileprivate func getShapeInfo(points: [CGPoint]) -> ShapeInfo {
        let m = Moments.calculate(points: points)
        let hull = ConvexHull.process(points: points)
        let mHull = Moments.calculate(points: hull)
        
        let convexity: CGFloat
        if mHull.m00 > .ulpOfOne {
            convexity = m.m00 / mHull.m00 // area / hullArea
        } else {
            convexity = 0
        }
        
        let perimeter = calculatePerimetr(points: points)
        let circularity: CGFloat = 4 * .pi * m.m00 / (perimeter * perimeter)
        // probably we can use more properties of moments
        
        return ShapeInfo(moments: m, circularity: circularity, convexity: convexity)
    }
    
    fileprivate func calculatePerimetr(points: [CGPoint]) -> CGFloat {
        var perimeter: CGFloat = 0
        for i in 0..<points.count {
            let i2 = (i + 1) % points.count
            perimeter += points[i].distance(p: points[i2])
        }
        return perimeter
    }
}



