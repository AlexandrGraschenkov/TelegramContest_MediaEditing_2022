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
            parentWithOpacity.shadowOpacity = 1
            parentWithOpacity.shadowOffset = .zero
            content?.layer.addSublayer(parentWithOpacity)
            parentLayer = parentWithOpacity
            
            
            let layer = CAShapeLayer()
            layer.strokeColor = comp.toColorOverride(a: 1).cgColor
            layer.lineWidth = size
            layer.lineCap = .round
            layer.lineJoin = .round
            layer.shadowColor = parentWithOpacity.shadowColor
            layer.shadowRadius = size / 2
            layer.shadowOpacity = parentWithOpacity.shadowOpacity
            layer.shadowOffset = parentWithOpacity.shadowOffset
            layer.fillColor = nil //comp.toColorOverride(a: 1).cgColor
            
            parentWithOpacity.addSublayer(layer)
            
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
        let name = layers.generateUniqueName(prefix: "pen")
        history.layerContainer?.layers[name] = parentLayer
        let bezier = UIBezierPath()
        for b in splitOpt.bezierArr {
            bezier.append(b)
        }
        let lineWidth = (parentLayer.sublayers?.first as? CAShapeLayer)?.lineWidth ?? toolSize
        
        let shapeDict: [String: Any] = [
            "path": bezier.cgPath,
            "strokeColor": color.withAlphaComponent(1).cgColor,
            "lineJoin": CAShapeLayerLineJoin.round,
            "lineCap": CAShapeLayerLineCap.round,
            "lineWidth": lineWidth,
            "shadowOpacity": parentLayer.shadowOpacity,
            "shadowColor": parentLayer.shadowColor ?? color.withAlphaComponent(1).cgColor,
            "shadowRadius": parentLayer.shadowRadius,
            "shadowOffset": parentLayer.shadowOffset,
            "fillColor": UIColor.clear.cgColor
        ]
        
        let forward = History.Element(objectId: name, action: .add(classType: CAShapeLayer.self), updateKeys: [
            "shadowOpacity": parentLayer.shadowOpacity,
            "shadowColor": parentLayer.shadowColor ?? color.withAlphaComponent(1).cgColor,
            "shadowRadius": parentLayer.shadowRadius,
            "shadowOffset": parentLayer.shadowOffset,
        ]) { elem, container in
            guard let container = container.layers[elem.objectId] else {
                return
            }
            
            let shape = CAShapeLayer()
            for (k, v) in shapeDict {
                shape.setValue(v, forKeyPath: k)
            }
            container.addSublayer(shape)
        }
        
        let backward = History.Element(objectId: name, action: .remove)
        history.add(element: .init(forward: [forward], backward: [backward]))
    }
}
