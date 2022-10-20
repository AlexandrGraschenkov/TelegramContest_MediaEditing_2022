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
            penGen.penSize = penSize*scale
            penGen.scrollZoomScale = scale
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
    fileprivate var penLayers: [CAShapeLayer] = []
    fileprivate var penGen = PenCurveGenerator()
    fileprivate let splitOpt = PenSplitOptimizer()
    
    fileprivate func updateDrawLayer() {
        if !splitOpt.isPrepared {
            let layer = CAShapeLayer()
            layer.strokeColor = nil
            layer.fillColor = color.cgColor
            content?.layer.addSublayer(layer)
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
            penLayers.append(contentsOf: splitOpt.shapeArr)
            
            let suffCount = drawPath.count - splitOpt.frozenCount
            // generate last layer without plume
            splitOpt.finish(updateLayer: false, points: drawPath)
            // run pretty animation with plume shrinks
            penGen.finishPlumAnimation(points: drawPath.suffix(suffCount), onLayer: splitOpt.shapeArr.last!, duration: 0.24)
        }
//        currentDrawDebugLayer = nil
    }
}

