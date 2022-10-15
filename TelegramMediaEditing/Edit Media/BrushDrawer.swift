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
            brushGen.brushSize = 30*scale
            drawPath.removeAll()
            drawPath.append(pp)
            updateDrawLayer()
        case .changed:
            drawPath.append(pp)
            updateDrawLayer()
        case .ended:
            drawPath.append(pp)
            updateDrawLayer()
            brushLayers.append(currentDrawLayer!)
            currentDrawLayer = nil
        default:
            currentDrawLayer?.removeFromSuperlayer()
            currentDrawLayer = nil
        }
    }
    
    fileprivate var pan: UIPanGestureRecognizer!
    fileprivate weak var content: UIView?
    fileprivate var drawBezier: UIBezierPath?
    fileprivate var drawPath: [PanPoint] = []
    fileprivate var currentDrawLayer: CAShapeLayer?
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
        }
        currentDrawLayer?.path = bezier.cgPath
    }
}

