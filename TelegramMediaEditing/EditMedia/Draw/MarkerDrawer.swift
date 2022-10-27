//
//  MarkerDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 27.10.2022.
//

import UIKit

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

class MarkerDrawer: ToolDrawer {
    override init() {
        super.init()
        
        curveGen.mode = .marker
    }
    
    fileprivate var parentLayer: CAReplicatorLayer?
    fileprivate var bendStrokeLayer: CAShapeLayer?
    fileprivate var bendStrokePath: UIBezierPath?
    fileprivate var bendTranslate: CGPoint = .zero
    fileprivate var bendPointsSet = Set<CGPoint>()
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            let comp = color.components
            let parentWithOpacity = CAReplicatorLayer()
            parentWithOpacity.opacity = Float(comp.a)
            content?.layer.addSublayer(parentWithOpacity)
            parentLayer = parentWithOpacity
            
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            
            // little bit of cheating with CAReplicatorLayer
            let repCount: Int = 3
            let layer = CAShapeLayer()
            layer.strokeColor = comp.toColorOverride(a: 1).cgColor
            layer.lineWidth = toolSize * scale / CGFloat(repCount)
            layer.lineCap = .round
            layer.lineJoin = .round
//            print("Tool size", toolSize * scale / 2)
            layer.fillColor = nil //comp.toColorOverride(a: 1).cgColor
            
            let t = CGPoint(x: cos(curveGen.marker.angle) * layer.lineWidth / 2,
                            y: sin(curveGen.marker.angle) * layer.lineWidth / 2)
            bendTranslate = CGPoint(x: -t.x * CGFloat(repCount/2),
                                    y: -t.y * CGFloat(repCount/2))
            layer.transform = CATransform3DMakeTranslation(-t.x * CGFloat(repCount/2),
                                                           -t.y * CGFloat(repCount/2), 0)
            
//            bendPointsSet.removeAll()
//            bendStrokePath = UIBezierPath()
//            bendStrokeLayer = CAShapeLayer()
//            bendStrokeLayer!.strokeColor = layer.strokeColor
//            bendStrokeLayer!.lineWidth = layer.lineWidth
//            bendStrokeLayer!.lineCap = layer.lineCap
//            bendStrokeLayer!.lineJoin = layer.lineJoin
//            parentWithOpacity.addSublayer(bendStrokeLayer!)
            
//            let rep = CAReplicatorLayer()
            parentWithOpacity.instanceTransform = CATransform3DMakeTranslation(t.x, t.y, 0)
            parentWithOpacity.instanceCount = repCount
            parentWithOpacity.addSublayer(layer)
            
//            parentWithOpacity.addSublayer(rep)
            splitOpt.start(layer: layer, penGen: curveGen)
        }
        splitOpt.updatePath(points: drawPath)
        drawLinesOnBend()
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
        var shapeDict: [String: Any] = [:]
        if let l = parentLayer.sublayers?.first as? CAShapeLayer {
            shapeDict["lineWidth"] = l.lineWidth
            shapeDict["transform"] = l.transform
            shapeDict["lineJoin"] = l.lineJoin
            shapeDict["lineCap"] = l.lineCap
            shapeDict["strokeColor"] = l.strokeColor
        }
        
        let forward = History.Element(objectId: name, action: .add(classType: CAReplicatorLayer.self), updateKeys: ["instanceCount": parentLayer.instanceCount, "instanceTransform": parentLayer.instanceTransform, "opacity": parentLayer.opacity]) { elem, container in
            guard let rep = container.layers[elem.objectId] else {
                return
            }
            
            let shape = CAShapeLayer()
            shape.path = bezier.cgPath
            shape.fillColor = nil
            for (k, v) in shapeDict {
                shape.setValue(v, forKeyPath: k)
            }
            rep.addSublayer(shape)
        }
        
        let backward = History.Element(objectId: name, action: .remove)
        history.add(element: .init(forward: [forward], backward: [backward]))
    }
    
    func drawLinesOnBend() {
        for p in curveGen.markerBendPoints {
            if bendPointsSet.contains(p) { continue }
            bendPointsSet.insert(p)
            bendStrokePath?.move(to: p.add(bendTranslate))
            bendStrokePath?.addLine(to: p.substract(bendTranslate))
            bendStrokeLayer?.path = bendStrokePath?.cgPath
        }
    }
}
