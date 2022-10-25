//
//  PenSplitOptimizer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 20.10.2022.
//

import UIKit

/// Если пользователь будет водить продолжительное время кисточкой, обновление CAShapeLayer начинает занимать слишком много, поэтому бъем на кусочки
class PenSplitOptimizer: NSObject {
    fileprivate(set) var bezierArr: [UIBezierPath] = []
    fileprivate(set) var shapeArr: [CAShapeLayer] = []
    fileprivate(set) var penGen: PenCurveGenerator!
    fileprivate(set) var frozenCount: Int = 0
    let splitThreshCount = 150
    let splitCount = 100
    fileprivate(set) var isPrepared: Bool = false
    
    func start(layer: CAShapeLayer, penGen: PenCurveGenerator) {
        isPrepared = true
        shapeArr = [layer]
        bezierArr = [UIBezierPath()]
        self.penGen = penGen
        frozenCount = 0
    }
    
    func finish(updateLayer: Bool, points: [PanPoint]) {
        isPrepared = false
        let suffixCount = points.count - frozenCount
        let poly = penGen.generatePolygon(points: points.suffix(suffixCount), withPlume: false)
        bezierArr[bezierArr.count-1] = poly
        if updateLayer {
            CALayer.withoutAnimation {
                shapeArr.last!.path = poly.cgPath
            }
        }
    }
    
    func updatePath(points: [PanPoint]) {
        if points.count - frozenCount > splitThreshCount {
            let poly = penGen.generatePolygon(points: Array<PanPoint>(points[frozenCount..<frozenCount+splitCount+1]), withPlume: false)
            CALayer.withoutAnimation {
                shapeArr.last!.path = poly.cgPath
            }
            let newShape = shapeArr.last!.customCopy()
            shapeArr.last!.superlayer?.insertSublayer(newShape, above: shapeArr.last!)
//            shapeArr.last!.strokeColor = UIColor.red.cgColor
//            shapeArr.last!.lineWidth = 2
            
            frozenCount += splitCount
            shapeArr.append(newShape)
            bezierArr.append(UIBezierPath())
        }
        let suffixCount = points.count - frozenCount
        let poly = penGen.generatePolygon(points: points.suffix(suffixCount))
        bezierArr[bezierArr.count-1] = poly
        CALayer.withoutAnimation {
            shapeArr.last!.path = poly.cgPath
        }
    }
}

fileprivate extension CAShapeLayer {
    func customCopy() -> CAShapeLayer {
        let res = CAShapeLayer()
        res.fillColor = fillColor
        res.strokeColor = strokeColor
        res.lineWidth = lineWidth
        res.lineCap = .round
        res.lineJoin = .round
        return res
    }
}
