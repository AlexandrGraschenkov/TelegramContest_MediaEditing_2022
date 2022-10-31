//
//  MarkerDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 27.10.2022.
//

import UIKit


class MarkerDrawer: ToolDrawer {
    override var toolType: ToolType { .marker }
    
    fileprivate var parentLayer: CAReplicatorLayer?
    fileprivate var suggestLayer: CAShapeLayer?
    fileprivate var suggestParentLayer: CAReplicatorLayer?
//    fileprivate var bendStrokeLayer: CAShapeLayer?
//    fileprivate var bendStrokePath: UIBezierPath?
//    fileprivate var bendTranslate: CGPoint = .zero
//    fileprivate var bendPointsSet = Set<CGPoint>()
    
    
    override func generateLayer(path: UIBezierPath?, overrideColor: UIColor? = nil, overrideFinalSize: CGFloat? = nil) -> CALayer {
        let size = overrideFinalSize ?? toolSize * 2 * contentScale
        let color = overrideColor ?? self.color
        let comp = color.components
        
        let repCount: Int = 3
        
        let layer = CAShapeLayer()
        layer.strokeColor = comp.toColorOverride(a: 1).cgColor
        layer.lineWidth = size / CGFloat(repCount)
        layer.lineCap = .round
        layer.lineJoin = .round
        let t = CGPoint(x: cos(curveGen.marker.angle) * layer.lineWidth / 2,
                        y: sin(curveGen.marker.angle) * layer.lineWidth / 2)
        layer.transform = CATransform3DMakeTranslation(-t.x * CGFloat(repCount/2),
                                                       -t.y * CGFloat(repCount/2), 0)
        layer.fillColor = comp.toColorOverride(a: 0).cgColor
        layer.path = path?.cgPath
        
        let parent = CAReplicatorLayer()
        parent.opacity = Float(comp.a)
        parent.instanceTransform = CATransform3DMakeTranslation(t.x, t.y, 0)
        parent.instanceCount = repCount
        parent.addSublayer(layer)
        
//        bendTranslate = CGPoint(x: -t.x * CGFloat(repCount/2),
//                                y: -t.y * CGFloat(repCount/2))
        
        return parent
    }
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            parentLayer = (generateLayer(path: nil) as! CAReplicatorLayer)
            let shape = parentLayer!.sublayers!.first as! CAShapeLayer
            content?.layer.addSublayer(parentLayer!)
            splitOpt.start(layer: shape, penGen: curveGen)
        }
        CALayer.withoutAnimation {
            splitOpt.updatePath(points: drawPath)
        }
    }
    
    override func finishDraw(canceled: Bool) {
        if canceled {
            parentLayer?.removeFromSuperlayer()
        } else {
            splitOpt.finish()
            addToHistory()
        }
        parentLayer = nil
        suggestLayer = nil
        suggestParentLayer = nil
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
        
        let cgPath: CGPath
        let opacity: Float
        if let rep = suggestParentLayer {
            history.layerContainer?.layers[name] = rep
            cgPath = suggestLayer!.path!
            opacity = rep.opacity
            parentLayer.removeFromSuperlayer()
        } else {
            history.layerContainer?.layers[name] = parentLayer
            opacity = parentLayer.opacity
            let bezier = UIBezierPath()
            for b in splitOpt.bezierArr {
                bezier.append(b)
            }
            cgPath = bezier.cgPath
            suggestParentLayer?.removeFromSuperlayer()
        }
        
        let shape = parentLayer.sublayers!.first as! CAShapeLayer
        var shapeDict = shape.getKeys()
        shapeDict["path"] = cgPath
        
        let forward = History.Element(objectId: name, action: .add(classType: CAReplicatorLayer.self), updateKeys: parentLayer.getKeys(override: ["opacity": opacity])) { elem, container, obj in
            guard let container = container.layers[elem.objectId] else {
                return
            }
            
            let shape = CAShapeLayer()
            shape.apply(keys: shapeDict)
            container.addSublayer(shape)
        }
        
        let backward = History.Element(objectId: name, action: .remove)
        history.add(element: .init(forward: [forward], backward: [backward]))
    }
    
    override func onShapeSuggested(path: UIBezierPath?) {
        if path == nil && suggestLayer == nil { return }
        guard let parentLayer = parentLayer else { return }
        if suggestLayer == nil {
            let origShape = parentLayer.sublayers?.first as? CAShapeLayer
            suggestLayer = origShape?.customCopy()
            
            let rep = CAReplicatorLayer()
            rep.instanceTransform = parentLayer.instanceTransform
            rep.instanceCount = parentLayer.instanceCount
            rep.addSublayer(suggestLayer!)
            parentLayer.superlayer?.addSublayer(rep)
            suggestParentLayer = rep
            
            suggestLayer?.opacity = 1
            parentLayer.opacity = 0
        }
        if let path = path {
            suggestLayer?.path = path.cgPath
        } else if let layer = suggestLayer {
            suggestLayer = nil
            suggestParentLayer = nil
            let rep = suggestParentLayer
            
            layer.opacity = 0
            parentLayer.opacity = Float(color.components.a)
            delay(0.3) {
                layer.removeFromSuperlayer();
                rep?.removeFromSuperlayer()
            }
        }
    }
}
