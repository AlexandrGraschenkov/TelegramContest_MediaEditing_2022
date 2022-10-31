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
    fileprivate var suggestLayer: CAShapeLayer?
    fileprivate var suggestParentLayer: CALayer?
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            parentLayer = generateLayer(path: nil)
            let layer = parentLayer!.sublayers!.first as! CAShapeLayer
            
            content?.layer.addSublayer(parentLayer!)
            
//            parentWithOpacity.addSublayer(rep)
            splitOpt.start(layer: layer, penGen: curveGen)
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
        suggestParentLayer = nil
        suggestLayer = nil
        parentLayer = nil
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
        if let suggestParent = suggestParentLayer {
            history.layerContainer?.layers[name] = suggestParent
            cgPath = suggestLayer!.path!
            opacity = suggestParent.opacity
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
        
        let forward = History.Element(objectId: name, action: .add(classType: CALayer.self), updateKeys: parentLayer.getKeys(override: ["opacity": opacity])) { elem, container, obj in
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
    
    override func generateLayer(path: UIBezierPath?, overrideColor: UIColor? = nil, overrideFinalSize: CGFloat? = nil) -> CALayer {
        let size = overrideFinalSize ?? toolSize * 2 * contentScale
        let color = overrideColor ?? self.color
        let comp = color.components
        
        let parent = CALayer()
        parent.opacity = Float(comp.a)
        parent.shadowColor = comp.toColorOverride(a: 1).cgColor
        parent.shadowRadius = size
        parent.shadowOpacity = 1
        parent.shadowOffset = .zero
        
        let layer = CAShapeLayer()
        layer.strokeColor = comp.toColorOverride(a: 1).cgColor
        layer.lineWidth = size
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.shadowColor = parent.shadowColor
        layer.shadowRadius = size / 2
        layer.shadowOpacity = parent.shadowOpacity
        layer.shadowOffset = parent.shadowOffset
        layer.fillColor = comp.toColorOverride(a: 0).cgColor
        layer.path = path?.cgPath
        
        parent.addSublayer(layer)
        
        return parent
    }
    
    override func onShapeSuggested(path: UIBezierPath?) {
        if path == nil && suggestLayer == nil { return }
        guard let parentLayer = parentLayer else { return }
        if suggestLayer == nil {
            suggestParentLayer = generateLayer(path: nil)
            suggestLayer = suggestParentLayer?.sublayers?.first as? CAShapeLayer
            suggestLayer?.opacity = 0
            
            parentLayer.superlayer?.addSublayer(suggestParentLayer!)
            
            suggestLayer?.opacity = 1
            parentLayer.opacity = 0
        }
        if let path = path {
            suggestLayer?.path = path.cgPath
        } else if let layer = suggestLayer {
            suggestLayer = nil
            suggestParentLayer = nil
            let suggestParent = suggestParentLayer
            
            layer.opacity = 0
            parentLayer.opacity = Float(color.components.a)
            delay(0.3) {
                layer.removeFromSuperlayer();
                suggestParent?.removeFromSuperlayer()
            }
        }
    }
}
