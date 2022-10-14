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
    
    @objc
    private func onPan(pan: UIPanGestureRecognizer) {
        let p = pan.location(in: content)
        switch pan.state {
        case .began:
            drawBezier = UIBezierPath()
            drawBezier?.move(to: p)
            drawBezier?.addLine(to: p)
            updateDrawLayer()
        case .changed:
            drawBezier?.addLine(to: p)
            updateDrawLayer()
        case .ended:
            drawBezier?.addLine(to: p)
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
    fileprivate var currentDrawLayer: CAShapeLayer?
    fileprivate var brushLayers: [CAShapeLayer] = []
    
    
    fileprivate func updateDrawLayer() {
        if currentDrawLayer == nil {
            var scale: CGFloat = 1.0
            if let content = content {
                scale = content.bounds.width / content.frame.width
            }
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.white.cgColor
            layer.lineWidth = scale * 10
            layer.lineCap = .round
            layer.lineJoin = .round
            layer.fillColor = nil
            content?.layer.addSublayer(layer)
            currentDrawLayer = layer
        }
        currentDrawLayer?.path = drawBezier?.cgPath
    }
}

