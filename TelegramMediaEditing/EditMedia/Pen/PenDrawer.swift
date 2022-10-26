//
//  PenDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 14.10.2022.
//

import UIKit

class PenDrawer: NSObject {
    var active: Bool = false {
        didSet {
            if oldValue == active { return }
            pan?.isEnabled = active
        }
    }
    var color: UIColor = .white
    var penSize: CGFloat = 10
    
    func setup(content: UIView, history: History) {
        pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(pan:)))
        pan.isEnabled = active
        pan.maximumNumberOfTouches = 1
        content.addGestureRecognizer(pan)
        content.isUserInteractionEnabled = true
        
        self.content = content
        self.history = history
    }
    
//    func historyForward() {
//        
//    }
//    
//    func historyBackward() {
//        
//    }
    
//    var debugBegunFlag = false
    @objc
    private func onPan(pan: UIPanGestureRecognizer) {
        let p = pan.location(in: content)
        let t = CACurrentMediaTime()
        let pp = PanPoint(point: p, time: t)
        switch pan.state {
        case .began:
            
//// MARK: - FOR DEBUG
//            if debugBegunFlag {
//                return
//            }
//            debugBegunFlag = true
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            penGen.penSize = penSize*scale
            penGen.scrollZoomScale = scale
            smooth.scale = scale
            smooth.debugView = content
            smooth.start()
            smooth.update(point: pp)
            drawPath = smooth.points
            updateDrawLayer()
        case .changed:
            smooth.update(point: pp)
            drawPath = smooth.points
            updateDrawLayer()
        case .ended:
            smooth.end()
            drawPath = smooth.points
            
            updateDrawLayer()
            finishDraw(canceled: false)
        default:
            smooth.end()
            finishDraw(canceled: true)
        }
    }
    
    fileprivate var smooth = PanSmoothIK()
//    fileprivate var smoothTime = PanSmoothTime()
    fileprivate var pan: UIPanGestureRecognizer!
    fileprivate weak var content: UIView?
    fileprivate weak var history: History?
    fileprivate var drawPath: [PanPoint] = []
    fileprivate var penGen = PenCurveGenerator()
    fileprivate let splitOpt = PenSplitOptimizer()
    fileprivate var parentLayer: CAShapeLayer?
    
    fileprivate func updateDrawLayer() {
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
            splitOpt.start(layer: layer, penGen: penGen)
            
//            currentDrawDebugLayer = CAShapeLayer()
//            currentDrawDebugLayer?.strokeColor = UIColor.red.cgColor
//            currentDrawDebugLayer?.lineWidth = scale
//            currentDrawDebugLayer?.fillColor = nil
//            content?.layer.addSublayer(currentDrawDebugLayer!)
        }
        splitOpt.updatePath(points: drawPath)
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
    
    fileprivate func finishDraw(canceled: Bool) {
        if canceled {
            splitOpt.shapeArr.forEach({$0.removeFromSuperlayer()})
        } else {
            let suffCount = drawPath.count - splitOpt.frozenCount
            // generate last layer without plume
            splitOpt.finish(updateLayer: false, points: drawPath)
            addToHistory()
            
            // run pretty animation with plume shrinks
            penGen.finishPlumAnimation(points: drawPath.suffix(suffCount), onLayer: splitOpt.shapeArr.last!, duration: 0.24)
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
        let forward = History.Element(objectId: name, action: .add(classType: CAShapeLayer.self), updateKeys: ["path": bezier.cgPath, "fillColor": color.cgColor])
        let backward = History.Element(objectId: name, action: .remove)
        history.add(element: .init(forward: [forward], backward: [backward]))
    }
}

