//
//  ToolDrawer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 27.10.2022.
//

import UIKit

class ToolDrawer: NSObject {
    var active: Bool = false {
        didSet {
            if oldValue == active { return }
            pan?.isEnabled = active
        }
    }
    var toolType: ToolType { .pen }
    var toolShape: ToolShape = .circle
    var color: UIColor = .white
    var toolSize: CGFloat = 10
    var contentScale: CGFloat {
        var scale: CGFloat = 1.0
        if let content = content {
            scale = content.bounds.width / content.frame.width
        }
        return scale
    }
    
    func setup(content: UIView, history: History) {
        pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(pan:)))
        pan.isEnabled = active
        pan.maximumNumberOfTouches = 1
        content.addGestureRecognizer(pan)
        content.isUserInteractionEnabled = true
        
        self.content = content
        self.history = history
    }
    
//    var debugBegunFlag = false
    @objc
    open func onPan(pan: UIPanGestureRecognizer) {
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
            let scale: CGFloat = contentScale
            curveGen.toolSize = toolSize*scale
            curveGen.scrollZoomScale = scale
            smooth.scale = scale
            smooth.toolSize = toolSize
            smooth.debugView = content
            smooth.start()
            smooth.update(point: pp)
            updateDrawPath()
            updateDrawLayer()
        case .changed:
            smooth.update(point: pp)
            updateDrawPath()
            updateDrawLayer()
        case .ended:
            smooth.end()
            updateDrawPath()
            
            updateDrawLayer()
            finishDraw(canceled: false)
        default:
            smooth.end()
            finishDraw(canceled: true)
        }
    }
    
    fileprivate(set) var smooth = PanSmoothIK()
//    fileprivate var smooth = PanSmoothTime()
    fileprivate var pan: UIPanGestureRecognizer!
    fileprivate(set) weak var content: UIView?
    fileprivate(set) weak var history: History?
    fileprivate(set) var drawPath: [PanPoint] = []
    lazy var curveGen: ToolCurveGenerator = {
        let gen = ToolCurveGenerator()
        gen.mode = toolType
        return gen
    }()
    let splitOpt = ToolDrawSplitOptimizer()
    fileprivate var parentLayer: CAShapeLayer?
    
    open func updateDrawLayer() {
        // draw path was updated
        assert(false, "Override method")
    }
    
    open func finishDraw(canceled: Bool) {
        assert(false, "Override method")
    }
    
    private func updateDrawPath() {
        drawPath = smooth.points
        if toolShape == .arrow {
            makeArrowOnEnd(points: &drawPath)
        }
    }
    
    open func makeArrowOnEnd(points: inout [PanPoint]) {
        if points.count < 2 {
            return
        }
        let finalToolSize = contentScale * toolSize
        let idx1 = points.count-1
        let idx2 = max(0, points.count-4) // index from back
        let averageSpeed = points[idx1].speed(p: points[idx2])
        let time = points[idx1].time
        
        let dir = points[idx1].point.substract(points[idx2].point)
        let angle = atan2(dir.y, dir.x)
        let angle1 = angle + .pi * 3 / 4
        let angle2 = angle - .pi * 3 / 4
        let distOffset = finalToolSize * 5
        let p1 = points[idx1].point.add(CGPoint(x: cos(angle1) * distOffset, y: sin(angle1) * distOffset))
        let p2 = points[idx1].point.add(CGPoint(x: cos(angle2) * distOffset, y: sin(angle2) * distOffset))
        let pCenter = points[idx1].point.substract(dir.norm.multiply(0.1))
        
        points.append(PanPoint(point: p1, time: time, speed: averageSpeed, bezierSmooth: false))
        points.append(PanPoint(point: pCenter, time: time, speed: averageSpeed, bezierSmooth: false))
        points.append(PanPoint(point: p2, time: time, speed: averageSpeed, bezierSmooth: false))
    }
}
