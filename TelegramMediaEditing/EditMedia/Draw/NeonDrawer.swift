//
//  NeonDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 28.10.2022.
//

import UIKit

class NeonDrawer: ToolDrawer {
    override var toolType: ToolType { .neon }
    
    fileprivate var parentLayer: CALayer?
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            let size = toolSize * 2 * scale
            
            let comp = color.components
            let parentWithOpacity = CALayer()
            parentWithOpacity.opacity = Float(comp.a)
            parentWithOpacity.shadowColor = comp.toColorOverride(a: 1).cgColor
            parentWithOpacity.shadowRadius = size
            parentWithOpacity.shadowOpacity = 0.8
            content?.layer.addSublayer(parentWithOpacity)
            parentLayer = parentWithOpacity
            
            
            let layer = CAShapeLayer()
            layer.strokeColor = comp.toColorOverride(a: 1).cgColor
            layer.lineWidth = size
            layer.lineCap = .round
            layer.lineJoin = .round
//            print("Tool size", toolSize * scale / 2)
            layer.fillColor = nil //comp.toColorOverride(a: 1).cgColor
            
            
//            bendPointsSet.removeAll()
//            bendStrokePath = UIBezierPath()
//            bendStrokeLayer = CAShapeLayer()
//            bendStrokeLayer!.strokeColor = layer.strokeColor
//            bendStrokeLayer!.lineWidth = layer.lineWidth
//            bendStrokeLayer!.lineCap = layer.lineCap
//            bendStrokeLayer!.lineJoin = layer.lineJoin
//            parentWithOpacity.addSublayer(bendStrokeLayer!)
            
//            let rep = CAReplicatorLayer()
            parentWithOpacity.addSublayer(layer)
            
//            parentWithOpacity.addSublayer(rep)
            splitOpt.start(layer: layer, penGen: curveGen)
        }
        CALayer.withoutAnimation {
            splitOpt.updatePath(points: drawPath)
        }
//        drawLinesOnBend()
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
            splitOpt.finish()
            addToHistory()
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
        let name = layers.generateUniqueName(prefix: "pen")
        history.layerContainer?.layers[name] = parentLayer
        let bezier = UIBezierPath()
        for b in splitOpt.bezierArr {
            bezier.append(b)
        }
        let lineWidth = (parentLayer.sublayers?.first as? CAShapeLayer)?.lineWidth ?? toolSize
        
        let forward = History.Element(objectId: name, action: .add(classType: CAShapeLayer.self), updateKeys: [
            "opacity": parentLayer.opacity,
            "path": bezier.cgPath,
            "strokeColor": color.withAlphaComponent(1).cgColor,
            "lineJoin": CAShapeLayerLineJoin.round,
            "lineCap": CAShapeLayerLineCap.round,
            "lineWidth": lineWidth,
            "shadowOpacity": parentLayer.shadowOpacity,
            "shadowColor": parentLayer.shadowColor ?? color.withAlphaComponent(1).cgColor,
            "shadowRadius": parentLayer.shadowRadius,
            "fillColor": UIColor.clear.cgColor
        ])
        
        let backward = History.Element(objectId: name, action: .remove)
        history.add(element: .init(forward: [forward], backward: [backward]))
    }
    
//    func drawLinesOnBend() {
//        for p in curveGen.markerBendPoints {
//            if bendPointsSet.contains(p) { continue }
//            bendPointsSet.insert(p)
//            bendStrokePath?.move(to: p.add(bendTranslate))
//            bendStrokePath?.addLine(to: p.substract(bendTranslate))
//            bendStrokeLayer?.path = bendStrokePath?.cgPath
//        }
//    }
}
