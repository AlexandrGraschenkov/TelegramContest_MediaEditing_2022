//
//  BrushDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 14.10.2022.
//

import UIKit

class BrushDrawer: NSObject {
    var active: Bool = false {
        didSet {
            if oldValue == active { return }
            pan?.isEnabled = active
        }
    }
    
    func setup(content: UIView) {
        pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(pan:)))
        pan.isEnabled = active
        content.addGestureRecognizer(pan)
        content.isUserInteractionEnabled = true
        
        self.content = content
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
            brushGen.brushSize = 10*scale
            brushGen.scrollZoomScale = scale
            smoothTime.scale = scale
            smoothTime.debugView = content
            smoothTime.start()
            smoothTime.update(point: pp)
            drawPath = smoothTime.points
            updateDrawLayer()
        case .changed:
            smoothTime.update(point: pp)
            drawPath = smoothTime.points
            updateDrawLayer()
        case .ended:
            smoothTime.end()
            drawPath = smoothTime.points
            
            updateDrawLayer()
            finishDraw(canceled: false)
        default:
            smoothTime.end()
            finishDraw(canceled: true)
        }
    }
    
    fileprivate var smoothTime = PanSmoothIK()
//    fileprivate var smoothTime = PanSmoothTime()
    fileprivate var pan: UIPanGestureRecognizer!
    fileprivate weak var content: UIView?
    fileprivate var drawBezier: UIBezierPath?
    fileprivate var drawPath: [PanPoint] = []
    fileprivate var currentDrawLayer: CAShapeLayer?
    fileprivate var currentDrawDebugLayer: CAShapeLayer?
    fileprivate var brushLayers: [CAShapeLayer] = []
    fileprivate var brushGen = BrushCurveGenerator()
    fileprivate let splitOpt = BrushSplitOptimizer()
    
    fileprivate func updateDrawLayer() {
        if currentDrawLayer == nil {
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            let layer = CAShapeLayer()
            layer.strokeColor = nil
            layer.fillColor = UIColor.white.cgColor
            content?.layer.addSublayer(layer)
            currentDrawLayer = layer
            splitOpt.start(layer: layer, brushGen: brushGen)
            
//            currentDrawDebugLayer = CAShapeLayer()
//            currentDrawDebugLayer?.strokeColor = UIColor.red.cgColor
//            currentDrawDebugLayer?.lineWidth = scale
//            currentDrawDebugLayer?.fillColor = nil
//            content?.layer.addSublayer(currentDrawDebugLayer!)
        }
        splitOpt.updatePath(points: drawPath)
//        let bezier = brushGen.generatePolygon(type: .standart, points: drawPath)
//        currentDrawLayer?.path = bezier.cgPath
//        var debugPath = brushGen.generateStrokePolygon(type: .standart, points: drawPath)
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
            currentDrawLayer?.removeFromSuperlayer()
        } else {
            brushLayers.append(currentDrawLayer!)
            
            let suffCount = drawPath.count - splitOpt.frozenCount
            brushGen.finishPlumAnimation(type: .standart, points: drawPath.suffix(suffCount), onLayer: splitOpt.shapeArr.last!, duration: 0.24)
//            brushGen.finishPlumAnimation(type: .standart, points: drawPath, onLayer: currentDrawLayer!, duration: 0.2)
        }
        currentDrawLayer = nil
        currentDrawDebugLayer = nil
    }
}

