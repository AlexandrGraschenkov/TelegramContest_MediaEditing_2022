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
    
    fileprivate var parentLayer: CALayer?
    fileprivate var bendStrokeLayer: CAShapeLayer?
    fileprivate var bendStrokePath: UIBezierPath?
    fileprivate var bendTranslate: CGPoint = .zero
    fileprivate var bendPointsSet = Set<CGPoint>()
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            let comp = color.components
            let parentWithOpacity = CALayer()
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
            
            let rep = CAReplicatorLayer()
            rep.instanceTransform = CATransform3DMakeTranslation(t.x, t.y, 0)
            rep.instanceCount = repCount
            rep.addSublayer(layer)
            
            parentWithOpacity.addSublayer(rep)
            splitOpt.start(layer: layer, penGen: curveGen)
            
//            currentDrawDebugLayer = CAShapeLayer()
//            currentDrawDebugLayer?.strokeColor = UIColor.red.cgColor
//            currentDrawDebugLayer?.lineWidth = scale
//            currentDrawDebugLayer?.fillColor = nil
//            content?.layer.addSublayer(currentDrawDebugLayer!)
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
        let forward = History.Element(objectId: name, action: .add(classType: CAShapeLayer.self), updateKeys: ["path": bezier.cgPath, "fillColor": color.cgColor, "lineWidth": 2, "strokeColor": color.cgColor])
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
