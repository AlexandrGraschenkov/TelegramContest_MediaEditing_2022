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
        brushGen.testSquare()
    }
    
//    func historyForward() {
//        
//    }
//    
//    func historyBackward() {
//        
//    }
    
    @objc
    private func onPan(pan: UIPanGestureRecognizer) {
        let p = pan.location(in: content)
        let t = CACurrentMediaTime()
        let pp = PanPoint(point: p, time: t)
        switch pan.state {
        case .began:
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            brushGen.brushSize = 20*scale
            brushGen.scrollZoomScale = scale
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
            smoothTime.update(point: pp)
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
    
    fileprivate func updateDrawLayer() {
        let bezier = brushGen.generatePolygon(type: .standart, points: drawPath)
        if currentDrawLayer == nil {
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            let layer = CAShapeLayer()
            let stroke = false
            if stroke {
                layer.strokeColor = UIColor.white.cgColor
                layer.lineWidth = scale * 10
                layer.lineCap = .round
                layer.lineJoin = .round
                layer.fillColor = nil
            } else {
                layer.strokeColor = nil
                layer.fillColor = UIColor.white.cgColor
            }
            content?.layer.addSublayer(layer)
            currentDrawLayer = layer
            
            currentDrawDebugLayer = CAShapeLayer()
            currentDrawDebugLayer?.strokeColor = UIColor.red.cgColor
            currentDrawDebugLayer?.lineWidth = scale
            currentDrawDebugLayer?.fillColor = nil
            content?.layer.addSublayer(currentDrawDebugLayer!)
        }
        currentDrawLayer?.path = bezier.cgPath
        var debugPath = brushGen.generateStrokePolygon(type: .standart, points: drawPath)
//        if drawPath.count > 1 {
//            debugPath.move(to: drawPath[0].point)
//            for point in drawPath {
//                debugPath.addLine(to: point.point)
//            }
//        }
        currentDrawDebugLayer?.path = debugPath.cgPath
    }
    
    fileprivate func finishDraw(canceled: Bool) {
        if canceled {
            currentDrawLayer?.removeFromSuperlayer()
        } else {
            brushLayers.append(currentDrawLayer!)
        }
        currentDrawLayer = nil
        currentDrawDebugLayer = nil
    }
}

