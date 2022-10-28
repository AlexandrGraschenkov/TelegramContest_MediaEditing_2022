//
//  PenDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 14.10.2022.
//

import UIKit

class PenDrawer: ToolDrawer {
    fileprivate var parentLayer: CAShapeLayer?
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            let comp = color.components
            let parentWithOpacity = CAShapeLayer()
            parentWithOpacity.opacity = Float(comp.a)
            content?.layer.addSublayer(parentWithOpacity)
            parentLayer = parentWithOpacity
            
            let layer = CAShapeLayer()
            layer.strokeColor = nil
            layer.fillColor = comp.toColorOverride(a: 1).cgColor
            parentWithOpacity.addSublayer(layer)
            splitOpt.start(layer: layer, penGen: curveGen)
            
//            currentDrawDebugLayer = CAShapeLayer()
//            currentDrawDebugLayer?.strokeColor = UIColor.red.cgColor
//            currentDrawDebugLayer?.lineWidth = scale
//            currentDrawDebugLayer?.fillColor = nil
//            content?.layer.addSublayer(currentDrawDebugLayer!)
        }
        
        CALayer.withoutAnimation {
            splitOpt.updatePath(points: drawPath)
        }
//        let bezier = penGen.generatePolygon(type: .standart, points: drawPath)
//        currentDrawLayer?.path = bezier.cgPath
//        var debugPath = penGen.generateStrokePolygon(type: .standart, points: drawPath)
//        if drawPath.count > 1 {
//            debugPath.move(to: drawPath[0].point)
//            for point in drawPath {
//                debugPath.addLine(to: point.point)
//            }
//        }
//        currentDrawDebugLayer?.path = debugPath.cgPath
    }
    
    override func finishDraw(canceled: Bool) {
        if canceled {
            parentLayer?.removeFromSuperlayer()
        } else {
            let suffCount = drawPath.count - splitOpt.frozenCount
            // generate last layer without plume
            splitOpt.finish(updateLayer: false, points: drawPath)
            addToHistory()
            
            // run pretty animation with plume shrinks
            curveGen.finishPlumAnimation(points: drawPath.suffix(suffCount), onLayer: splitOpt.shapeArr.last!, duration: 0.24)
        }
        parentLayer = nil
//        currentDrawDebugLayer = nil
    }
    
    fileprivate func addToHistory() {
        guard let history = history,
              let parentLayer = parentLayer,
              let layers = history.layerContainer else {
            assert(false, "Something missing")
            return
        }

        // WARNING: For optimization purpose we have layer with multiple sublayers; Possible some bugs in future;
        let name = layers.generateUniqueName(prefix: toolType.rawValue)
        history.layerContainer?.layers[name] = parentLayer
        let bezier = UIBezierPath()
        for b in splitOpt.bezierArr {
            bezier.append(b)
        }
        let forward = History.Element(objectId: name, action: .add(classType: CAShapeLayer.self), updateKeys: ["path": bezier.cgPath, "fillColor": color.cgColor])
        let backward = History.Element(objectId: name, action: .remove)
        history.add(element: .init(forward: [forward], backward: [backward]))
    }
}

