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
    var color: UIColor = .white
    var toolSize: CGFloat = 10
    
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
            curveGen.toolSize = toolSize*scale
            curveGen.scrollZoomScale = scale
            smooth.scale = scale
            smooth.toolSize = toolSize
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
}
