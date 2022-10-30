//
//  PencilDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 28.10.2022.
//

import UIKit

class PencilDrawer: ToolDrawer {
    override init() {
        super.init()
        smooth.smoothMultiplier = 0.5
    }
    
    override var toolType: ToolType { .pencil }
    
    fileprivate var parentLayer: CAShapeLayer?
    fileprivate lazy var patternImage = UIImage(named: "pencil_texture")!
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            let size = toolSize * 2 * scale
            
            let comp = color.components
            let parentWithOpacity = CAShapeLayer()
            parentWithOpacity.opacity = Float(comp.a)
            
            let img = patternImage.imageWithColor(color1: comp.toColorOverride(a: 1))
            parentWithOpacity.fillColor = UIColor(patternImage: img).cgColor
            parentWithOpacity.path = CGPath(rect: content!.bounds, transform: nil)
            content?.layer.addSublayer(parentWithOpacity)
            parentLayer = parentWithOpacity
            
            
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.white.cgColor // Use like a mask
            layer.lineWidth = size
            layer.lineCap = .round
            layer.lineJoin = .round
//            print("Tool size", toolSize * scale / 2)
            layer.fillColor = nil //comp.toColorOverride(a: 1).cgColor
            
            
            let mask = CALayer()
            mask.addSublayer(layer)
            parentWithOpacity.mask = mask
            
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
        let name = layers.generateUniqueName(prefix: toolType.rawValue)
        history.layerContainer?.layers[name] = parentLayer
        let bezier = UIBezierPath()
        for b in splitOpt.bezierArr {
            bezier.append(b)
        }
        let cgPath = bezier.cgPath
        let lineWidth = (parentLayer.mask?.sublayers?.first as? CAShapeLayer)?.lineWidth ?? toolSize
        let drawBbox = getOptimalBbox(bounds: content!.bounds, patternSize: patternImage.size, path: cgPath, lineWidth: lineWidth)
        parentLayer.path = CGPath(rect: drawBbox, transform: nil)
        
        let shapeDict: [String: Any] = [
            "path": cgPath,
            "strokeColor": UIColor.white.cgColor,
            "lineJoin": CAShapeLayerLineJoin.round,
            "lineCap": CAShapeLayerLineCap.round,
            "lineWidth": lineWidth,
            "fillColor": UIColor.clear.cgColor
        ]
        
        let forward = History.Element(objectId: name, action: .add(classType: CAShapeLayer.self), updateKeys: [
            "path": parentLayer.path!,
            "fillColor": parentLayer.fillColor!
        ]) { elem, container, obj in
            guard let container = container.layers[elem.objectId] else {
                return
            }
            
            let shape = CAShapeLayer()
            for (k, v) in shapeDict {
                shape.setValue(v, forKeyPath: k)
            }
            container.mask = shape
        }
        
        let backward = History.Element(objectId: name, action: .remove)
        history.add(element: .init(forward: [forward], backward: [backward]))
    }
    
    fileprivate func getOptimalBbox(bounds: CGRect, patternSize: CGSize, path: CGPath, lineWidth: CGFloat) -> CGRect {
        var bbox = path.boundingBoxOfPath
        bbox = bbox.insetBy(dx: -lineWidth*2-1, dy: -lineWidth*2-1).integral
        var tl = CGPoint(x: bbox.minX, y: bbox.minY)
//        tl.x = floor(tl.x / patternSize.width) * patternSize.width
//        tl.y = floor(tl.y / patternSize.height) * patternSize.height
        
        var br = CGPoint(x: bbox.maxX, y: bbox.maxY)
//        br.x = ceil(br.x / patternSize.width) * patternSize.width
//        br.y = ceil(br.y / patternSize.height) * patternSize.height
        
        tl.x = max(tl.x, bounds.minX)
        tl.y = max(tl.y, bounds.minY)
        br.x = min(br.x, bounds.maxX)
        br.y = min(br.y, bounds.maxY)
        
        return CGRect(origin: tl, size: br.subtract(tl).size)
    }
    
}
