//
//  EraserDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 28.10.2022.
//

import UIKit

class EraserDrawer: ToolDrawer {
    override init() {
        super.init()
        smooth.smoothMultiplier = 0.001
        toolShape = .eraserObject
    }
    
    override var toolType: ToolType { .eraser }
    
    fileprivate var parentLayer: CAShapeLayer?
    fileprivate var blurredSnapshot: UIImage?
    override var active: Bool {
        didSet {
            if !active {
                blurredSnapshot = nil
            } else {
                if toolShape == .eraserBlur {
                    prepareBlurredSnapshot()
                }
            }
        }
    }
    override var toolShape: ToolShape {
        didSet {
            if toolShape == .eraserBlur {
                prepareBlurredSnapshot()
            } else {
                blurredSnapshot = nil
            }
        }
    }
    
    override func updateDrawLayer() {
        if !splitOpt.isPrepared {
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            let size = toolSize * 2 * scale
            
            // cheating with overlay
            parentLayer = CAShapeLayer()
            parentLayer?.frame = content!.bounds
//            let imgView = content as? UIImageView
//            print(content)
            if toolShape == .eraserBlur {
                parentLayer?.contents = self.blurredSnapshot?.cgImage
            } else {
                parentLayer?.contents = (content as? UIImageView)?.image?.cgImage
            }
            content?.layer.addSublayer(parentLayer!)
            
            
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.white.cgColor // Use like a mask
            layer.lineWidth = size
            layer.lineCap = .round
            layer.lineJoin = .round
//            print("Tool size", toolSize * scale / 2)
            layer.fillColor = nil //comp.toColorOverride(a: 1).cgColor
            
            
            let mask = CALayer()
            mask.addSublayer(layer)
            parentLayer?.mask = mask
            
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
        let name = layers.generateUniqueName(prefix: toolType.rawValue+"_"+toolShape.rawValue)
        history.layerContainer?.layers[name] = parentLayer
        let bezier = UIBezierPath()
        for b in splitOpt.bezierArr {
            bezier.append(b)
        }
        let cgPath = bezier.cgPath
        let lineWidth = (parentLayer.mask?.sublayers?.first as? CAShapeLayer)?.lineWidth ?? toolSize

        let shapeDict: [String: Any] = [
            "path": cgPath,
            "strokeColor": UIColor.white.cgColor,
            "lineJoin": CAShapeLayerLineJoin.round,
            "lineCap": CAShapeLayerLineCap.round,
            "lineWidth": lineWidth,
            "fillColor": UIColor.clear.cgColor
        ]

        let forward = History.Element(objectId: name, action: .add(classType: CAShapeLayer.self), updateKeys: [
            "frame": parentLayer.frame,
            "path": parentLayer.path,
            "contents": parentLayer.contents,
            "fillColor": parentLayer.fillColor
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
    
    fileprivate func prepareBlurredSnapshot() {
        let scaleDown = max(content!.bounds.height, content!.bounds.width) / UIScreen.main.bounds.height
        var hiddenLayers: [CALayer] = []
        for (k, l) in history?.layerContainer?.layers ?? [:] {
            if k.hasPrefix(toolType.rawValue+"_"+toolShape.rawValue) {
                hiddenLayers.append(l)
                l.isHidden = true
            }
        }
        content?.snapshotInMain(scale: 0.25/scaleDown, blur: 1, completion: { image in
            hiddenLayers.forEach({ $0.isHidden = false })
//        content?.snapshotInBackground(scale: 1/4, blur: 1, completion: { image in
            if let image = image {
                self.blurredSnapshot = UIImage(cgImage: image)
            }
        })
    }
}
