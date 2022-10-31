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
            longPress?.isEnabled = active
        }
    }
    open var enableSuggestion: Bool {
        switch toolShape {
        case .circle, .eraserBlur, .eraserNormal: return true
        default: return false
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
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(gesture:)))
        longPress.minimumPressDuration = 1.0
        longPress.isEnabled = active
        content.addGestureRecognizer(longPress)
        
        pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(pan:)))
        pan.isEnabled = active
        pan.maximumNumberOfTouches = 1
        content.addGestureRecognizer(pan)
        content.isUserInteractionEnabled = true
        
        self.content = content
        self.history = history
        shapeSuggestion.onShape = { [weak self] path in
            self?.onShapeSuggested(path: path)
        }
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
        case .failed, .cancelled:
            smooth.end()
            finishDraw(canceled: true)
        default:
            break
        }
        
        if enableSuggestion {
            shapeSuggestion.onPanClassify(pan, drawPath: drawPath)
        }
    }
    
    fileprivate(set) var smooth = PanSmoothIK()
//    fileprivate var smooth = PanSmoothTime()
    fileprivate var pan: UIPanGestureRecognizer!
    fileprivate var longPress: UILongPressGestureRecognizer!
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
    let shapeSuggestion = ToolShapeSuggestion()
    
    
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
        let averageSpeed = points[idx1].getSpeed(p: points[idx2])
        let time = points[idx1].time
        
        let dir = points[idx1].point.subtract(points[idx2].point)
        let angle = atan2(dir.y, dir.x)
        let angle1 = angle + .pi * 3 / 4
        let angle2 = angle - .pi * 3 / 4
        let distOffset = finalToolSize * 5
        let p1 = points[idx1].point.add(CGPoint(x: cos(angle1) * distOffset, y: sin(angle1) * distOffset))
        let p2 = points[idx1].point.add(CGPoint(x: cos(angle2) * distOffset, y: sin(angle2) * distOffset))
        let pCenter = points[idx1].point.subtract(dir.norm.multiply(0.1))
        
        points.append(PanPoint(point: p1, time: time, speed: averageSpeed, bezierSmooth: false))
        points.append(PanPoint(point: pCenter, time: time, speed: averageSpeed, bezierSmooth: false))
        points.append(PanPoint(point: p2, time: time, speed: averageSpeed, bezierSmooth: false))
    }
    
    open func onShapeSuggested(path: UIBezierPath?) {
//        assert(false, "Override method")
    }
    open func generateLayer(path: UIBezierPath?, overrideColor: UIColor? = nil, overrideFinalSize: CGFloat? = nil) -> CALayer {
        let size = overrideFinalSize ?? toolSize * 2 * contentScale
        let color = overrideColor ?? self.color
        let comp = color.components
        
        let layer = CAShapeLayer()
        layer.strokeColor = comp.toColorOverride(a: 1).cgColor
        layer.lineWidth = size
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.fillColor = comp.toColorOverride(a: 0).cgColor
        layer.path = path?.cgPath
        
        return layer
    }
    
    func generateForwardAddHistory(layer: CALayer, objectId: String, overrideKeys: [String: Any?]? = nil) -> History.Element {
        let layerClass: AnyClass = layer.classForCoder
        let keys = layer.getKeys(override: overrideKeys)
        var elem = History.Element(objectId: objectId, action: .add(classType: layerClass), updateKeys: keys)
        
        if layer.mask != nil || layer.sublayers?.count ?? 0 > 0 {
            let maskClass: AnyClass? = layer.mask?.classForCoder
            let maskKeys: [String: Any?]? = layer.mask?.getKeys()
            let subClass: AnyClass? = layer.sublayers?.first?.classForCoder
            let subKeys: [String: Any?]? = layer.sublayers?.first?.getKeys()
            
            elem.closure = { (elem, container, parent) in
                guard let parent = parent as? CALayer else {
                    return
                }
                
                if let maskClass = maskClass as? CALayer.Type, let keys = maskKeys {
                    parent.mask = maskClass.init()
                    parent.mask?.apply(keys: keys)
                }
                if let subClass = subClass as? CALayer.Type, let keys = subKeys {
                    let sub = subClass.init()
                    sub.apply(keys: keys)
                    parent.addSublayer(sub)
                }
            }
        }
        
        return elem
    }
    
    // for shape creation
    func applyNewPath(layer: CALayer, path: CGPath) {
        guard let shape = layer.mask as? CAShapeLayer ??
            layer.sublayers?.first as? CAShapeLayer ??
                layer as? CAShapeLayer else {
            assert(false, "something wrong")
            return
        }
        
        shape.path = path
    }
    
    
    @objc func onLongPress(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let container = history?.layerContainer,
              let fillView = container.fillView else {
            return
        }
        
        pan.isEnabled = false
        delay(0.1) { self.pan.isEnabled = true }
        let point = gesture.location(in: gesture.view)
        
        let prevFillView = UIView(frame: fillView.frame)
        prevFillView.backgroundColor = fillView.backgroundColor
        fillView.superview?.insertSubview(prevFillView, belowSubview: fillView)
        
        let prevColor = container.fillView?.backgroundColor
        let newColor = color.withAlphaComponent(1)
        
        let mask = UIView(frame: CGRect(mid: point, size: .square(side: 6)))
        mask.backgroundColor = UIColor.white
        mask.layer.masksToBounds = true
        mask.layer.cornerRadius = mask.width / 2
        
        container.fillView?.mask = mask
        container.fillView?.backgroundColor = newColor
        let diameter = container.fillView!.bounds.size.point.distance()
        let scale = diameter / mask.width
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn]) {
            mask.transform = .init(scaleX: scale, y: scale)
        } completion: { _ in
            mask.removeFromSuperview()
            prevFillView.removeFromSuperview()
        }
        
        // History
        let forward = History.Element(objectId: "", action: .closure) { _, container, _ in
            container.fillView?.backgroundColor = newColor
        }
        let backward = History.Element(objectId: "", action: .closure) { _, container, _ in
            container.fillView?.backgroundColor = prevColor
        }
        history?.add(element: History.ElementGroup(forward: [forward], backward: [backward]))
    }
}
