//
//  ToolDrawSplitOptimizer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 20.10.2022.
//

import UIKit

/// Если пользователь будет водить продолжительное время кисточкой, обновление CAShapeLayer начинает занимать слишком много, поэтому бъем на кусочки
class ToolDrawSplitOptimizer: NSObject {
    fileprivate(set) var bezierArr: [UIBezierPath] = []
    fileprivate(set) var shapeArr: [CAShapeLayer] = []
    fileprivate(set) var penGen: ToolCurveGenerator!
    fileprivate(set) var frozenCount: Int = 0
    let splitThreshCount = 110
    let splitCount = 80
    fileprivate(set) var isPrepared: Bool = false
    var resultBezier: UIBezierPath {
        let bezier = UIBezierPath()
        for b in bezierArr {
            bezier.append(b)
        }
        return bezier
    }
    
    func start(layer: CAShapeLayer, penGen: ToolCurveGenerator) {
        isPrepared = true
        shapeArr = [layer]
        bezierArr = [UIBezierPath()]
        self.penGen = penGen
        frozenCount = 0
        penGen.overrideStartSmoothSpeeds = []
    }
    
    func finish() {
        isPrepared = false
    }
    
    func finish(updateLayer: Bool, points: [PanPoint]) {
        isPrepared = false
        let suffixCount = points.count - frozenCount
        let poly = penGen.generatePolygon(points: points.suffix(suffixCount), withPlume: false)
        bezierArr[bezierArr.count-1] = poly
        if updateLayer {
            shapeArr.last!.path = poly.cgPath
        }
    }
    
    func updatePath(points: [PanPoint]) {
        if points.count - frozenCount > splitThreshCount {
            penGen.overrideStartSmoothSpeeds = penGen.lastProcessedSpeeds
            let poly = penGen.generatePolygon(points: Array<PanPoint>(points[frozenCount..<frozenCount+splitCount+1]), withPlume: false)
            shapeArr.last!.path = poly.cgPath
            let newShape = shapeArr.last!.customCopy()
            shapeArr.last!.superlayer?.insertSublayer(newShape, above: shapeArr.last!)
//            shapeArr.last!.strokeColor = UIColor.red.cgColor
//            shapeArr.last!.lineWidth = 2
            
            penGen.overrideStartSmoothSpeeds = Array(penGen.overrideStartSmoothSpeeds[splitCount..<splitCount+10])
            frozenCount += splitCount
            shapeArr.append(newShape)
            bezierArr.append(UIBezierPath())
        }
        let suffixCount = points.count - frozenCount
        let poly = penGen.generatePolygon(points: points.suffix(suffixCount))
        bezierArr[bezierArr.count-1] = poly
        shapeArr.last!.path = poly.cgPath
    }
}
