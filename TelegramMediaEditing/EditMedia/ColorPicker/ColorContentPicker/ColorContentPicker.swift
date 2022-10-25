//
//  ColorContentPicker.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 25.10.2022.
//

import UIKit

class ColorContentPicker: UIView {

    static func createOn(content: UIView, bounds: CGRect, completion: @escaping (UIColor)->()) -> ColorContentPicker {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = UIScreen.main.scale
        if #available(iOS 12.0, *) {
            format.preferredRange = .standard
        } else {
            format.prefersExtendedRange = false
        }
        // TODO: maybe need to move in background?
        let renderer = UIGraphicsImageRenderer(bounds: content.bounds, format: format)
        let img = renderer.image { rendererContext in
            content.layer.render(in: rendererContext.cgContext)
        }
        let container = UIView(frame: content.frame)
        content.autoresizingMask = content.autoresizingMask
        content.superview?.addSubview(container)
        
        let control = ColorContentPicker()
        control.activeBounds = bounds
        control.img = img
        control.container = container
        control.completion = completion
        
        control.center = container.bounds.mid
        container.addSubview(control)
        control.animateAppear()
        
        container.addGestureRecognizer(UIPanGestureRecognizer(target: control, action: #selector(onPan(pan:))))
        return control
    }
    
    func dismiss() {
        animateDismiss()
    }
    
    
    // MARK: - private
    
    private var container: UIView!
    private var img: UIImage!
    private let pickerSize: CGFloat = 110
    private let gridElemSize: CGFloat = 10
    private let gridElemSpace: CGFloat = 0.5
    private let colorOutlineSize: CGFloat = 10
    private let whiteOutlineSize: CGFloat = 3
    
    private var activeBounds: CGRect = .zero
    private var completion: ((UIColor)->())?
    private var colorOutline: CAShapeLayer!
    private var grid: [[CAShapeLayer]] = []
    private var lastColor: UIColor = .white
    
    private init() {
        super.init(frame: CGRect(x: 0, y: 0, width: pickerSize, height: pickerSize))
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        colorOutline = CAShapeLayer()
        colorOutline.path = CGPath(ellipseIn: bounds, transform: nil)
        colorOutline.fillColor = UIColor.red.cgColor
        layer.addSublayer(colorOutline)
        
        let whiteOutline = CAShapeLayer()
        whiteOutline.path = CGPath(ellipseIn: bounds.insetBy(dx: colorOutlineSize, dy: colorOutlineSize), transform: nil)
        whiteOutline.fillColor = UIColor.white.cgColor
        layer.addSublayer(whiteOutline)
        
        let contentMask = CAShapeLayer()
        contentMask.fillColor = UIColor.black.cgColor
        contentMask.path = CGPath(ellipseIn: bounds.insetBy(dx: colorOutlineSize+whiteOutlineSize, dy: colorOutlineSize+whiteOutlineSize), transform: nil)
        
        let content = CALayer()
        content.mask = contentMask
        content.frame = bounds
        layer.addSublayer(content)
        
        // Generate grid
        let contentSize = bounds.width - (colorOutlineSize+whiteOutlineSize)
        var gridCount: Int = Int(ceil(contentSize / (gridElemSize + gridElemSpace)))
        if gridCount % 2 == 0 {
            gridCount += 1 // must be odd
        }
        let midPoint = bounds.mid
        let midCount = gridCount / 2
        for r in 0..<gridCount {
            var line: [CAShapeLayer] = []
            for c in 0..<gridCount {
                let l = CAShapeLayer()
                let x = CGFloat(c - midCount) * (gridElemSize + gridElemSpace) + midPoint.x
                let y = CGFloat(r - midCount) * (gridElemSize + gridElemSpace) + midPoint.y
                l.path = CGPath(rect: CGRect(mid: CGPoint(x: x, y: y), size: .square(side: gridElemSize)), transform: nil)
                l.fillColor = UIColor.blue.cgColor
                content.addSublayer(l)
                line.append(l)
            }
            grid.append(line)
        }
        let midGridRect = CGRect(mid: bounds.mid, size: .square(side: gridElemSize)).insetBy(dx: -1, dy: -1)
        let midGridShape = CAShapeLayer()
        midGridShape.path = CGPath(roundedRect: midGridRect, cornerWidth: 1, cornerHeight: 1, transform: nil)
        midGridShape.strokeColor = UIColor.white.cgColor
        midGridShape.fillColor = nil
        midGridShape.lineWidth = 3
        content.addSublayer(midGridShape)
    }
    
    fileprivate func animateAppear() {
        updateColors()
        container.isUserInteractionEnabled = true
        self.transform = .init(scaleX: 0.1, y: 0.1)
        self.alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0.2, options: [.curveEaseOut]) {
            self.transform = .identity
            self.alpha = 1
        }
    }
    fileprivate func animateDismiss() {
        container.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            self.transform = .init(scaleX: 0.1, y: 0.1)
            self.alpha = 0
        } completion: { _ in
            self.container.removeFromSuperview()
        }
    }
    
    fileprivate func updateColors() {
        let gridSize = grid.count
        let midElem = gridSize / 2
        
        let provider = img.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)!
        let format = img?.cgImage?.bitmapInfo.componentLayout
        let yStep = img.cgImage!.bytesPerRow
        let xStep = img.cgImage!.bitsPerPixel / 8
        let getColor = {(y: Int, x: Int) -> CGColor in
            let pixelOffset = yStep * y + x * xStep
            let r: CGFloat, g: CGFloat, b: CGFloat
            switch format {
            case .rgba, .rgb:
                r = CGFloat(data[pixelOffset + 0]) / 255
                g = CGFloat(data[pixelOffset + 1]) / 255
                b = CGFloat(data[pixelOffset + 2]) / 255
            case .bgr, .bgra:
                b = CGFloat(data[pixelOffset + 0]) / 255
                g = CGFloat(data[pixelOffset + 1]) / 255
                r = CGFloat(data[pixelOffset + 2]) / 255
            default:
                r = 0; g = 0; b = 0
            }
            if #available(iOS 13.0, *) {
                return CGColor(red: r, green: g, blue: b, alpha: 1)
            } else {
                return UIColor(red: r, green: g, blue: b, alpha: 1).cgColor
            }
        }
        
        let p = center.mulitply(UIScreen.main.scale)
        let boundsScaled = CGRect(origin: activeBounds.origin.mulitply(UIScreen.main.scale),
                                  size: activeBounds.size.mulitply(UIScreen.main.scale))
        
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let y = r - midElem + Int(p.y.rounded())
                let x = c - midElem + Int(p.x.rounded())
                if !boundsScaled.contains(CGPoint(x: x, y: y)) {
                    grid[r][c].fillColor = UIColor.black.cgColor
                    continue
                }
                
                grid[r][c].fillColor = getColor(y, x)
                
                if r == midElem && c == midElem {
                    lastColor = UIColor(cgColor: grid[r][c].fillColor!)
                    colorOutline.fillColor = grid[r][c].fillColor
                }
            }
        }
        CATransaction.commit()
    }
    

    @objc private func onPan(pan: UIPanGestureRecognizer) {
        let offset = pan.translation(in: container)
        let scale = UIScreen.main.scale
        switch pan.state {
        case .changed:
            var p = container.bounds.mid.add(offset)
            p.x = max(activeBounds.minX, min(activeBounds.maxX, p.x.round(scale: scale)))
            p.y = max(activeBounds.minY, min(activeBounds.maxY, p.y.round(scale: scale)))
            self.center = p
            updateColors()
            
        case .ended:
            completion?(lastColor)
            animateDismiss()
        case .failed, .cancelled:
            animateDismiss()
        default: break
        }
    }
}
